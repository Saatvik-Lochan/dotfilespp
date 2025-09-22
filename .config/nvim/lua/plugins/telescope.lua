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
          "--trim" -- add this value
        },
        mappings = {
          i = {
            ["C-u"] = false,
            ["C-S"] = false
          },
        },
      },
      pickers = {
        find_files = { theme = 'ivy' },
      }
    }

    require("telescope").load_extension("recent-files")
  end,

  keys = function()
    local builtin = require('telescope.builtin')
    local telescope = require('telescope')

    local function find_files_from_root()
      local clients = vim.lsp.get_active_clients({ bufnr = 0 })
      if #clients == 0 then
        builtin.find_files()
        return
      end

      local root_dir = clients[1].config.root_dir
      if root_dir == nil then
        builtin.find_files()
        builtin.find_files()
      end

      builtin.find_files({ cwd = root_dir })
    end

    return {
      { "<leader>sh", builtin.help_tags,    "[S]earch [H]elp" },
      { "<leader>sg", builtin.live_grep,    "[S]earch [G]rep" },
      { "<leader>sc", builtin.colorscheme,  "[S]earch [C]olourschemes" },
      { "<leader>se", find_files_from_root, "[S]earch [E]ntities" },
      { "<leader>sr", function()
        telescope.extensions['recent-files'].recent_files({})
      end, "[S]earch [R]ecent (recent files)" },
      { "<leader>sm", function() builtin.lsp_workspace_symbols({ symbols = 'function' }) end, { desc = "[S]earch workspace [M]ethods (functions)" } },
      { "<leader>sw", builtin.lsp_dynamic_workspace_symbols,                                  { desc = "Search workspace symbols" } },
      { "<leader>sd", builtin.lsp_document_symbols,                                           { desc = "Search document symbols" } }

    }
  end
}
