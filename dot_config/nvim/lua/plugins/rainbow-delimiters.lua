return {
    "HiPhish/rainbow-delimiters.nvim",
    opts   = {
        strategy = {
            [''] = 'rainbow-delimiters.strategy.global',
            vim = 'rainbow-delimiters.strategy.local',
        },
        query = {
            [''] = 'rainbow-delimiters',
            lua = 'rainbow-blocks',
        },
        priority = {
            [''] = 110,
            lua = 210,
        },
        highlight = {
            'RainbowDelimiterRed',
            'RainbowDelimiterYellow',
            'RainbowDelimiterCyan',
            'RainbowDelimiterOrange',
            'RainbowDelimiterGreen',
            'RainbowDelimiterViolet',
            'RainbowDelimiterBlue',
        },
    },
    config = function(_, opts)
        require('rainbow-delimiters.setup').setup(opts)
    end,
}
