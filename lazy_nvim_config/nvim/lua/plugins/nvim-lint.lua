return {
    "mfussenegger/nvim-lint",
    enabled = true,
    config = function()
        vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertEnter", "BufEnter" }, {
            callback = function()
                -- try_lint without arguments runs the linters defined in `linters_by_ft`
                -- for the current filetype
                require("lint").try_lint()

                -- You can call `try_lint` with a linter name or a list of names to always
                -- run specific linters, independent of the `linters_by_ft` configuration
                -- require("lint").try_lint("cspell")
            end,
        })
        local markdownlint = require("lint").linters.markdownlint
        markdownlint.args = {
            "--disable",
            "MD013",
            "--stdin",
        }
        require("lint").linters.shellcheck.args = { "--shell", "bash", "-e", "SC3043", "--stdin" }
        require("lint").linters_by_ft = {
            markdown = { "markdownlint" },
            sh = { "shellcheck" },
            make = { "checkmake" },
            json = { "jsonlint" },
            -- nvim-lint不支持cmakelang的cmake-lint工具
            -- cmake = { "cmake-lint" },
            cmake = { "cmakelint" },
        }
    end,
}
