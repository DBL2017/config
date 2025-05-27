return {
    "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            -- Map of filetype to formatters
            formatters_by_ft = {
                lua = { "custom_stylua" },

                c = { "clang-format" },

                -- Conform will run multiple formatters sequentially
                -- go = { "goimports", "gofmt" },
                -- Use a sub-list to run only the first available formatter
                javascript = { "prettierd", "prettier" },
                html = { "prettierd", "prettier" },
                sh = function()
                    return { "beautysh" }
                    -- if require("conform").get_formatter_info("shfmt", bufnr).available then
                    -- 	return { "shfmt" }
                    -- else
                    -- 	return { "beautysh" }
                    -- end
                end,
                tex = { "latexindent" },
                python = function()
                    return { "black" }
                    -- if require("conform").get_formatter_info("shfmt", bufnr).available then
                    -- 	return { "shfmt" }
                    -- else
                    -- 	return { "beautysh" }
                    -- end
                end,
                json = function(bufnr)
                    if require("conform").get_formatter_info("jq", bufnr).available then
                        return { "custom_json" }
                    end
                end,
                -- markdown = { "markdownlint" },
                -- Use the "*" filetype to run formatters on all filetypes.
                -- ["*"] = { "codespell" },
                -- Use the "_" filetype to run formatters on filetypes that don't
                -- have other formatters configured.
                ["_"] = { "trim_whitespace" },
            },
            -- format_on_save = {
            --     lsp_fallback = true,
            --     timeout_ms = 500,
            -- },
            -- -- If this is set, Conform will run the formatter asynchronously after save.
            -- -- It will pass the table to conform.format().
            -- -- This can also be a function that returns the table.
            -- format_after_save = {
            --     lsp_fallback = true,
            -- },
            -- Set the log level. Use `:ConformInfo` to see the location of the log file.
            log_level = vim.log.levels.DEBUG,
            -- Conform will notify you when a formatter errors
            notify_on_error = true,
            formatters = {
                custom_stylua = {
                    command = "stylua",
                    args = {
                        "--call-parentheses",
                        "Always",
                        "--column-width",
                        "120",
                        "--indent-type",
                        "Spaces",
                        "--indent-width",
                        "4",
                        "--line-endings",
                        "Unix",
                        "--quote-style",
                        "AutoPreferDouble",
                        "-",
                    },
                    stdin = true,
                },
                custom_json = {
                    command = "jq",
                    args = {
                        "--indent",
                        "4",
                    },
                    stdin = true,
                },
            },
        })
        -- 禁用自动格式化，采用手动触发
        -- vim.api.nvim_create_autocmd("BufWritePre", {
        --     pattern = "*",
        --     callback = function(args)
        --         require("conform").format({ bufnr = args.buf })
        --     end,
        -- })
        --
    end,
}
