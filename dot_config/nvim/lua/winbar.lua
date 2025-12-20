local folder_icon = require('icons').symbol_kinds.Folder
local ellipsis = require('icons').misc.ellipsis
local info_icon = require('icons').diagnostics.INFO
local robot_icon = require('icons').misc.robot

local M = {}

---@alias WinbarOptions { separator?: string, buffer_symbols?: BufferSymbols, abbreviated_dirs?: AbbreviatedDirs }

---@class Options
---@field separator string Delimiter used to seperate path breadcrumbs.
---@field buffer_symbols BufferSymbols Symbols to be used for the buffer state.
---@field abbreviated_dirs AbbreviatedDirs Dirs to abbreviate in the breadcrumbs.
local Options = {
    separator = ' / ',
    buffer_symbols = {
        modified = '+',
        readonly = '-',
        newfile = 'New',
    },
    abbreviated_dirs = {
        CONFIG = vim.fs.normalize(vim.env.XDG_CONFIG_HOME or vim.env.HOME .. '/.config'),
        HOME = vim.fs.normalize(vim.env.HOME),
    },
}

---@class BufferSymbols
---@field modified string Symbol to denote a buffer with unwritten changes.
---@field readonly string Symbol to denote a buffer that is readonly.
---@field newfile string Symbol to denote a buffer to a new file.

---@alias AbbreviatedDirs table<string, DirOptions|string>

---@class DirOptions
---@field path string The path to the dir.
---@field transparent boolean If true, the subdirectory will be used as the prefix instead when relevant.

---@class Breadcrumb_Parts
---@field tokens string[] All unstyled path tokens for the buffer, exlcuding the prefix and target.
---@field prefix? string The unstyled prefix for the buffer, if any.
---@field target? string The unstyled target for the buffer, if any.

-- Cache of path tokens per buffer.
---@type table<integer, Breadcrumb_Parts>
local cache = {}

---@class Window_State
---@field bufnr integer The bufnr id the cache is for.
---@field path? string The styled breadcrumbs up to the target, exclusive of the target seperator.
---@field pathNC? string The NC styled breadcrumbs up to the target, exclusive of the target seperator.
---@field truncated_token? string The first truncated breadcrumb, if any.
---@field truncated integer The number of tokens truncated.
---@field display_width integer The display width of the cached path.

-- Cache of window rendered breadcrumbs.
---@type table<integer, Window_State>
local window_cache = {}

---@return boolean
local function is_new_file()
    local filename = vim.fn.expand('%')
    return filename ~= ''
        and filename:match('^%a+://') == nil
        and vim.bo.buftype == ''
        and vim.fn.filereadable(filename) == 0
end

