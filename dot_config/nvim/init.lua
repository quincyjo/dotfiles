-- Confiuration.
require('config.settings')
require('config.keymaps')
require('config.commands')
require('config.autocmds')

-- My custom stuff.
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
require('marks').setup()
require('lsp').setup()

-- Load lazy.nvim.
require('config.lazy')
