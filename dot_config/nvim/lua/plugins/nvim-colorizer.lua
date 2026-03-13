return {
    -- not maintained
    -- "norcalli/nvim-colorizer.lua",
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
        options = {
            parsers = {
                names = {
                    enable = false
                },
                xterm = {
                    enable = true,
                }
            },
        },
    },
    config = function(_, opts)
        require("colorizer").setup(opts)
    end,
}
