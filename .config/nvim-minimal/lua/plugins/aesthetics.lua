return {
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd([[colorscheme gruvbox-material]])
    end
  },
  -- { "ellisonleao/gruvbox.nvim" },
  -- { "EdenEast/nightfox.nvim" }, -- lazy
  -- { "rebelot/kanagawa.nvim" },
  -- { 'AlexvZyl/nordic.nvim',    config = function() require('nordic').load() end },
  -- { "folke/tokyonight.nvim" },
  { -- requires deno
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
  {
    "folke/zen-mode.nvim",
    opts = {},
    keys = {
      { "<leader>z", ":ZenMode<cr>" }
    }
  },
}
