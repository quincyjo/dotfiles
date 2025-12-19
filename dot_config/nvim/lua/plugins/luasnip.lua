return {
    {
        enabled = true,
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            delete_check_events = 'TextChanged',
        },
        keymap = {

        },
        config = function(_, opts)
            local ls = require 'luasnip'

            ls.setup(opts)

            require('luasnip.loaders.from_lua').lazy_load {
                paths = vim.fn.stdpath 'config' .. '/lua/snippets',
            }

            require("luasnip.loaders.from_vscode").lazy_load()

            vim.keymap.set({ 'i', 's' }, '<C-c>', function()
                if ls.choice_active() then
                    require 'luasnip.extras.select_choice' ()
                end
            end, { desc = 'Select choice' })

            vim.keymap.set({ "i", "s" }, "<C-j>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end, { silent = true })
        end,
    },
}
