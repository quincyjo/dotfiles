-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Keep the cursor centered while jumping.
vim.keymap.set({ 'n', 'v' }, 'n', 'nzz')
vim.keymap.set({ 'n', 'v' }, 'N', 'Nzz')
vim.keymap.set({ 'n', 'v' }, '<C-d>', '<C-d>zz')
vim.keymap.set({ 'n', 'v' }, '<C-u>', '<C-u>zz')
vim.keymap.set({ 'n', 'v' }, '<C-f>', '<C-f>zz')
vim.keymap.set({ 'n', 'v' }, '<C-b>', '<C-b>zz')
vim.keymap.set({ 'n', 'v' }, '}', '}zz')
vim.keymap.set({ 'n', 'v' }, '{', '{zz')
vim.keymap.set({ 'n', 'v' }, 'G', 'Gzz')
vim.keymap.set('n', '<C-o>', '<C-o>zz')
vim.keymap.set('n', '<C-i>', '<C-i>zz')

-- Open the package manager.
vim.keymap.set('n', '<leader>L', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- Restart Neovim.
vim.keymap.set('n', '<leader>R', '<cmd>restart<cr>', { desc = 'Restart Neovim' })

-- Windows
vim.keymap.set('n', '<C-w>v', '<cmd>vsplit<cr>', { desc = 'Vertical Split' })
vim.keymap.set('n', '<C-w>s', '<cmd>split<cr>', { desc = 'Horizontal Split' })

-- Clipboard
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('n', '<leader>P', '"+P', { desc = 'Paste from system clipboard' })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Tab navigation.
vim.keymap.set('n', '<C-w>t', '<cmd>tabnew<cr>', { desc = 'New tab page' })
vim.keymap.set('n', '<C-t>', '<cmd>tabnew<cr>', { desc = 'New tab page' })
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tab page' })
vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<cr>', { desc = 'New tab page' })
vim.keymap.set('n', '<leader>to', '<cmd>tabonly<cr>', { desc = 'Close other tab pages' })

-- Escape binding
vim.keymap.set({ 'i', 'v', 's' }, "<C-k>", "<Esc>", {})

vim.keymap.set('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move current line down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move current line up' })

vim.keymap.set({ 'i', 'n', 'v' }, '<C-s>', '<esc>:w<cr>', { desc = 'Exit insert mode and save changes' })

