return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim", -- required
        "sindrets/diffview.nvim", -- optional - Diff integration

        -- Only one of these is needed.
        "nvim-telescope/telescope.nvim", -- optional
        "ibhagwan/fzf-lua", -- optional
        "nvim-mini/mini.pick", -- optional
        "folke/snacks.nvim", -- optional
    },
    config = function()
        require("neogit").setup({
            -- 在新tab中查看特定提交信息
            commit_view = {
                kind = "tab",
                verify_commit = vim.fn.executable("gpg") == 1, -- Can be set to true or false, otherwise we try to find the binary
            },
        })
    end,
}
