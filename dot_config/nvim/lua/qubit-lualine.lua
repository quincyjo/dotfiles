-- Eviline config for lualine
-- Author: shadmansaleh
-- Credit: glepnir

local icons = require('icons')

local M = {}

-- Color table for highlights
-- stylua: ignore
local colors = {
  bg       = '#202328',
  fg       = '#bbc2cf',
  yellow   = '#ECBE7B',
  cyan     = '#008080',
  darkblue = '#081633',
  green    = '#98be65',
  orange   = '#FF8800',
  violet   = '#a9a1e1',
  magenta  = '#c678dd',
  blue     = '#51afef',
  red      = '#ec5f67',
}

local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
  end,
  hide_in_width = function()
    return vim.fn.winwidth(0) > 80
  end,
  check_git_workspace = function()
    local filepath = vim.fn.expand('%:p:h')
    local gitdir = vim.fn.finddir('.git', filepath .. ';')
    return gitdir and #gitdir > 0 and #gitdir < #filepath
  end,
}

-- Config
local config = {
  options = {
    -- Disable sections and component separators
    component_separators = '',
    section_separators = '',
    theme = {
      -- We are going to use lualine_c an lualine_x as left and
      -- right section. Both are highlighted by c theme .  So we
      -- are just setting default looks o statusline
      normal = { c = { fg = colors.fg, bg = colors.bg } },
      inactive = { c = { fg = colors.fg, bg = colors.bg } },
    },
    globalstatus = true,
  },
  sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    -- These will be filled later
    lualine_c = {},
    lualine_x = {},
  },
  inactive_sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
}

local mode_to_str = {
    ['n'] = 'NORMAL',
    ['no'] = 'OP-PENDING',
    ['nov'] = 'OP-PENDING',
    ['noV'] = 'OP-PENDING',
    ['no\22'] = 'OP-PENDING',
    ['niI'] = 'NORMAL',
    ['niR'] = 'NORMAL',
    ['niV'] = 'NORMAL',
    ['nt'] = 'NORMAL',
    ['ntT'] = 'NORMAL',
    ['v'] = 'VISUAL',
    ['vs'] = 'VISUAL',
    ['V'] = 'VISUAL',
    ['Vs'] = 'VISUAL',
    ['\22'] = 'VISUAL',
    ['\22s'] = 'VISUAL',
    ['s'] = 'SELECT',
    ['S'] = 'SELECT',
    ['\19'] = 'SELECT',
    ['i'] = 'INSERT',
    ['ic'] = 'INSERT',
    ['ix'] = 'INSERT',
    ['R'] = 'REPLACE',
    ['Rc'] = 'REPLACE',
    ['Rx'] = 'REPLACE',
    ['Rv'] = 'VIRT REPLACE',
    ['Rvc'] = 'VIRT REPLACE',
    ['Rvx'] = 'VIRT REPLACE',
    ['c'] = 'COMMAND',
    ['cv'] = 'VIM EX',
    ['ce'] = 'EX',
    ['r'] = 'PROMPT',
    ['rm'] = 'MORE',
    ['r?'] = 'CONFIRM',
    ['!'] = 'SHELL',
    ['t'] = 'TERMINAL',
}

local mode_color = {
    n = colors.red,
    i = colors.green,
    v = colors.blue,
    [''] = colors.blue,
    V = colors.blue,
    c = colors.magenta,
    no = colors.red,
    s = colors.orange,
    S = colors.orange,
    [''] = colors.orange,
    ic = colors.yellow,
    R = colors.violet,
    Rv = colors.violet,
    cv = colors.red,
    ce = colors.red,
    r = colors.cyan,
    rm = colors.cyan,
    ['r?'] = colors.cyan,
    ['!'] = colors.red,
    t = colors.red,
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end

-- Inserts a component in lualine_c at left section
local function ins_windbar_left(component)
  table.insert(config.winbar.lualine_c, component)
  table.insert(config.inactive_winbar.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_windbar_right(component)
  table.insert(config.winbar.lualine_x, component)
  table.insert(config.inactive_winbar.lualine_x, component)
end

local mode_component = {
  function()
    return '▊ ' .. mode_to_str[vim.fn.mode()] .. ' '
  end,
  color = function()
    return { fg = mode_color[vim.fn.mode()] }
  end,
  padding = { right = 1 },
}

local mode_highlight_component = {
  function()
    return '▊'
  end,
  color = function()
    -- auto change color according to neovims mode
    return { fg = mode_color[vim.fn.mode()] }
  end,
  padding = { left = 0 },
}


local git_branch_component = {
  'branch',
  icon = icons.git.branch,
  color = { fg = colors.violet, gui = 'bold' },
}

local git_diff_component = {
  'diff',
  -- Is it me or the symbol for modified us really weird
  symbols = { added = icons.git.additions, modified = icons.git.modified, removed = icons.git.deletions },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.orange },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
}

local diagnostics_component = {
  'diagnostics',
  sources = { 'nvim_diagnostic' },
  symbols = { error = icons.diagnostics.ERROR, warn = icons.diagnostics.WARN, info = icons.diagnostics.INFO },
  diagnostics_color = {
    error = { fg = colors.red },
    warn = { fg = colors.yellow },
    info = { fg = colors.cyan },
  },
}

local filename_component = {
  'filename',
  cond = conditions.buffer_not_empty,
  color = { fg = colors.magenta, gui = 'bold' },
}

local lsp_status_component = { 'lsp_status' }

local fileformat_component = {
  'fileformat',
  fmt = string.upper,
  color = { fg = colors.green, gui = 'bold' },
}

local encoding_component = {
  'o:encoding', -- option component same as &encoding in viml
  fmt = string.upper, -- I'm not sure why it's upper case either ;)
  cond = conditions.hide_in_width,
  color = { fg = colors.green, gui = 'bold' },
}

local spacer = {
  function()
    return '%='
  end,
}

--- The current line, total line count, and column position.
local position_component = {
    function()
        local line = vim.fn.line '.'
        local line_count = vim.api.nvim_buf_line_count(0)
        local col = vim.fn.virtcol '.'

        return table.concat {
            '%#StatuslineItalic#l: ',
            string.format('%%#StatuslineTitle#%d', line),
            string.format('%%#StatuslineItalic#/%d c: %d', line_count, col),
        }
    end
}

-- Global status
ins_left(mode_component)
ins_left(filename_component)
ins_left(git_diff_component)

ins_left(spacer)

ins_right { 'searchcount' }
ins_right(diagnostics_component)
ins_right(lsp_status_component)
ins_right(git_branch_component)
-- ins_right(lsp_name_component)
ins_right(mode_highlight_component)

-- Constant winbar
ins_windbar_left(mode_highlight_component)
ins_windbar_left(filename_component)
ins_windbar_left(git_diff_component)

ins_windbar_left(spacer)

ins_windbar_right(diagnostics_component)
ins_windbar_right { 'filetype' }
ins_windbar_right(encoding_component)
ins_windbar_right(fileformat_component)
ins_windbar_right(position_component)
ins_windbar_right(mode_highlight_component)
-- ins_windbar_right(progress_component)
-- ins_windbar_right(location_component)


M.config = config

return M

