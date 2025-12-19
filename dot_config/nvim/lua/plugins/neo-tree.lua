return {
    -- neo-tree
    -- File tree.
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons", -- optional, but recommended
        },
        -- lazy = false,
        cmd = "Neotree",
        opts = {
            close_if_last_window = true,
            enable_get_status = true,
            popup_border_style = "NC",
            source_selector = {
                winbar = true,
                statusline = false,
            }
        }
    },

    --[[
    {
        "nvim-tree/nvim-tree.lua"
    },
    ]]
}
