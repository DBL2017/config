return {
    "nvimdev/lspsaga.nvim",
    -- enabled = false,
    event = "LspAttach",
    config = function()
        require("lspsaga").setup({
            outline = {
                close_after_jump = true,
                win_width = 40,
                detail = true,
                auto_preview = true,
            },
            symbol_in_winbar = {
                enable = false,
                separator = " -> ",
                hide_keyword = false,
                ignore_patterns = nil,
                show_file = true,
                folder_level = 1,
                color_mode = true,
                delay = 300,
            },
        })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- optional
        "nvim-tree/nvim-web-devicons", -- optional
    },
}
