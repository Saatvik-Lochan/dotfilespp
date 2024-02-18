-- [[ Configure Telescope ]]
local actions = require("telescope.actions")

require("telescope").setup {
	defaults = {
		mappings = {
			i = {
				['<C-u>'] = false,
				['<C-d>'] = false,
				['<C-s>'] = false,
			},
			n = {
				['<C-s>'] = actions.close,
			}
		},
		layout_strategy = 'vertical',
		layout_config = {
			height = 0.95
		},
	},
	pickers = {
		find_files = { theme = 'ivy' },
	},
	extensions = {
		undo = {
			use_delta = false
		}
	}
}

require('telescope').load_extension('fzf')
require('telescope').load_extension('undo')
vim.keymap.set('n', '<leader>u', '<cmd>UndotreeShow<cr><cmd>UndotreeFocus<cr>', { desc = '[?] Find recently opened files' })

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require('telescope.builtin').current_buffer_fuzzy_find(require("telescope.themes").get_dropdown())
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>se', function() require('telescope.builtin').find_files({ hidden = false }) end,
	{ desc = '[S]earch Files [E]ntities' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]resume' })

-- [[ Configure Alpha ]]
require('alpha').setup(require('alpha.themes.startify').config)

-- [[ Configure Virt Column ]]
require("virt-column").setup()

-- [[ Configure Oil ]]
require("oil").setup({
	keymaps = {
		["<leader>o"] = {
			callback = function()
				require('telescope.builtin')
					.find_files({ find_command = {'fd', '.', '--hidden', require('oil').get_current_dir() }})
			end,
		mode = "n",
		}
	}
})

vim.keymap.set({ 'n' }, '-', '<cmd>Oil<cr>', { desc = 'Directory Stuff', silent = true })

-- [[ Configure Mini ]]
require('mini.ai').setup()
require('mini.comment').setup()
require('mini.splitjoin').setup()
require('mini.bracketed').setup()
-- require('mini.files').setup()

-- [[ Configure nvim surround ]]
require('nvim-surround').setup()


-- [[ Configure Aerial - Symbols viewer ]]
require("aerial").setup({
	highlight_on_hover = true,
	autojump = true,
	highlight_on_jump = false,
	manage_folds = true,
	show_guides = true,
})

vim.keymap.set({ 'n', 't', 'v' }, '<Leader>k', '<cmd>AerialToggle<cr>', { desc = '[K]ool symbols', silent = true })

-- [[ Configure Hop ]]
vim.keymap.set({ 'n', 't', 'v' }, 's', function() require('hop').hint_words({ x_bias = 90 }) end,
	{ desc = '[S]lide to correct word on line' })

-- [[ Configure CamelCaseMotion ]]
vim.o.camelcasemotion_key = 'i'

-- [[ Configure Harpoon ]]
vim.keymap.set('n', '<leader>a', require('harpoon.mark').add_file, { desc = '[A]dd mark to file' })
vim.keymap.set('n', '<leader>qf', require('harpoon.ui').toggle_quick_menu, { desc = 'Toggle [Q]uick [F]iles' })
vim.keymap.set('n', '<leader>qc', require('harpoon.cmd-ui').toggle_quick_menu, { desc = 'Toggle [Q]uick [C]ommands' })

vim.keymap.set('n', '<leader>1', function() require('harpoon.ui').nav_file(1) end, { desc = '[G]o to mark [1]' })
vim.keymap.set('n', '<leader>2', function() require('harpoon.ui').nav_file(2) end, { desc = '[G]o to mark [2]' })
vim.keymap.set('n', '<leader>3', function() require('harpoon.ui').nav_file(3) end, { desc = '[G]o to mark [3]' })
vim.keymap.set('n', '<leader>4', function() require('harpoon.ui').nav_file(4) end, { desc = '[G]o to mark [4]' })
vim.keymap.set('n', '<leader>5', function() require('harpoon.ui').nav_file(5) end, { desc = '[G]o to mark [5]' })

-- [[ Configure Indent Blank Line ]]
require("ibl").setup()

-- [[ Configure Neodev ]]
require('neodev').setup()

