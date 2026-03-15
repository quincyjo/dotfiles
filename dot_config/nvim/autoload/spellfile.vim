" Shim for spellfile#WritableSpellDir removed in nvim 0.12
" Required by vim-dirtytalk's DirtytalkUpdate
function! spellfile#WritableSpellDir()
    return stdpath('data') . '/site/spell'
endfunction
