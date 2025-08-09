return {
    "nvimdev/lspsaga.nvim",
    -- enabled = false,
    config = function()
        require("lspsaga").setup({
            outline = {
                close_after_jump = true,
                win_width = 40,
                detail = true,
                auto_preview = true,
            },
        })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- optional
        "nvim-tree/nvim-web-devicons", -- optional
    },
}
