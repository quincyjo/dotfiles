return {
    {
        "rmagatti/auto-session",
        lazy = false,

        ---@module "auto-session"
        ---@type AutoSession.Config
        opts = {
            auto_create = false,
            auto_restore = true,
            auto_save = true,
            git_use_branch_name = true,
            pre_save_cmds = { "Neotree close" },
            -- post_restore_cmds = { "Neotree filesystem show" }
        },
    },

}
