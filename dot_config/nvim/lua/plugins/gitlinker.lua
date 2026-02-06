return {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        mappings = nil,
    },
    keys = {
        { '<leader>gy', mode = { 'n' }, '<cmd>lua require("gitlinker").get_buf_range_url("n")<cr>', desc = 'Copy git url' },
        { '<leader>gy', mode = { 'v' }, '<cmd>lua require("gitlinker").get_buf_range_url("v")<cr>', desc = 'Copy git url' },
        {
            '<leader>go',
            mode = { 'n' },
            '<cmd>lua require"gitlinker".get_buf_range_url("n", {action_callback = require"gitlinker.actions".open_in_browser})<cr>',
            -- { silent = true }
        },
        {
            '<leader>go',
            mode = { 'v' },
            '<cmd>lua require"gitlinker".get_buf_range_url("v", {action_callback = require"gitlinker.actions".open_in_browser})<cr>',
            -- {}
        }
    }
}
