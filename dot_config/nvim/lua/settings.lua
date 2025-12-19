local arrows = require('icons').arrows

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.termguicolors = true

-- Enable persistent undo
vim.opt.undofile = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false

-- Tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Folding
vim.opt.foldcolumn = '1'
vim.opt.foldlevelstart = 99
vim.wo.foldtext = ''
vim.opt.fillchars = {
    fold = ' ',
    foldclose = arrows.right,
    foldopen = arrows.down,
    foldsep = ' ',
    foldinner = ' '
}

-- Global statusline
vim.o.laststatus = 3

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Case insensitive searching UNLESS /C or the search has capitals.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Update times and timeouts.
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10
-- vim.o.winborder = 'rounded'

-- Highlight cursorline
vim.opt.cursorline = true

vim.opt.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.cmd("colorscheme qubit-true")

-- Keeping the cursor centered. (opting for bindings instead for reasons)
-- vim.opt.scrolloff = 999

