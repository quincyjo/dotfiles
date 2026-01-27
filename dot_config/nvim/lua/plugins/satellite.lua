return {
    'lewis6991/satellite.nvim',
    opts = {
        handlers = {
            cursor = {
                enable = false,
            },
            gitsigns = {
                enable = true,
                -- Can set to true to avoid bg but limits sign spage.
                -- Workaround for https://github.com/lewis6991/satellite.nvim/issues/94
                overlap = false,
                signs = {
                    add = "│",
                    change = "│",
                    delete = "-",
                },
            },
        },
    },
}
