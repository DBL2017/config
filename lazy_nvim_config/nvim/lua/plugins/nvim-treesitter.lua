return {

	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-tree/nvim-web-devicons"
	},
	config = function()
		require("nvim-treesitter.configs").setup({
			-- A list of parser names, or "all"
			-- ensure_installed = { "c", "lua", "python" },
			ensure_installed = { "c", "lua", "python", "bash", "make", "cmake", "cpp", "json", "markdown", "sql", "markdown_inline" },

			-- 是否同步安装,ensure_installed中列出的解析器
			sync_install = false,

			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
			auto_install = true,

			-- List of parsers to ignore installing (for "all")
			ignore_install = {},

			---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
			-- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

			-- 高亮
			highlight = {
				-- `false` will disable the whole extension
				enable = true,

				-- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
				-- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
				-- the name of the parser)
				-- list of language that will be disabled
				-- disable =  false,
				-- 当文件大于100KB时禁用高亮
				disable = function(lang, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,

				-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
				-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
				-- Using this option may slow down your editor, and you may see some duplicate highlights.
				-- Instead of true it can also be a list of languages
				additional_vim_regex_highlighting = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn",
					node_incremental = "grn",
					scope_incremental = "grc",
					node_decremental = "grm",
				},
			},
			indent = {
				enable = false,
			},
		})
		-- 开启 Folding
		vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
	end

}
