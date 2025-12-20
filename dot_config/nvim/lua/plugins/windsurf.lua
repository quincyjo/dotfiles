return {
    'Exafunction/windsurf.nvim',
    event = 'InsertEnter',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'saghen/blink.cmp',
    },
    opts = {
        enable_cmp_source = false,
        virtual_text = {
            enabled = true,
        },
        filetypes = {
            oil = false,
        },
    },
    config = function(_, opts)
        require("codeium").setup(opts)
    end,
}
