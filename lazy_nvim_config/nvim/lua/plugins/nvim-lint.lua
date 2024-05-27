return {
    "mfussenegger/nvim-lint",
    enabled = true,
    config = function()
        require('lint').linters_by_ft = {
            markdown = { "markdownlint" }
        }
    end
}
