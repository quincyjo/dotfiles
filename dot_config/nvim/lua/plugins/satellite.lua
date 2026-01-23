return {
    'lewis6991/satellite.nvim',
    opts = {
        width = 20,
        handlers = {
            cursor = {
                enable = false,
            },
            gitsigns = {
                enable = true,
                -- Workaround for https://github.com/lewis6991/satellite.nvim/issues/94
                overlap = true,
                signs = {
                    add = "│",
                    change = "│",
                    delete = "-",
                },
            },
        },
    },
}
