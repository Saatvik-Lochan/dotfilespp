return {
  { "ellisonleao/gruvbox.nvim", config = function() vim.cmd("colorscheme gruvbox") end },
  { "sainnhe/gruvbox-material" },
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
      'MeanderingProgrammer/render-markdown.nvim',
      dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
      ---@module 'render-markdown'
      ---@type render.md.UserConfig
      opts = {},
  }
}
