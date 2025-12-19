return {
    {
        enabled = false,
        "zbirenbaum/copilot.lua",
        requires = {
            "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
        },
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({})
        end,
        opts = {
            -- The panel is useless.
            panel = { enabled = false },
            suggestion = {
                enabled = true,
                auto_trigger = true,
                hide_during_completion = false,
                keymap = {
                    accept = '<C-.>',
                    accept_word = '<M-w>',
                    accept_line = '<M-l>',
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '<C-/>',
                },
            },
            --[[
            filetypes = {
                markdown = true,
                yaml = true,

            },
            ]]
        },
    },
    --[[ Blink integraion, if desired.
    {
      "giuxtaposition/blink-cmp-copilot",
      dependencies = { "zbirenbaum/copilot.lua" }
    }
    ]]
}
