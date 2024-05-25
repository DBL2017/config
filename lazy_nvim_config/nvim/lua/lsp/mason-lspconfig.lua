return {
	"williamboman/mason-lspconfig.nvim",
	config = function()
		-- 该插件用于安装lsp server
		require("mason-lspconfig").setup({
			-- 自动安装的server
			--
			ensure_installed = { "clangd" },
			-- 决定是否安装已经通过lspconfig setup过的server
			-- 取值如下：
			--   - false: Servers are not automatically installed.
			--   - true: All servers set up via lspconfig are automatically installed.
			--   - { exclude: string[] }: All servers set up via lspconfig, except the ones provided in the list, are automatically installed.
			--       Example: automatic_installation = { exclude = { "rust_analyzer", "solargraph" } }
			automatic_installation = true,
		})
	end

}
