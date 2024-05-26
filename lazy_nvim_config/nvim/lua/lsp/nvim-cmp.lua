-- 该插件为代码补全工具，补全数据来源有LSP，BUFFER，CMDLine等
return {
	"hrsh7th/nvim-cmp",
	dependencies = {
		"lukas-reineke/cmp-under-comparator",

		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		-- Buffer / Vim-builtin functionality
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-omni",

		-- Filesystem paths
		"hrsh7th/cmp-path",
		-- Command line
		"hrsh7th/cmp-cmdline",
		-- Markdown emojis
		"hrsh7th/cmp-emoji",
		-- Neovim's Lua API
		"hrsh7th/cmp-nvim-lua",
		-- latex
		"amarakon/nvim-cmp-lua-latex-symbols",
	},
	event = "InsertEnter",
	pin = true, -- 锁定插件，不会被更新
	config = function()
		local cmp = require("cmp")
		local cmp_under_comparator = require("cmp-under-comparator")
		local luasnip = require("luasnip")
		local cmp_buffer = require("cmp_buffer")

		local kind_icons = {
			Text = "",
			Method = "",
			Function = "",
			Constructor = "",
			Field = "ﰠ",
			Variable = "",
			Class = "ﴯ",
			Interface = "",
			Module = "",
			Property = "ﰠ",
			Unit = "塞",
			Value = "",
			Enum = "",
			Keyword = "",
			Snippet = "",
			Color = "",
			File = "",
			Reference = "",
			Folder = "",
			EnumMember = "",
			Constant = "",
			Struct = "פּ",
			Event = "",
			Operator = "",
			TypeParameter = "",
		}

		cmp.setup({

			-- 指定 snippet 引擎
			snippet = {
				expand = function(args)
					-- For `luasnip` users.
					luasnip.lsp_expand(args.body)
				end,
			},
			formatting = {
				fields = { "kind", "abbr", "menu" },
				format = function(entry, vim_item)
					-- print(vim.inspect(vim_item, { newline = "", indent = "" }))
					-- Kind icons
					---- This concatenates the icons with the name of the item kind
					vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
					-- vim_item.kind = kind_icons[vim_item.kind]
					-- vim_item.abbr = global.trim(vim_item.abbr)
					-- print(entry.source.name)
					if entry.source.name == "nvim_lsp" then
						vim_item.abbr = " •" .. vim_item.abbr
					else
						vim_item.abbr = " " .. vim_item.abbr
					end
					-- Source
					vim_item.menu = ({
						nvim_lsp = "[LSP]",
						buffer = "[BUF]",
						npm = "[NPM]",
						ultisnips = "[SNI]",
						latex_symbols = "[LTX]",
						path = "[PTH]",
						look = "[LOK]",
						nerdfont = "[NDF]",
						emoji = "[EMJ]",
						nvim_lua = "[NML]",
					})[entry.source.name] or "[OTH]"

					-- print(vim.inspect(entry.source.name, { newline = "", indent = "" }))
					return vim_item
				end,
			},
			completion = {
				-- autocomplete = false,
				keyword_length = 2,
			},
			-- 提示窗口配置
			window = {
				-- completion = cmp.config.window.bordered(),
				-- documentation = cmp.config.window.bordered(),
				completion = {
					-- border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
					border = "rounded",
					winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
					col_offset = 0,
					side_padding = 1,
				},
				documentation = {
					-- border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
					border = "rounded",
					winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
				},
			},
			-- 快捷键
			mapping = cmp.mapping.preset.insert({
				["<C-d>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-q>"] = cmp.mapping.close(),
				["<C-Space>"] = cmp.mapping.complete(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Tab>"] = function(fallback)
					if cmp.visible() then
						cmp.select_next_item({ behavior = cmp.SelectBehavior })
					else
						fallback()
					end
				end,
				["<S-Tab>"] = function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end,
			}),
			-- 候选排序
			sorting = {
				comparators = {
					-- -- The rest of your comparators...
					cmp.config.compare.offset,
					cmp.config.compare.exact,
					cmp.config.compare.score,
					cmp_under_comparator.under,
					function(...)
						cmp_buffer:compare_locality(...)
					end,
					cmp.config.compare.kind,
					cmp.config.compare.sort_text,
					cmp.config.compare.length,
					cmp.config.compare.order,
				},
			},
			-- 来源
			sources = cmp.config.sources({
				-- lsp的数据源
				{ name = "nvim_lsp" },
				-- For luasnip users.
				{ name = "luasnip" },

				{
					name = "buffer",
				},
				-- nvim-cmp source for omnifunc.
				{ name = "omni" },
			}, {
				--nvim-cmp source for filesystem paths.
				{
					name = "path",
					option = {
						-- 选中目录后是否追加/
						trailing_slash = true,
						label_trailing_slash = true,
					},
				},
			}),
		})

		-- Use buffer source for `/`.
		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				-- The purpose is the demonstration customize / search by nvim-cmp.
				{ name = "nvim_lsp_document_symbol" },
			}, {
				{ name = "buffer" },
			}),
		})
		-- Use cmdline & path source for ':'.
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				-- nvim-cmp source for vim's cmdline.
				{ name = "cmdline" },
			}),
		})
		-- Only enable `nvim_lua` for nvim_lua
		cmp.setup.filetype({ "lua", "Lua" }, {
			sources = {
				-- lsp的数据源
				{ name = "nvim_lsp" },
				-- For luasnip users.
				{ name = "luasnip" },
				-- nvim-cmp source for neovim Lua API.
				{ name = "nvim_lua" },
			},
		})

		-- Only enable `buffer-lines` for C and C++
		cmp.setup.filetype({ "c", "cpp" }, {
			sources = {
				-- lsp的数据源
				{ name = "nvim_lsp" },
				-- For luasnip users.
				{ name = "luasnip" },
				{
					name = "buffer",
					option = {
						keyword_pattern = [[\k\+]],
						get_bufnrs = function()
							local bufs = {}
							for _, win in ipairs(vim.api.nvim_list_wins()) do
								bufs[vim.api.nvim_win_get_buf(win)] = true
							end
							return vim.tbl_keys(bufs)
						end,
					},
				},

				-- nvim-cmp source for omnifunc.
				{ name = "omni" },
			},
		})
		cmp.setup.filetype({ "markdown", "latex" }, {
			sources = {
				-- lsp的数据源
				{ name = "nvim_lsp" },
				-- For luasnip users.
				{ name = "luasnip" },

				{
					name = "buffer",
				},

				-- nvim-cmp source for omnifunc.
				{ name = "omni" },

				-- nvim-cmp source for emojis.
				{ name = "emoji" },

				-- nvim-cmp source for nerdfont icons.
				{ name = "nerdfont" },

				-- Add latex symbol support for nvim-cmp.
				{ name = "lua-latex-symbols", option = { cache = true } },
			},
			{
				--nvim-cmp source for filesystem paths.
				{
					name = "path",
					option = {
						-- 选中目录后是否追加/
						trailing_slash = true,
						label_trailing_slash = true,
					},
				},
			},
		})
	end,
}
