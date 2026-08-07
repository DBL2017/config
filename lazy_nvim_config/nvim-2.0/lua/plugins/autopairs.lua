return {
    "windwp/nvim-autopairs",
    event = { "BufWritePost", "TextChanged", "InsertEnter", "BufEnter" },
    config = function()
        require("nvim-autopairs").setup({
            disable_filetype = { "TelescopePrompt", "vim" },
        })
    end,
}
