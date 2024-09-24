return {
    "folke/trouble.nvim",
    cmd = "Trouble",
    branch = "main",
    dependencies = {
        "nvim-tree/nvim-web-devicons"
    },
    config = function()
        require("trouble").setup({
            auto_jump = true, -- auto jump to the item when there's only one
            focus = true,     -- Focus the window when opened
        })
    end
}