-- Adopted from lualine filename componenet
-- Builds a target suffix for the buffer state, eg [+,New]
---@return string | nil
local function get_symbols()
    if not Options.buffer_symbols then
        return nil
    end
    local symbols = {}
    if vim.bo.modified then
        table.insert(symbols, Options.buffer_symbols.modified)
    end
    if vim.bo.modifiable == false or vim.bo.readonly == true then
        table.insert(symbols, Options.buffer_symbols.readonly)
    end

    if is_new_file() then
        table.insert(symbols, Options.buffer_symbols.newfile)
    end

    return (#symbols > 0 and '[' .. table.concat(symbols, ',') .. ']' or nil)
end

-- Gets the breadcrumb parts for the current buffer.
-- If it is cached, the cached value is immediately returned,
-- else it builds them and adds them to the cache.
---@param bufnr integer The buffer to get parts for.
---@return Breadcrumb_Parts
local function get_parts(bufnr)
    if cache[bufnr] then
        return cache[bufnr]
    end

    -- Get the path and expand variables.
    local path = vim.fs.normalize(vim.fn.expand('%:p'))
        :gsub('^oil:', '') -- Strip oil prefix

    local prefix, prefix_path = '', ''
    ---@type DirOptions|string
    local prefix_options = ''

    for dir_name, dir_options in pairs(Options.abbreviated_dirs) do
        local dir_path = dir_options.path or dir_options
        if vim.startswith(path, dir_path) and #dir_path > #prefix_path then
            prefix, prefix_path, prefix_options = dir_name, dir_path, dir_options
        end
    end
    if prefix ~= '' then
        path = string.sub(path, #prefix_path + 1)
        -- If prefix is transparent, use the sub directory if it exists.
        if prefix_options.transparent and #path > 0 then
            local sub_dir = path:match('/[^/]*')
            path          = string.sub(path, #sub_dir + 1)
            prefix        = sub_dir:gsub('^/', '')
        end
    end

    -- Select the target
    ---@type string
    local target = path and path:match('/[^/]+$')
    if target then
        -- Drop target from the path
        path = path:sub(1, #path - #target)
        target = target:gsub('^/', '')
    elseif prefix == '' and path == '' then
        -- PWD is '/'
        target = '/'
    end

    -- Split the nodes
    local nodes = vim.split(path, '/', { trimempty = true }) or {}

    cache[bufnr] = {
        tokens = nodes,
        prefix = prefix,
        target = target,
    }
    return cache[bufnr]
end

-- Formats the given target according to the buffer state.
---@param bufnr integer
---@param target string | nil
---@param is_active boolean
---@param is_help boolean
---@param is_code_companion boolean
---@return string | nil, integer
local function get_target(bufnr, target, is_active, is_help, is_code_companion)
    if not target then
        return nil, 0
    end
    if is_help then
        local no_affix = target:gsub('.txt$', '')
        return '%#WinBarDoc#' .. info_icon .. ' ' .. no_affix, #no_affix + 2
    end
    if is_code_companion then
        return '%#WinBarCodeCompanion#' .. robot_icon .. ' ' .. target, #target + 2
    end
    local diff = require('git').git_diff(bufnr)
    local symbols = get_symbols()
    local num_errors = #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
    local target_parts = {}
    local hi = num_errors > 0 and '%#WinBarTargetError#'
        or vim.bo.modified and '%#WinBarTargetModified#'
        or diff and '%#WinBarTargetDirty#'
        or is_active and '%#WinBarTarget#'
        or '%#WinBarTargetNC#'
    table.insert(target_parts, hi .. target)
    if symbols then
        table.insert(target_parts, symbols)
    end
    if diff then
        table.insert(target_parts, diff)
    end
    local display_width = #target
        + (symbols and #symbols or 0)
        + (diff and #diff:gsub('%%#[a-zA-Z]+#', '') or 0)
        + #target_parts - 1
    return table.concat(target_parts, ' '), display_width
end

-- Attempts to load the breadcrumbs for the given buffer for the target window
-- cache. If no cache is found or it is no longer valid, nil is returned.
---@param win integer The ID of the window.
---@param bufnr integer The ID of the buffer.
---@param separator string The seperator we are using.
---@param available integer The available space to draw in.
---@return string | nil
local function load_from_window_catch(win, bufnr, separator, available, is_active)
    local cached = window_cache[win]
    if not cached or bufnr ~= cached.bufnr then
        return nil
    end
    local cached_path = is_active and cached.path or not is_active and cached.pathNC
    if not cached_path then
        return nil
    end
    local remaining_space = available - cached.display_width
    local truncated = cached.truncated_token
        and #cached.truncated_token
        + (cached.truncated > 1 and vim.fn.strdisplaywidth(separator) or 0)
        or nil
    -- If we have remaining space and don't have room to reveal the
    -- first truncated, then we can return the cached value.
    if remaining_space >= 0 and (not truncated or truncated > remaining_space) then
        return cached_path
    else
        -- If the window is so small if can't fit prefix + subdir + target,
        -- we return and do not use the cache, but rebuilding is cheap.
        -- Clear the other cache to avoid checking it when focus changes.
        return nil
    end
end

-- Builds the breadcrumbs according to the target window and buffer with the
-- provided target. Applies truncation to make sure that the breadcrumbs
-- will fit in the target winbar. It will not be truncated more than prefix?,
-- context, target.
---@param win integer Window id which we are building for.
---@param bufnr integer Buffer id which we are building for.
---@param parts Breadcrumb_Parts The breadcrumb parts for the buffer.
---@param separator string The separator we are using.
---@param available integer The available space to draw in.
---@param is_active boolean If the target window is the active window or not.
---@param is_help boolean If the target window is a help window.
---@return string
local function build(win, bufnr, parts, separator, available, is_active, is_help)
    -- Check if the buftype is 'help'
    if is_help then
        return ''
    end
    local separator_length = vim.fn.strdisplaywidth(separator)
    local used = 0
    local display_width = 0

    -- Account for the prefix with icon, if defined.
    if parts.prefix and parts.prefix ~= '' then
        used = #parts.prefix + 2
        display_width = used
    end

    ---@type table<string>
    local bread_crumbs = {}

    -- Calculate the bread crumbs, truncated as needed.
    local truncated, num_truncated = nil, 0
    local winbar_hl = is_active and '%#Winbar#' or '%#WinBarNC#'
    if #parts.tokens > 0 then
        -- Always show the first item for context
        used = used + #parts.tokens[1] + separator_length
        display_width = display_width + #parts.tokens[1] + separator_length
        -- Insert from the last path node until the first while there is room.
        for i = 0, #parts.tokens - 2 do
            local this_token = parts.tokens[#parts.tokens - i]
            used = used + #this_token + separator_length
            -- If we only have enough space left for the ellipsis segment,
            -- insert that and break the loop.
            -- Generally this first case catches all, but in a very rare
            -- edge case, if it is not the last element and it will leave
            -- less than the 4 spaces required for the ellipsis, it could
            -- overflow.
            if used > available or (i ~= (#parts.tokens - 2) and used > available - 4) then
                table.insert(bread_crumbs, ellipsis)
                display_width = display_width + 4
                truncated = this_token
                num_truncated = #parts.tokens - 3 - i
                break
            else
                display_width = display_width + #this_token + separator_length
                table.insert(bread_crumbs, winbar_hl .. this_token)
            end
        end
        table.insert(bread_crumbs, winbar_hl .. parts.tokens[1])
    end


    if parts.prefix and parts.prefix ~= '' then
        table.insert(bread_crumbs, table.concat {
            is_active and '%#WinBarDir#' or '%#WinBarDirNC#',
            folder_icon,
            ' ',
            parts.prefix
        })
    end

    local path = vim.iter(bread_crumbs):rev():join(
        (is_active and '%#WinBarSeparator#' or '%#WinBarNC#') .. separator
    )

    local exiting_cache = window_cache[win]
    local cache_still_relevant = exiting_cache
        and exiting_cache.bufnr == bufnr
        and exiting_cache.truncated == truncated

    window_cache[win] = {
        bufnr = bufnr,
        truncated_token = truncated,
        truncated = num_truncated,
        display_width = display_width,
        path = is_active and path or cache_still_relevant and exiting_cache.path or nil,
        pathNC = not is_active and path or cache_still_relevant and exiting_cache.pathNC or nil,
    }

    return path
end

---@return string
local function mode_highlight(is_active, string)
    if not is_active then
        return '%#WinBarModeHighlightNC#' .. string
    else
        return string.format('%%#StatuslineModeSeparator%s#%s', require('util').mode_highlight_group(), string)
    end
end

local left_highlight = '▊'
local right_highlight = '🮊'

function M.render()
    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    local is_active = tostring(win) == vim.g.actual_curwin
    local is_help = vim.bo[bufnr].buftype == 'help'
    local is_code_companion = vim.bo.filetype == 'codecompanion'
    -- TODO: Make this dynamic
    local highlight_width = vim.fn.strdisplaywidth(left_highlight) + vim.fn.strdisplaywidth(right_highlight)
    local left, right = mode_highlight(is_active, left_highlight), mode_highlight(is_active, right_highlight)
    local separator = Options.separator or ''
    local parts = get_parts(bufnr)
    local target, target_display_width = get_target(bufnr, parts.target, is_active, is_help, is_code_companion)
    local breadcrumbs = ''
    -- If target will have a seperator
    if target and (#parts.prefix > 0 or #parts.tokens > 0) then
        target_display_width = target_display_width + 3
    end

    if not is_help and not is_code_companion then
        -- Available space with room for the padding, highlight, and target.
        local available = vim.api.nvim_win_get_width(0) - 2 - highlight_width - target_display_width
        -- Load from the window cache if it exists and still is still viable.
        breadcrumbs = load_from_window_catch(win, bufnr, separator, available, is_active)
            or build(win, bufnr, parts, separator, available, is_active, is_help)
    end

    return table.concat {
        is_active and '%#WinBar#' or '%#WinBarNC#',
        left,
        ' ',
        breadcrumbs,
        target and #breadcrumbs > 0 and (is_active and '%#WinBarSeparator#' or '%#WinBarNC#') .. separator or '',
        target and target or '',
        '%=',
        right,
    }
end

---@param user_options? WinbarOptions
function M.setup(user_options)
    if user_options then
        Options = vim.tbl_deep_extend('keep', user_options, Options)
    end

    -- vim.go.winbar = "%{%(nvim_get_current_win()==#g:actual_curwin) ? luaeval('M.build(true)') : luaeval('M.build(false)')%}"

    local group = vim.api.nvim_create_augroup('quincyjo/winbar', { clear = true })

    -- Attach the winbar to buffers.
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        desc = 'Attach winbar',
        callback = function(args)
            if
                (vim.bo[args.buf].buftype == ''                     -- Normal buffer
                    and vim.api.nvim_buf_get_name(args.buf) ~= ''   -- Has a file name
                    or vim.bo[args.buf].buftype == 'help'           -- Or is help buffer
                    or vim.api.nvim_buf_get_name(args.buf):find('[CodeCompanion]')  -- Or is oil buffer
                )
                and not vim.wo[0].diff                              -- Not in diff mode
            then
                vim.wo.winbar = "%{%v:lua.require'winbar'.render()%}"
            end
        end,
    })

    -- Clean up the cache when a buffer unloaded or a window is closed.
    vim.api.nvim_create_autocmd('BufUnload', {
        group = group,
        pattern = '*',
        callback = function(args)
            cache[args.buf] = nil
        end,
    })
    vim.api.nvim_create_autocmd('WinClosed', {
        group = group,
        pattern = '*',
        callback = function(args)
            window_cache[args.id] = nil
        end,
    })
end

return M
