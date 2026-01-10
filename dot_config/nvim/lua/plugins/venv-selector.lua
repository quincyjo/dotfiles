return {
    'linux-cultist/venv-selector.nvim',
    dependencies = {
        'neovim/nvim-lspconfig',
        'ibhagwan/fzf-lua',
    },
    ft = 'python',
    keys = {
        { '<leader>v', mode = { 'n' }, '<cmd>VenvSelect<cr>' },
    },
    ---@module 'venv-selector'
    ---@type venv-selector.Settings
    opts = {},
}
