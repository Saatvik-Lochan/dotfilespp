return {
  { "sainnhe/gruvbox-material" },
  { "ellisonleao/gruvbox.nvim", config = function() vim.cmd("colorscheme gruvbox") end },
  { "EdenEast/nightfox.nvim" },
  { "rebelot/kanagawa.nvim" },
  { 'AlexvZyl/nordic.nvim' },
  { "folke/tokyonight.nvim" },
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
