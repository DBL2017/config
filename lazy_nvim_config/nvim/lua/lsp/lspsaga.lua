return {
	"nvimdev/lspsaga.nvim",
	enabled = true,
	config = function()
		require("lspsaga").setup({
			outline = {
				close_after_jump = true,
				detail = true,
				win_width = 40,
			},
		})
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
}
