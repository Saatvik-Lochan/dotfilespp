local set = vim.opt

set.clipboard = "unnamedplus"

set.nu = true
set.relativenumber = false

set.softtabstop = 2
set.shiftwidth = 2
set.expandtab = true

set.smartindent = true

set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.vim/undodir"
set.undofile = true

set.hlsearch = false
set.incsearch = true
set.ignorecase = true
set.smartcase = true

set.termguicolors = true

set.scrolloff = 8
set.isfname:append("@-@")

set.updatetime = 50

set.colorcolumn = "80"
set.signcolumn = "number"
