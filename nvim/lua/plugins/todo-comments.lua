return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        -- TODO: 待做
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    config = function()
        require("todo-comments").setup({
            keywords = {
                REVIEW = {
                    icon = "👀",
                    color = "warning",
                },
                DONE = {
                    icon = "✅",
                    color = "hint",
                    alt = { "COMPLETED", "FINISHED", "RESOLVED" },
                },
                QUESTION = {
                    icon = "?",
                    color = "info",
                },
            },
            highlight = {
                comments_only = false,
            },
        })
    end,
}
