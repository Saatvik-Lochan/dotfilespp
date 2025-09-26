return {
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    opts = true
  },
  {
      'Chaitanyabsprip/fastaction.nvim',
      event = "VeryLazy",
      opts = {},
  },
  {
    "echasnovski/mini.nvim",
    version = '*',
    config = function()
      require('mini.pairs').setup()
      require('mini.ai').setup()
      require('mini.splitjoin').setup()
    end
  },

  {
    "mg979/vim-visual-multi"
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    }
  },

  {
    "rgroli/other.nvim",
    config = function()
      require("other-nvim").setup({
        mappings = {
          {
            pattern = "/src/(.*).cpp",
            target = "/include/%1.hpp"
          },
          {
            pattern = "/include/(.*).hpp",
            target = "/src/%1.cpp"
          }
        }
      })

      vim.keymap.set("n", "gh", ":Other<cr>", { desc = "Go to header" })
    end
  },

  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional
    },
    keys = {
      { "<leader>g", function() require('neogit').open() end, desc = "Neo[g]it" }
    },
    config = true
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      -- ripped straight from the github README
      -- where did the 'MINIMAL' in nvim-minimal go?
      require('gitsigns').setup {
        on_attach = function(bufnr)
          local gitsigns = require('gitsigns')

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then
              vim.cmd.normal({ ']c', bang = true })
            else
              gitsigns.nav_hunk('next')
            end
          end)

          map('n', '[c', function()
            if vim.wo.diff then
              vim.cmd.normal({ '[c', bang = true })
            else
              gitsigns.nav_hunk('prev')
            end
          end)

          -- Actions
          map('n', '<leader>hs', gitsigns.stage_hunk, { desc = "[H]unk [S]tage" })
          map('n', '<leader>hr', gitsigns.reset_hunk, { desc = "[H]unk [R]eset" })

          map('v', '<leader>hs', function()
            gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
          end, { desc = "[H]unk [S]tage" })

          map('v', '<leader>hr', function()
            gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
          end, { desc = "[H]unk [R]eset" })

          map('n', '<leader>hS', gitsigns.stage_buffer, { desc = "[H]unk [S]tage Buffer" })
          map('n', '<leader>hR', gitsigns.reset_buffer, { desc = "[H]unk [R]eset Buffer" })
          map('n', '<leader>hp', gitsigns.preview_hunk, { desc = "[H]unk [P]review" })
          map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = "[H]unk [I]nline Preview" })

          map('n', '<leader>hb', function()
            gitsigns.blame_line({ full = true })
          end, { desc = "[H]unk [B]lame" })

          map('n', '<leader>hd', gitsigns.diffthis, { desc = "[H]unk [D]iff" })

          map('n', '<leader>hD', function()
            gitsigns.diffthis('~')
          end, { desc = "[H]unk [D]iff ~" })

          map('n', '<leader>hQ', function() gitsigns.setqflist('all') end, { desc = "[H]unk [Q]uickfix all" })
          map('n', '<leader>hq', gitsigns.setqflist, { desc = "[H]unk [q]uickfix" })

          -- Toggles
          map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = "[T]oggle [B]lame" })
          map('n', '<leader>td', gitsigns.toggle_deleted, { desc = "[T]oggle [D]eleted" })
          map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = "[T]oggle [W]ord Diff" })

          -- Text object
          map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = "Select [H]unk" })
        end
      }
    end
  },

  {
    "debugloop/telescope-undo.nvim",
    dependencies = { -- note how they're inverted to above example
      {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    keys = {
      { -- lazy style key map
        "<leader>u",
        "<cmd>Telescope undo<cr>",
        desc = "undo history",
      },
    },
    opts = {
      extensions = {
        undo = {
          use_delta = false,
          layout_strategy = "vertical",
          layout_config = {
            preview_cutoff = 0,
            preview_height = 0.5,
          },
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension("undo")
    end,
  },
}
