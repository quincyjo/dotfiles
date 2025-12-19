require('settings')
require('keymaps')
require('commands')
require('autocmds')
require('statusline').setup()
require('winbar').setup {
    separator = ' ' .. require('icons').arrows.right .. ' ',
    abbreviated_dirs = {
        PROJECTS = {
            path = vim.env.HOME .. '/Projects',
            transparent = true,
        },
    },
}
require('marks')
require('lsp')

require('config.lazy')

