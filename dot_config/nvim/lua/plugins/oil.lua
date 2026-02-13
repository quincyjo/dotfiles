return {
    "refractalize/oil-git-status.nvim",
    dependencies = {
        {
            'stevearc/oil.nvim',
            ---@module 'oil'
            ---@type oil.SetupOpts
            opts = {
                win_options = {
                    signcolumn = "yes:2",
                },
            },
            dependencies = { "nvim-tree/nvim-web-devicons" },
            lazy = false,
            keys = {
                { mode = { "n" }, "-", "<cmd>Oil<cr>" }
            }
        },
    },
    config = true,
}
