return {
    -- not maintained
    -- "norcalli/nvim-colorizer.lua",
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
        user_default_options = {
            names = false,
            xterm = true,
        },
    },
    config = function(_, opts)
        require("colorizer").setup(opts)
    end,
}
