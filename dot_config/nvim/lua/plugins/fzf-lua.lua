return {
    -- fzf-lua
    -- Fuzzy command palletes.
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {},
        keys = {
            { mode = { 'n' }, '<C-\\>', '<Cmd>lua require\'fzf-lua\'.buffers()<CR>' },
            -- Commented out for now due to conflict
            -- { mode = { 'n' }, '<C-k>', '<Cmd>lua require\'fzf-lua\'.builtin()<CR>'},
            { mode = { 'n' }, '<C-p>',  '<Cmd>lua require\'fzf-lua\'.files()<CR>' },
            -- Accessible via <C-g> twice and prefer for window navigation.
            -- { mode = { 'n' }, '<C-l>', '<Cmd>lua require\'fzf-lua\'.live_grep()<CR>'},
            { mode = { 'n' }, '<C-g>',  '<Cmd>lua require\'fzf-lua\'.grep_project()<CR>' },
            { mode = { 'n' }, '<F1>',   '<Cmd>lua require\'fzf-lua\'.help_tags()<CR>' }
        }
    },
}
