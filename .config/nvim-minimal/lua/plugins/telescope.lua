return { -- potential speedup with fzf native
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'mollerhoj/telescope-recent-files.nvim',
  },
  config = function()
    local actions = require('telescope.actions')

    require("telescope").setup {
      defaults = {
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--trim"           -- add this value
        },
        mappings = {
          i = {
            ["C-U"] = false,
            ["C-S"] = false
          },
          n = {
            ["C-S"] = actions.close
          }
        },
      },
      pickers = {
        theme = 'ivy'
      }
    }

    require("telescope").load_extension("recent-files")
  end,

  keys = function()
    local builtin = require('telescope.builtin')
    local telescope = require('telescope')

    return {
      { "<leader>sh", builtin.help_tags,   "[S]earch [H]elp" },
      { "<leader>sg", builtin.live_grep,   "[S]earch [G]rep" },
      { "<leader>sc", builtin.colorscheme, "[S]earch [C]olourschemes" },
      { "<leader>se", function()
        telescope.extensions['recent-files'].recent_files({})
      end, "[S]earch [E]ntites (recent files)" },
      { "<leader>sm", function() builtin.lsp_workspace_symbols({ symbols = 'function' }) end, { desc = "[S]earch workspace [M]ethods (functions)" } },
      { "<leader>sw", builtin.lsp_dynamic_workspace_symbols, { desc = "Search workspace symbols" } },
      { "<leader>sd", builtin.lsp_document_symbols, { desc = "Search document symbols" } }

    }
  end
}
