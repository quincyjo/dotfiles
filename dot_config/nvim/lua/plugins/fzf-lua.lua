return {
    -- fzf-lua
    -- Fuzzy command palettes.
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {},
        keys = {
            { mode = { 'n' }, '<C-\\>', '<Cmd>lua require\'fzf-lua\'.buffers()<CR>' },
            { mode = { 'n' }, '<C-q>', '<Cmd>lua require\'fzf-lua\'.builtin()<CR>'},
            { mode = { 'n' }, '<C-p>',  '<Cmd>lua require\'fzf-lua\'.files()<CR>' },
            { mode = { 'n' }, '<C-g>',  '<Cmd>lua require\'fzf-lua\'.grep_project()<CR>' },
            { mode = { 'n' }, '<F1>',   '<Cmd>lua require\'fzf-lua\'.help_tags()<CR>' },
            { mode = { 'n' }, 'z=',   '<Cmd>lua require\'fzf-lua\'.spell_suggest()<CR>' },
        }
    },
}
