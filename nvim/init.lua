#!/bin/lua

require("basic")

-- basic
require("plugins")
require("keymappings")
require("autocmds")
require("theme")
require("diagnostic")

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
-- cmp
require("lsp.nvim-cmp")
require("lsp.cmp.cmp-npm")
-- theme
require("theme.material")
-- require("plugin-config.bufferline")
