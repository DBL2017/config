return {
    "stevearc/conform.nvim",
    lazy = false,
    config = function()
        require("conform").setup({
            -- Map of filetype to formatters
            formatters_by_ft = {
                lua = function(bufnr)
                    if require("conform").get_formatter_info("stylua", bufnr).available then
                        return { "custom_stylua" }
                    end
                    return {}
                end,
                c = function(bufnr)
                    if require("conform").get_formatter_info("clang-format", bufnr).available then
                        return { "custom_cpp" }
                    end
                    return {}
                end,
                cpp = function(bufnr)
                    if require("conform").get_formatter_info("clang-format", bufnr).available then
                        return { "custom_cpp" }
                    end
                    return {}
                end,
                -- Conform will run multiple formatters sequentially
                -- go = { "goimports", "gofmt" },
                -- Use a sub-list to run only the first available formatter
                javascript = { "prettierd", "prettier" },
                html = { "prettierd", "prettier" },
                -- You can use a function here to determine the formatters dynamically
                python = function(bufnr)
                    return { "black" }
                end,
                sh = function(bufnr)
                    if require("conform").get_formatter_info("beautysh", bufnr).available then
                        return { "custom_sh" }
                    end
                    -- return { "beautysh" }
                    -- if require("conform").get_formatter_info("shfmt", bufnr).available then
                    -- 	return { "shfmt" }
                    -- else
                    -- 	return { "beautysh" }
                    -- end
                    return {}
                end,
                json = function(bufnr)
                    if require("conform").get_formatter_info("jq", bufnr).available then
                        return { "custom_json" }
                    end
                    return {}
                end,
                markdown = { "markdownlint" },
                tex = { "latexindent" },
                xml = function(bufnr)
                    if require("conform").get_formatter_info("xmlformat", bufnr).available then
                        return { "custom_xml" }
                    end
                    return {}
                end,
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
            timeout = 15000,
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
                    timeout = 5000,
                },
                custom_json = {
                    command = "jq",
                    args = {
                        -- "--indent",
                        -- "4",
                        "--tab",
                    },
                    stdin = true,
                },
                custom_sh = {
                    command = "beautysh",
                    args = {
                        "--indent-size",
                        "8",
                        "--tab",
                        "--force-function-style",
                        "paronly",
                        "-",
                    },
                    stdin = true,
                },
                custom_cpp = {
                    command = "clang-format",
                    args = function(self, ctx)
                        -- 动态构建参数
                        local args = { "--style=file" }

                        -- 如果有配置文件，使用它
                        local config_file = vim.fn.findfile(".clang-format", ".;")
                        if config_file ~= "" then
                            -- 使用项目中的配置文件
                            args = { "--style=file:" .. config_file }
                        else
                            -- 使用全局配置文件
                            local global_config = vim.fn.expand("~/.clang-format")
                            if vim.fn.filereadable(global_config) == 1 then
                                args = { "--style=file:" .. global_config }
                            end
                        end
                        -- 添加其他参数
                        table.insert(args, "--assume-filename=" .. ctx.filename)
                        table.insert(args, "--verbose")
                        return args
                    end,
                    stdin = true,
                },
                custom_xml = {
                    command = "xmlformat",
                    args = {
                        "--indent",
                        "4",
                        "-",
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
