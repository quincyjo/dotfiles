return {
    'Exafunction/windsurf.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'saghen/blink.cmp',
        'hrsh7th/nvim-cmp',
    },
    config = function()
        require("codeium").setup({
            virtual_text = {
                enabled = true,
            }
        })
    end
}
