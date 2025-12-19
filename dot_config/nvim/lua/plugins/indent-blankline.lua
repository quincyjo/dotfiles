return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
        scope = {
            highlight = {
                'RainbowDelimiterRed',
                'RainbowDelimiterYellow',
                'RainbowDelimiterBlue',
                'RainbowDelimiterOrange',
                'RainbowDelimiterGreen',
                'RainbowDelimiterViolet',
                'RainbowDelimiterCyan',
            }
        }
    },
    config = function(_, opts)
        local hooks = require "ibl.hooks"
        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
        require('ibl').setup(opts)
    end,
}
