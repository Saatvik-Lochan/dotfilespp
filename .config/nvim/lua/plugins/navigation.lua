return {
  {
    'ThePrimeagen/harpoon',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>a",     function() require('harpoon.mark').add_file() end,        desc = "[a]dd file" },
      { "<leader><Tab>", function() require('harpoon.ui').toggle_quick_menu() end, desc = "[a]dd file" },
      { "<leader>1",     function() require('harpoon.ui').nav_file(1) end,         desc = "Goto File [1]" },
      { "<leader>2",     function() require('harpoon.ui').nav_file(2) end,         desc = "Goto File [2]" },
      { "<leader>3",     function() require('harpoon.ui').nav_file(3) end,         desc = "Goto File [3]" },
      { "<leader>4",     function() require('harpoon.ui').nav_file(4) end,         desc = "Goto File [4]" },
      { "<leader>5",     function() require('harpoon.ui').nav_file(5) end,         desc = "Goto File [5]" },
    }
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
  },
  {
    'kevinhwang91/nvim-bqf'
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>.", function()
        require('telescope').extensions.file_browser.file_browser({ path = "%:p:h" })
      end }
    },
    config = function()
      -- local fb_actions = require('telescope').extensions.file_browser.actions
      local actions = require('telescope.actions')
      require('telescope').setup {
        extensions = {
          file_browser = {
            sorting_strategy = "ascending",
            default_selection_index = 2,
            mappings = {
              ["i"] = {
                ["<C-i>"] = actions.select_default,
                ["<C-w>"] = function() 
                  vim.api.nvim_input("<c-s-w>")
                end,
                ["<C-u>"] = false
              }
            }
          }
        }
      }

      require("telescope").load_extension("file_browser")
    end

  }
}
