function MapKey(key, todo, desc, modes)
	modes = modes or 'n'

	local opts = { silent = true, remap = false }

	if desc ~= nil then
		opts['desc'] = desc
	end

	vim.keymap.set(modes, key, todo, opts)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

MapKey('<C-S>', '<Esc>', "Standard Escape", {'i', 'v', 'o', 't', 'c' })
MapKey('<C-e>', '3<C-e>', "Faster Down", { 'n', 'v', 'o' })
MapKey('<C-y>', '3<C-y>', "Faster Up", { 'n', 'v', 'o' })
MapKey('-', ':e %:h<cr>', "Open file")
MapKey('H', '^', "Super left", { 'n', 'v', 'o' })
MapKey('L', '$', "Super right", { 'n', 'v', 'o' })
MapKey('go', 'gd', "GO to definition (hurts my hand to type gd)")
MapKey('<leader>`', ':b#<cr>', "Toggle previous file")

MapKey('<C-h>', ':bp<cr>', "Previous Buffer")
MapKey('<C-l>', ':bn<cr>', "Next Buffer")
MapKey('<C-j>', ':cn<cr>', "Quick fix next")
MapKey('<C-k>', ':cp<cr>', "Quick fix previous")

MapKey('<leader>qo', ':copen<cr>', "Open quickfix list")
MapKey('<leader>qt', ':cclose<cr>', "Close quickfix list")

require("general")
require("config.lazy")
