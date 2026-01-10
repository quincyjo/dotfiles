local icons = require 'icons'
local mode_highlight_group = require('util').mode_highlight_group
local mode_string = require('util').mode_string

local M = {}

-- Don't show the command that produced the quickfix list.
vim.g.qf_disable_statusline = 1

-- Show the mode in my custom component instead.
vim.o.showmode = false

--- Keeps track of the highlight groups I've already created.
---@type table<string, boolean>
local statusline_hls = {}

---@param hl string
---@return string
function M.get_or_create_hl(hl)
    local hl_name = 'StatusLine' .. hl

    if not statusline_hls[hl] then
        -- If not in the cache, create the highlight group using the icon's foreground color
        -- and the statusline's background color.
        local bg_hl = vim.api.nvim_get_hl(0, { name = 'StatusLine' })
        local fg_hl = vim.api.nvim_get_hl(0, { name = hl })
        vim.api.nvim_set_hl(0, hl_name, { bg = ('#%06x'):format(bg_hl.bg), fg = ('#%06x'):format(fg_hl.fg) })
        statusline_hls[hl] = true
    end

    return hl_name
end

--- Current mode.
---@return string
function M.mode_component()
    -- Get the respective string to display.
    local mode = mode_string()
    local hl = mode_highlight_group()

    -- Construct the bubble-like component.
    return table.concat {
        string.format('%%#StatusLineModeSeparator%s#', hl),
        string.format('%%#StatusLineMode%s#%s', hl, mode),
        string.format('%%#StatusLineModeSeparator%s#', hl),
    }
end

--- Git status (if any).
---@return string
function M.git_component()
    local head = vim.b.gitsigns_head
    if not head or head == '' then
        return ''
    end

    local component = string.format('%s %s', require('icons').git.branch, head)
    local diff = require('git').git_diff()
    local hi = diff and '%#WinBarTargetModified#' or ''
    if diff then
        component = hi .. component .. ' ' .. diff
    end

    return component
end

---@return string
function M.filename_component()
    return require('util').file_highlight() .. vim.fn.expand('%:t')
end

--- The current debugging status (if any).
---@return string?
function M.dap_component()
    if not package.loaded['dap'] or require('dap').status() == '' then
        return nil
    end

    return string.format('%%#%s#%s  %s', M.get_or_create_hl 'Special', icons.misc.bug, require('dap').status())
end

---@type table<string, string?>
local progress_status = {
    client = nil,
    kind = nil,
    title = nil,
}

--- The latest LSP progress message.
---@return string
function M.lsp_progress_component()
    if not progress_status.client or not progress_status.title then
        return ''
    end

    -- Avoid noisy messages while typing.
    if vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
        return ''
    end

    return table.concat {
        '%#StatusLineSpinner#󱥸 ',
        string.format('%%#StatusLineTitle#%s  ', progress_status.client),
        string.format('%%#StatusLineItalic#%s...', progress_status.title),
    }
end

local last_diagnostic_component = ''
--- Diagnostic counts in the current buffer.
---@return string
function M.diagnostics_component()
    -- Lazy uses diagnostic icons, but those aren't errors per se.
    if vim.bo.filetype == 'lazy' then
        return ''
    end

    -- Use the last computed value if in insert mode.
    if vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
        return last_diagnostic_component
    end

    local counts = vim.iter(vim.diagnostic.get(0)):fold({
        ERROR = 0,
        WARN = 0,
        HINT = 0,
        INFO = 0,
    }, function(acc, diagnostic)
        local severity = vim.diagnostic.severity[diagnostic.severity]
        acc[severity] = acc[severity] + 1
        return acc
    end)

    local parts = vim.iter(counts)
        :map(function(severity, count)
            if count == 0 then
                return nil
            end

            local hl = 'Diagnostic' .. severity:sub(1, 1) .. severity:sub(2):lower()
            return string.format('%%#%s#%s %d', M.get_or_create_hl(hl), icons.diagnostics[severity], count)
        end)
        :totable()

    return table.concat(parts, ' ')
end

