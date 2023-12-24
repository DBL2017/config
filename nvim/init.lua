#!/bin/lua

require("basic")

-- basic
require("plugins")
require("keymappings")
require("autocmds")
require("diagnostic")

-- lsp
require("lsp.mason")
require("lsp.mason-lspconfig")
require("lsp.mason-tool-installer")
require("lsp.lspconfig")
-- plugins
require("plugin-config.lualine")
require("plugin-config.nvim-treesitter")
require("plugin-config.nvim-tree")
require("plugin-config.Comment")
require("plugin-config.gitsigns")
require("plugin-config.telescope")
require("plugin-config.symbols-outline")
require("plugin-config.toggleterm")
require("plugin-config.trouble")
require("plugin-config.autopairs")
require("plugin-config.vimtex")
require("plugin-config.nvim-lint")
require("plugin-config.null-ls")
require("plugin-config.conform")
require("plugin-config.autotag")
require("plugin-config.barbar")
-- cmp
require("lsp.nvim-cmp")
require("lsp.cmp.cmp-npm")
-- theme
require("theme.material")
-- require("theme.neon")
-- require("theme.tokyonight")
