--[[
 THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
 `lvim` is the global options object
]]
-- vim options
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.relativenumber = false
vim.opt.clipboard = "unnamedplus"

vim.g.vscode_style = "dark"
lvim.colorscheme = "vscode"

-- general
lvim.log.level = "info"
lvim.format_on_save = {
	enabled = true,
	pattern = "*",
	timeout = 10000,
}
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings <https://www.lunarvim.org/docs/configuration/keybindings>
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-n>"] = "<cmd>QNext<cr>"
lvim.keys.normal_mode["<C-p>"] = "<cmd>QPrev<cr>"
lvim.keys.normal_mode["<C-q>"] = "<cmd>QFToggle!<cr>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<leader>S"] = "<cmd>lua require('spectre').open()<CR>"

-- -- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["le"] = {
	"<cmd>lua vim.diagnostic.open_float()<CR>",
	"Line Diagnostics",
}
lvim.builtin.which_key.mappings["bp"] = {
	":echo expand('%:p')<CR>",
	"Echo file path",
}
-- lvim.builtin.which_key.mappings["W"] = { "<cmd>noautocmd w<cr>", "Save without formatting" }
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }

-- -- Change theme settings
-- lvim.colorscheme = "lunar"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.project.active = true
lvim.builtin.project.patterns = { "lerna.json", ".git" }
lvim.builtin.project.silent_chdir = false
lvim.builtin.nvimtree.setup.update_cwd = false
lvim.builtin.nvimtree.setup.update_focused_file.update_cwd = false
lvim.builtin.nvimtree.setup.actions.change_dir.enable = false
-- comment-string deprecation, remove after https://github.com/LunarVim/LunarVim/pull/4451 is merged
lvim.builtin.treesitter.context_commentstring = nil

lvim.builtin.telescope.defaults = {
	path_display = { "absolute" },
	layout_config = {
		width = 0.8,
	},
}

-- Automatically install missing parsers when entering buffer
lvim.builtin.treesitter.auto_install = true
lvim.builtin.treesitter.highlight.enabled = true
lvim.builtin.treesitter.incremental_selection = {
	enable = true,
	keymaps = {
		init_selection = "<CR>",
		scope_incremental = "<CR>",
		node_incremental = "<TAB>",
		node_decremental = "<S-TAB>",
	},
}
-- lvim.builtin.treesitter.ignore_install = { "haskell" }

-- -- always installed on startup, useful for parsers without a strict filetype
-- lvim.builtin.treesitter.ensure_installed = { "comment", "markdown_inline", "regex" }

-- -- generic LSP settings <https://www.lunarvim.org/docs/languages#lsp-support>

-- --- disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. IMPORTANT: Requires `:LvimCacheReset` to take effect
-- ---see the full default list `:lua =lvim.lsp.automatic_configuration.skipped_servers`
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "vuels" })

local lspconfig = require("lspconfig")
local opts = {
	root_dir = lspconfig.util.root_pattern("lerna.json", ".git"),
}
require("lvim.lsp.manager").setup("volar", opts)
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. IMPORTANT: Requires `:LvimCacheReset` to take effect
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
	return server ~= "ansiblels"
end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- linters and formatters <https://www.lunarvim.org/docs/languages#lintingformatting>
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{
		-- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
		command = "prettier",
		---@usage arguments to pass to the formatter
		-- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
		args = { "--config-precedence", "prefer-file" },
	},
	{ command = "eslint_d" },
	{ command = "stylua" },
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ command = "eslint_d" },
})

-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
lvim.plugins = {
	{
		"folke/trouble.nvim",
		cmd = "TroubleToggle",
	},
	{
		"ggandor/lightspeed.nvim",
		event = "BufRead",
	},
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"ray-x/lsp_signature.nvim",
		event = "BufRead",
		config = function()
			require("lsp_signature").setup()
		end,
	},
	{ "tpope/vim-repeat" },
	{
		"tpope/vim-surround",
		keys = { "c", "d", "y" },
	},
	{
		"stevearc/qf_helper.nvim",
		config = function()
			require("qf_helper").setup({
				quickfix = {
					track_location = false,
				},
				loclist = {
					track_location = false,
				},
			})
		end,
	},
	{
		"jose-elias-alvarez/nvim-lsp-ts-utils",
	},
	{
		"windwp/nvim-spectre",
		event = "BufRead",
		config = function()
			require("spectre").setup({
				mapping = {
					["send_to_qf"] = {
						map = "<leader>Q",
						cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
						desc = "send all item to quickfix",
					},
				},
			})
		end,
	},
	{
		"sindrets/diffview.nvim",
		event = "BufRead",
	},
	{
		"Mofiqul/vscode.nvim",
	},
	{
		"mfussenegger/nvim-ansible",
	},
	-- {
	-- 	"zbirenbaum/copilot-cmp",
	-- 	event = "InsertEnter",
	-- 	dependencies = { "zbirenbaum/copilot.lua" },
	-- 	config = function()
	-- 		vim.defer_fn(function()
	-- 			require("copilot").setup({
	-- 				suggestion = { enabled = false },
	-- 				panel = { enabled = false },
	-- 			}) -- https://github.com/zbirenbaum/copilot.lua/blob/master/README.md#setup-and-configuration
	-- 			require("copilot_cmp").setup() -- https://github.com/zbirenbaum/copilot-cmp/blob/master/README.md#configuration
	-- 		end, 100)
	-- 	end,
	-- },
}

-- -- Autocommands (`:help autocmd`) <https://neovim.io/doc/user/autocmd.html>
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
