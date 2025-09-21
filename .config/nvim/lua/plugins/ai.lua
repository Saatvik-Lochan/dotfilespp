return {
  {
    "github/copilot.vim",
    lazy = false,
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.keymap.set("i", "<C-e>", 'copilot#Accept("<CR>")', {
        silent = true,
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      })
    end,
    keys = {
      {
        "<C-e>",
        'copilot#Accept("<CR>")',
        mode = "i",
        expr = true,
        silent = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      },
      { "<leader>ce", function() vim.cmd("Copilot enable") end,  desc = "[E]nable Copilot" },
      { "<leader>cd", function() vim.cmd("Copilot disable") end, desc = "[D]isable Copilot" },
      { "<leader>cs", function() vim.cmd("Copilot status") end,  desc = "[S]tatus of Copilot" },
    }
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    config = function()
      require("CopilotChat").setup({
        mappings = {
          submit_prompt = {
            insert = '<C-e>'
          },
        }
      })

      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'copilot-*',
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
          vim.opt_local.conceallevel = 0
          vim.b.copilot_enabled = false
        end,
      })
    end,
    keys = {
      { "<leader>co", function() require("CopilotChat").toggle() end, desc = "Open Copilot [C]hat", mode = "n" },
      { "<leader>cc", ":CopilotChatCommit<CR>",                  desc = "[C]opilot [C]ommit",  mode = "n" },

      { "<leader>co", ":'<,'>CopilotChat<CR>",                        desc = "Open Copilot [C]hat", mode = "v" },
      { "<leader>ce", ":'<,'>CopilotChatExplain<CR>",                 desc = "[C]opilot [E]xplain", mode = "v" },
      { "<leader>cr", ":'<,'>CopilotChatReview<CR>",                  desc = "[C]opilot [R]eview",  mode = "v" },
      { "<leader>cf", ":'<,'>CopilotChatFix<CR>",                     desc = "[C]opilot [F]ix",     mode = "v" },
    }
  }
}
