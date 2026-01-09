return {
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        -- dependencies = { 'rafamadriz/friendly-snippets' },
        dependencies = {
            'Exafunction/windsurf.nvim',
            'LuaSnip'
        },
        build = 'cargo +nightly build --release',
        event = 'InsertEnter',
        version = '1.*',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                ['<CR>'] = { 'accept', 'fallback' },
                ['<C-\\>'] = { 'hide', 'fallback' },
                ['<C-n>'] = { 'select_next', 'show' },
                ['<C-p>'] = { 'select_prev' },
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
            },
            appearance = {
                kind_icons = require('icons').symbol_kinds,
                nerd_font_variant = 'mono',
            },
            completion = {
                documentation = { auto_show = true },
                menu = {
                    scrollbar = false,
                    draw = {
                        gap = 2,
                        columns = {
                            { 'kind_icon', 'kind',              gap = 1 },
                            { 'label',     'label_description', gap = 1 },
                        },
                    },
                },
            },
            snippets = { preset = 'luasnip' },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer', 'codeium' },
                providers = {
                    codeium = { name = 'Codeium', module = 'codeium.blink', async = true },
                },
                per_filetype = {
                    oil = { 'path', 'buffer' },
                    codecompanion = { 'codecompanion' },
                },
            },
            -- See :h blink-cmp-config-fuzzy for more information
            fuzzy = { implementation = 'prefer_rust_with_warning' },
            signature = { enabled = true },
        },
    },
}
