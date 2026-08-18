return {
    "windwp/nvim-autopairs",
    event = { "TextChanged", "InsertEnter" },
    config = function()
        require("nvim-autopairs").setup({
            disable_filetype = { "TelescopePrompt", "vim" },
        })
    end,
}
