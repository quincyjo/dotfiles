return {
    "HiPhish/rainbow-delimiters.nvim",
    main = "rainbow-delimiters.setup",
    opts = {
        condition = function(bufnr)
            local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
            return ok and parser ~= nil
        end,
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
}
