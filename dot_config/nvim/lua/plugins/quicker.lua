return {
    'stevearc/quicker.nvim',
    event = 'VeryLazy',
    opts = {
        borders = {
            vert = require('icons').misc.vertical_bar,
        },
    },
    ---@module "quicker"
    ---@type quicker.SetupOptions
    keys = {
        {
            '<leader>q',
            function() require('quicker').toggle() end,
            mode = { 'n' },
            desc = 'Toggle quickfix'
        },
        {
            '<leader>l',
            function() require('quicker').toggle { loclist = true } end,
            mode = { 'n' },
            desc = 'Toggle loclist'
        },
    },
}