--- The buffer's filetype.
---@return string
function M.filetype_component()
    local devicons = require 'nvim-web-devicons'

    -- Special icons for some filetypes.
    local special_icons = {
        DiffviewFileHistory = { icons.misc.git, 'Number' },
        DiffviewFiles = { icons.misc.git, 'Number' },
        OverseerForm = { icons.misc.toolbox, 'Special' },
        OverseerList = { icons.misc.toolbox, 'Special' },
        ['ccc-ui'] = { icons.misc.palette, 'Comment' },
        ['dap-view'] = { icons.misc.bug, 'Special' },
        ['grug-far'] = { icons.misc.search, 'Constant' },
        codecompanion = { icons.misc.robot, 'Conditional' },
        fzf = { icons.misc.terminal, 'Special' },
        gitcommit = { icons.misc.git, 'Number' },
        gitrebase = { icons.misc.git, 'Number' },
        lazy = { icons.symbol_kinds.Method, 'Special' },
        lazyterm = { icons.misc.terminal, 'Special' },
        minifiles = { icons.symbol_kinds.Folder, 'Directory' },
        qf = { icons.misc.search, 'Conditional' },
    }

    local filetype = vim.bo.filetype
    if filetype == '' then
        filetype = '[No Name]'
    end

    local icon, icon_hl
    if special_icons[filetype] then
        icon, icon_hl = unpack(special_icons[filetype])
    else
        local buf_name = vim.api.nvim_buf_get_name(0)
        local name, ext = vim.fn.fnamemodify(buf_name, ':t'), vim.fn.fnamemodify(buf_name, ':e')

        icon, icon_hl = devicons.get_icon(name, ext)
        if not icon then
            icon, icon_hl = devicons.get_icon_by_filetype(filetype, { default = true })
        end
    end
    icon_hl = M.get_or_create_hl(icon_hl)

    return string.format('%%#%s#%s %%#StatusLineTitle#%s', icon_hl, icon, filetype)
end

--- File-content encoding for the current buffer.
---@return string
function M.encoding_component()
    local encoding = vim.opt.fileencoding:get()
    return encoding ~= '' and string.format('%%#StatusLineModeSeparatorOther# %s', encoding) or ''
end

--- The current line, total line count, and column position.
---@return string
function M.position_component()
    local line = vim.fn.line('.')
    local line_count = vim.api.nvim_buf_line_count(0)
    local col = vim.fn.virtcol('.')

    return table.concat {
        '%#StatusLineItalic#l: ',
        string.format('%%#StatusLineTitle#%d', line),
        string.format('%%#StatusLineItalic#/%d c: %d', line_count, col),
    }
end

local right_highlight = ' 🮊'
function M.right_mode_highlight_component()
    return string.format('%%#StatusLineModeSeparator%s#%s', mode_highlight_group(), right_highlight)
end

function M.search_component()
    if vim.v.hlsearch == 0 then
        return ''
    end

    local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
    if not ok or next(result) == nil then
        return ''
    end

    local search_term = vim.fn.getreg('/')
    if #search_term > 25 then
        search_term = search_term:sub(1, 24) .. require('icons').misc.ellipsis
    end
    local denominator = math.min(result.total, result.maxcount)
    return table.concat {
        require('icons').misc.search,
        ' %#StatusLineItalic#/',
        search_term,
        ' %#StatusLine#[',
        '%#StatusLineTitle#',
        result.current,
        '%#StatusLineItalic#/',
        denominator,
        '%#StatusLine#]',
    }
end

function M.venv_component()
    if not package.loaded['venv-selector'] then
        return nil
    end
    local render = require('venv-selector.statusline.lualine').render()
    return render and render ~= '' and render or nil
end

--- Renders the statusline.
---@return string
function M.render()
    ---@param components string[]
    ---@return string
    local function concat_components(components)
        return vim.iter(components)
            :filter(function(x) return #x > 0 end)
            :join(' %#StatusLineSeparator#󰿟 ')
    end

    return table.concat {
        M.mode_component(),
        '  ',
        concat_components {
            M.git_component(),
            M.filename_component(),
            M.dap_component() or M.lsp_progress_component(),
        },
        '%#StatusLine#%=',
        concat_components {
            M.search_component(),
            M.diagnostics_component(),
            M.venv_component(),
            M.filetype_component(),
            M.encoding_component(),
            M.position_component(),
        },
        M.right_mode_highlight_component(),
    }
end

function M.setup()
    vim.o.statusline = "%!v:lua.require'statusline'.render()"

    vim.api.nvim_create_autocmd('LspProgress', {
        group = vim.api.nvim_create_augroup('mariasolos/statusline', { clear = true }),
        desc = 'Update LSP progress in statusline',
        pattern = { 'begin', 'end' },
        callback = function(args)
            -- This should in theory never happen, but I've seen weird errors.
            if not args.data then
                return
            end

            progress_status = {
                client = vim.lsp.get_client_by_id(args.data.client_id).name,
                kind = args.data.params.value.kind,
                title = args.data.params.value.title,
            }

            if progress_status.kind == 'end' then
                progress_status.title = nil
                -- Wait a bit before clearing the status.
                vim.defer_fn(function()
                    vim.cmd.redrawstatus()
                end, 3000)
            else
                vim.cmd.redrawstatus()
            end
        end,
    })
end

return M
