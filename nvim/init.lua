#!/bin/lua

require("basic")

-- basic
require("plugins")
require("keymappings")
require("autocmds")
require("theme")

-- plugins
require("plugin-config.lualine")
require("plugin-config.nvim-treesitter")
require("plugin-config.nvim-tree")
require("plugin-config.Comment")
require("plugin-config.gitsigns")
require("plugin-config.telescope")
require("plugin-config.formatter")
require("plugin-config.trouble")
require("plugin-config.autopairs")
require("plugin-config.vimtex")
require("plugin-config.nvim-lint")
-- lsp
require("lsp.mason")
require("lsp.mason-lspconfig")
require("lsp.lspconfig")
require("lsp.nvim-cmp")
-- theme
require("theme.material")
-- require("plugin-config.bufferline")
