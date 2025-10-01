local set = vim.opt

set.clipboard = "unnamedplus"

set.relativenumber = true

set.tabstop = 2
set.shiftwidth = 2

set.smartindent = true
set.autoindent = true
set.expandtab = true
set.wrap = false

set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.vim/undodir"
set.undofile = true

set.hlsearch = false
set.incsearch = true
set.smartcase = true

set.termguicolors = true

set.scrolloff = 8
set.isfname:append("@-@")

set.numberwidth = 2

-- performance
set.updatetime = 50
set.ttyfast = true

set.synmaxcol = 200
set.wrapscan = false
set.writebackup = false

set.timeoutlen = 300
set.ttimeoutlen = 10
set.modeline = false
