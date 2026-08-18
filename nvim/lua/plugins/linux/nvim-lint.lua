return {
    "mfussenegger/nvim-lint",
    ft = {
        "markdown",
        "sh",
        "make",
        "json",
        "cmake",
    },
    config = function()
        local lint = require("lint")

        lint.linters.markdownlint.args = {
            "--disable",
            "MD013",
            "--stdin",
        }

        lint.linters.shellcheck.args = {
            "--shell",
            "bash",
            "-e",
            "SC3043",
            "--stdin",
        }

        lint.linters_by_ft = {
            markdown = { "markdownlint" },
            sh = { "shellcheck" },
            make = { "checkmake" },
            json = { "jsonlint" },
            cmake = { "cmakelint" },
        }

        local group = vim.api.nvim_create_augroup("nvim_lint", { clear = true })

        vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave", "BufEnter" }, {
            group = group,
            callback = function(args)
                local ft = vim.bo[args.buf].filetype

                -- 只有配置了 linter 的文件类型才执行
                if lint.linters_by_ft[ft] then
                    lint.try_lint()
                end
            end,
        })
    end,
}