-- [[ Configure Noice ]]
require("noice").setup({
	messages = {
		view = "mini",
		view_search = "mini",
	},
	routes = {
		{
			view = "mini",
			filter = {
				event = "msg_show",
				find = "substitutions",
			},
		},
		{ filter = { find = "fewer lines;" }, opts = { skip = true } },
		{ filter = { find = "more line;" },   opts = { skip = true } },
		{ filter = { find = "more lines;" },  opts = { skip = true } },
		{ filter = { find = "less;" },        opts = { skip = true } },
		{ filter = { find = "change;" },      opts = { skip = true } },
		{ filter = { find = "changes;" },     opts = { skip = true } },
		{ filter = { find = "indent" },       opts = { skip = true } },
		{ filter = { find = "move" },         opts = { skip = true } },
	},
	cmdline = { view = "cmdline" },
	views = {
		popupmenu = {
			size = { width = 50, height = 10 },
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},
			win_options = {
				winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
			},
		},
	},
	lsp = {
		signature = { enabled = false },
		message = {
			enabled = false,
		},
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},
	presets = {
		bottom_search = true,
		long_message_to_split = true,
		lsp_doc_border = true,
	},
})

vim.keymap.set("n", "<leader>nn", "<cmd>Noice history<cr>", {})
vim.keymap.set("n", "<leader>ns", "<cmd>Noice last<cr>", {})
vim.keymap.set("n", "<leader>ne", "<cmd>Noice errors<cr>", {})
vim.keymap.set("n", "<leader>nt", "<cmd>Noice telescope<cr>", {})

-- [[ Configure Lualine ]]
require("lualine").setup({
	sections = {
		lualine_c = vim.g.neovide and { 'filename' } or {},
		lualine_x = {
			{
				require("noice").api.statusline.mode.get,
				cond = require("noice").api.statusline.mode.has,
				color = { fg = "#ff9e64" },
			}
		},
	},
	options = {
		theme = 'gruvbox-material',
		component_separators = { left = '' },
		section_separators = { left = '' },
	}
})

-- [[ Configure Tpipeline ]]
vim.g.tpipeline_restore = 1

-- [[ Configure eyeliner ]]
require('eyeliner').setup()

vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = '#96aeeb' })
vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = '#8f449e' })

-- [[ Configure Nvim Scroll Bar ]]
require("scrollbar").setup()

-- [[ Configure Highlight Undo ]]
require('highlight-undo').setup()

-- [[ Configure Local Highligh]]
require('local-highlight').setup()

-- [[ Configure No Neck Pain ]]
require('no-neck-pain').setup()

-- [[ Configure Projects ]]
require('project_nvim').setup({
	patterns = {
		">studies",
		">code",
		">internships",
		">writing",
		">repos",
		">.config",
		"src",
	}
})

require('telescope').load_extension('projects')
vim.keymap.set('n', '<leader>sm',
	function() require 'telescope'.extensions.projects.projects(require('telescope.themes').get_ivy()) end,
	{ desc = '[S]earch [M]y Projects' })

-- [[ Configure Inlay Hints ]]
require('inlay-hints').setup()

if not vim.g.neovide then
	-- [[ Configure neoscroll ]]
	require('neoscroll').setup()

	local t    = {}
	-- Syntax: t[keys] = {function, {function arguments}}
	t['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '30' } }
	t['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '30' } }
	t['<C-b>'] = { 'scroll', { '-vim.api.nvim_win_get_height(0)', 'true', '50' } }
	t['<C-f>'] = { 'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '50' } }
	t['<C-y>'] = { 'scroll', { '-0.10', 'false', '50' } }
	t['<C-e>'] = { 'scroll', { '0.10', 'false', '50' } }
	t['zt']    = { 'zt', { '50' } }
	t['zz']    = { 'zz', { '50' } }
	t['zb']    = { 'zb', { '50' } }

	require('neoscroll.config').set_mappings(t)

	-- [[ Configure Barbecue ]]
	-- triggers CursorHold event faster
	require("barbecue").setup({
		create_autocmd = false, -- prevent barbecue from updating itself automatically
	})

	vim.api.nvim_create_autocmd({
		"WinScrolled", -- or WinResized on NVIM-v0.9 and higher
		"BufWinEnter",
		"CursorHold",
		"InsertLeave",

		-- include this if you have set `show_modified` to `true`
		"BufModifiedSet",
	}, {
		group = vim.api.nvim_create_augroup("barbecue.updater", {}),
		callback = function()
			require("barbecue.ui").update()
		end,
	})
end

-- [[ Configure Bqf ]]
require("bqf")


