-- minimal.lua
-- Minimal Neovim config for gitsigns + statuscolumn with lazy.nvim

-- Bootstrap lazy.nvim if missing
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Lazy.nvim plugin setup
require("lazy").setup({
  -- Plugin manager itself
  "folke/lazy.nvim",

  -- Plugins to test
  "lewis6991/gitsigns.nvim",
  "luukvbaal/statuscol.nvim",
}, {
  defaults = { lazy = false },  -- install and load plugins immediately
})

-- Basic options
vim.o.nu = true
vim.o.relativenumber = true
vim.o.numberwidth = 3

-- Gitsigns setup
require("gitsigns").setup({
	signcolumn = true
})

-- Statuscolumn setup
require("statuscol").setup({
  segments = {
    -- Git signs segment
    {
      sign = {
        namespace = { "gitsigns" },
        maxwidth = 1,
        colwidth = 1,
        auto = false,
        wrap = false,
        fillchar = " ",
      },
    },
    -- Line numbers segment
    {
      text = { "%l" },
      hl = "LineNr",
    },
  }
})

