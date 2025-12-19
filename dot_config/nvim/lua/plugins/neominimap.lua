local diagnostics = require('icons').diagnostics

return {
    ---@module "neominimap.config.meta"
    {
        "Isrothy/neominimap.nvim",
        version = "v3.x.x",
        lazy = true,
        keys = {
            -- Global Minimap Controls
            { "<leader>nm",  "<cmd>Neominimap Toggle<cr>",      desc = "Toggle global minimap" },
            { "<leader>no",  "<cmd>Neominimap Enable<cr>",      desc = "Enable global minimap" },
            { "<leader>nc",  "<cmd>Neominimap Disable<cr>",     desc = "Disable global minimap" },
            { "<leader>nr",  "<cmd>Neominimap Refresh<cr>",     desc = "Refresh global minimap" },

            -- Window-Specific Minimap Controls
            { "<leader>nwt", "<cmd>Neominimap WinToggle<cr>",   desc = "Toggle minimap for current window" },
            { "<leader>nwr", "<cmd>Neominimap WinRefresh<cr>",  desc = "Refresh minimap for current window" },
            { "<leader>nwo", "<cmd>Neominimap WinEnable<cr>",   desc = "Enable minimap for current window" },
            { "<leader>nwc", "<cmd>Neominimap WinDisable<cr>",  desc = "Disable minimap for current window" },

            -- Tab-Specific Minimap Controls
            { "<leader>ntt", "<cmd>Neominimap TabToggle<cr>",   desc = "Toggle minimap for current tab" },
            { "<leader>ntr", "<cmd>Neominimap TabRefresh<cr>",  desc = "Refresh minimap for current tab" },
            { "<leader>nto", "<cmd>Neominimap TabEnable<cr>",   desc = "Enable minimap for current tab" },
            { "<leader>ntc", "<cmd>Neominimap TabDisable<cr>",  desc = "Disable minimap for current tab" },

            -- Buffer-Specific Minimap Controls
            { "<leader>nbt", "<cmd>Neominimap BufToggle<cr>",   desc = "Toggle minimap for current buffer" },
            { "<leader>nbr", "<cmd>Neominimap BufRefresh<cr>",  desc = "Refresh minimap for current buffer" },
            { "<leader>nbo", "<cmd>Neominimap BufEnable<cr>",   desc = "Enable minimap for current buffer" },
            { "<leader>nbc", "<cmd>Neominimap BufDisable<cr>",  desc = "Disable minimap for current buffer" },

            -- Focus Controls
            { "<leader>nf",  "<cmd>Neominimap Focus<cr>",       desc = "Focus on minimap" },
            { "<leader>nu",  "<cmd>Neominimap Unfocus<cr>",     desc = "Unfocus minimap" },
            { "<leader>ns",  "<cmd>Neominimap ToggleFocus<cr>", desc = "Switch focus on minimap" },
        },
        init = function()
            -- The following options are recommended when layout == "float"
            vim.opt.wrap = false
            vim.opt.sidescrolloff = 36 -- Set a large value

            --- Put your configuration here
            ---@type Neominimap.UserConfig
            vim.g.neominimap = {
                auto_enable = false,
                delay = 500,
                float = {
                    window_border = 'none',
                    minimap_width = 14,
                    z_index = 30,
                },
                search = {
                    enabled = true, ---@type boolean
                    mode = "line", ---@type Neominimap.Handler.Annotation.Mode
                    priority = 20, ---@type integer
                    icon = "󰱽 ", ---@type string
                },
                mark = {
                    enabled = true, ---@type boolean
                    mode = "icon", ---@type Neominimap.Handler.Annotation.Mode
                    priority = 10, ---@type integer
                    key = "m", ---@type string
                    show_builtins = false, ---@type boolean -- shows the builtin marks like [ ] < >
                },
                diagnostic = {
                    enabled = true,
                    mode = "line",
                    icon = {
                        ERROR = diagnostics.ERROR, ---@type string
                        WARN = diagnostics.WARN, ---@type string
                        INFO = diagnostics.INFO, ---@type string
                        HINT = diagnostics.HINT, ---@type string
                    },
                }
            }
        end,
    },
}
