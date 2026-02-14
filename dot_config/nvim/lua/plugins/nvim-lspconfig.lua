return {
    {
        enabled = true,
        lazy = false,
        "neovim/nvim-lspconfig",
        config = function()
            vim.lsp.enable('css_variables')
            vim.lsp.enable('cssls')
            vim.lsp.enable('cssmodules_ls')
            vim.lsp.enable('html')
            vim.lsp.enable('lua_ls')
            vim.lsp.enable('pyright')
            vim.lsp.enable('pyrefly')
            vim.lsp.enable('ruff')
            vim.lsp.enable('ty')
            vim.lsp.enable('ts_ls')
            vim.lsp.enable('vimls')
            vim.lsp.enable('taplo')
            vim.lsp.enable('hls')

            vim.lsp.config('hls', {
                filetypes = { 'haskell', 'lhaskell', 'cabal' },
                cmd = { "haskell-language-server-wrapper", "--lsp" },
            })

            -- Enable nvim type information when in nvim config dir.
            vim.lsp.config('lua_ls', {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath('config')
                            and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                        then
                            return
                        end
                    end

                    --[[ Disabled in favour of lazydev.
                    local path = vim.fn.expand("$HOME/.local/share/nvim/lazy")
                    local content = vim.fn.readdir(path)
                    local libraries = { vim.env.VIMRUNTIME }
                    -- Load lua lazy plugins into the workspace libraries.
                    for _, plugin in ipairs(content) do
                        local plugin_path = path .. "/" .. plugin
                        if vim.fn.isdirectory(plugin_path) == 1 then
                            for _, subdir in ipairs(vim.fn.readdir(plugin_path)) do
                                if subdir == 'lua' then
                                    table.insert(libraries, plugin_path)
                                    break
                                end
                            end
                        end
                    end
                    ]]

                    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                        runtime = {
                            version = 'LuaJIT',
                            -- Tell the language server how to find Lua modules same way as Neovim
                            -- (see `:h lua-module-load`)
                            path = {
                                'lua/?.lua',
                                'lua/?/init.lua',
                            },
                        },
                        -- Make the server aware of Neovim runtime files
                        workspace = {
                            checkThirdParty = false,
                            -- library = libraries,
                        }
                    })
                end,
                settings = {
                    Lua = {}
                }
            })
        end,
    }
}
