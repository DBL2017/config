local platform = require("config.platform")

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    enabled = platform.has_compiler,
    config = function()
        local languages = {
            "c",
            "lua",
            "python",
            "bash",
            "make",
            "cmake",
            "cpp",
            "json",
            "query",
            "vim",
            "vimdoc",
            "markdown",
            "markdown_inline",
            "sql",
            "yaml",
            "html",
        }

        require("nvim-treesitter").setup()
        require("nvim-treesitter").install(languages)

        vim.api.nvim_create_autocmd("FileType", {
            pattern = languages,
            callback = function(args)
                vim.treesitter.start(args.buf)
            end,
        })
    end,
}
