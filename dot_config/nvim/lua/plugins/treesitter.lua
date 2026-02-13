return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        branch = "main",
        build = ":TSUpdate",
        dependencies = {
            {
                'nvim-treesitter/nvim-treesitter-context',
                keys = {
                    {
                        '[c',
                        function()
                            -- Jump to previous change when in diffview.
                            if vim.wo.diff then
                                return '[c'
                            else
                                vim.schedule(function()
                                    if package.loaded['cinnamon'] then
                                        require('cinnamon').scroll(
                                            require('treesitter-context').go_to_context
                                        )
                                    else
                                        require('treesitter-context').go_to_context()
                                    end
                                end)
                                return '<Ignore>'
                            end
                        end,
                        desc = 'Jump to upper context',
                        expr = true,
                    },
                },
                config = function()
                    vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { underline = true, sp = 'Grey', fg = 'None' })
                    vim.api.nvim_set_hl(0, 'TreesitterContext', { fg = 'None' })
                    require('treesitter-context').setup {
                        -- Avoid the sticky context from growing a lot.
                        max_lines = 3,
                        -- Match the context lines to the source code.
                        multiline_threshold = 1,
                        -- Disable it when the window is too small.
                        min_window_height = 20,
                        seperator = 'X',
                        line_numbers = true,
                        multiwindow = true,
                        zindex = 20,
                    }
                end,
            },
        },
        opts = {
            install_dir = vim.fn.stdpath('data') .. '/site',
            sync_install = false,
            auto_install = true,
            ensure_installed = {
                'bash',
                'c',
                'cpp',
                'gitcommit',
                'html',
                'java',
                'javascript',
                'json',
                'json5',
                'jsonc',
                'haskell',
                'lua',
                'markdown',
                'markdown_inline',
                'python',
                'query',
                'regex',
                'scala',
                'scss',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'yaml',
                'zsh',
            },
            highlight = { enable = true },
            indent = {
                enable = true,
                -- Treesitter unindents Yaml lists for some reason.
                disable = { 'yaml' },
            },
            disable = function(_, buf)
                local max_filesize = 100 * 1024 -- 100 KB
                local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    return true
                end
            end,
        },
        config = function(_, opts)
            -- Folding
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

            require('nvim-treesitter.config').setup(opts)
            if opts.ensure_installed and type(opts.ensure_installed) == "table" then
                require('nvim-treesitter.install').install(opts.ensure_installed)
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = opts.ensure_installed,
                    callback = function()
                        pcall(vim.treesitter.start)
                    end,
                })
            end
        end,
    },
}
