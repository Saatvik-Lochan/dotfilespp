vim.keymap.set({ 'n' }, '<C-q>', '%', { noremap = true })
vim.keymap.set('n', '<leader>in', ':e $MYVIMRC<cr>', {})
vim.keymap.set('n', '<leader>it', ':e ~/repos/dotfiles/nvim/potentials.md<cr>', {})

vim.keymap.set('n', '<leader>`', '<cmd>b#<cr>', {})

vim.keymap.set({ 'n', 'o', 'v' }, 'H', '^', { noremap = true })
vim.keymap.set({ 'n', 'o', 'v' }, 'L', '$', { noremap = true })

-- Escape remaps
vim.keymap.set({ 'i', 'n', 'v', 'o', 'c' }, '<C-s>', '<esc>', { noremap = true })
vim.keymap.set({ 'n' }, '<C-W>d', ':bd<cr>', { noremap = true })

vim.keymap.set({ 'n', 'o', 'v' }, '<C-k>', '5k', { noremap = true })
vim.keymap.set({ 'n', 'o', 'v' }, '<C-j>', '5j', { noremap = true })

-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set("n", 'U', function() require('homegrown.visual_u').visual_undo() end, { silent = true })
vim.keymap.set("n", '<bs>', "<cmd>w<cr>", {})

-- Lua keybinds
vim.keymap.set("n", '<leader>rf', "<cmd>w<cr><cmd>source %<cr>", { silent = true })

-- Typo issue
vim.keymap.set("n", 'q:', ":q", { silent = true })

