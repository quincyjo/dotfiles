local qubit = require('qubit-lualine')

return {
    {
        enabled = false,
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = qubit.config
    },
}
