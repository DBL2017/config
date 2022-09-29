local installStatus = pcall(require, "formatter")

if installStatus then
    -- Utilities for creating configurations
    local util = require("formatter.util")

    -- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
    require("formatter").setup({
        -- Enable or disable logging
        logging = true,
        -- Set the log level
        log_level = vim.log.levels.INFO,

        -- All formatter configurations are opt-in
        filetype = {
            -- 将stylua可执行文件拷贝到/usr/bin下
            lua = {
                require("formatter.filetypes.lua").stylua,

                function()
                    if util.get_current_buffer_file_name() == "special.lua" then return nil end

                    return {
                        exe = "stylua",
                        --[[ FORMATTING OPTIONS:
                            --call-parentheses <CALL_PARENTHESES>
                                Specify whether to apply parentheses on function calls with single s
                    tring or table arg
                                [possible values: Always, NoSingleString, NoSingleTable, None]

                            --collapse-simple-statement <COLLAPSE_SIMPLE_STATEMENT>
                                Specify whether to collapse simple statements [possible values: Neve
                    r, FunctionOnly,
                                ConditionalOnly, Always]

                            --column-width <COLUMN_WIDTH>
                                The column width to use to attempt to wrap lines

                            --indent-type <INDENT_TYPE>
                                The type of indents to use [possible values: Tabs, Spaces]

                            --indent-width <INDENT_WIDTH>
                                The width of a single indentation level

                            --line-endings <LINE_ENDINGS>
                                The type of line endings to use [possible values: Unix, Windows]

                            --quote-style <QUOTE_STYLE>
                                The style of quotes to use in string literals [possible values: Auto
                    PreferDouble,
                                AutoPreferSingle, ForceDouble, ForceSingle] ]]
                        args = {
                            "--call-parentheses",
                            "Always",
                            "--collapse-simple-statement",
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
                        },
                        stdin = false,
                    }
                end,
            },
            -- 安装外部工具clang-format, sudo apt install clang-format
            c = {
                function()
                    return {
                        exe = "clang-format",
                        args = {
                            -- clang_format_option,
                            "--assume-filename=" .. vim.api.nvim_buf_get_name(0),
                        },
                        stdin = true,
                        cwd = vim.fn.expand("%:p:h"),
                    }
                end,
            },
            -- 需要安装外部json格式化工具，安装命令如下：
            -- sudo apt install jq
            json = {
                function()
                    return {
                        exe = "jq",
                        args = {
                            -- clang_format_option,
                            -- "--assume-filename=" .. vim.api.nvim_buf_get_name(0),
                        },
                        stdin = true,
                        cwd = vim.fn.expand("%:p:h"),
                    }
                end,
            },
            -- Use the special "*" filetype for defining formatter configurations on
            -- any filetype
            ["*"] = {
                -- "formatter.filetypes.any" defines default configurations for any
                -- filetype
                require("formatter.filetypes.any").remove_trailing_whitespace,
                function()
                    -- vim.notify(util.get_current_buffer_file_name())
                    -- 格式化C语言头文件
                    if util.get_current_buffer_file_name().find(util.get_current_buffer_file_name(), ".h") then
                        -- vim.notify(util.get_current_buffer_file_name())
                        return {
                            exe = "clang-format",
                            args = {
                                -- clang_format_option,
                                "--assume-filename=" .. vim.api.nvim_buf_get_name(0),
                            },
                            stdin = true,
                            cwd = vim.fn.expand("%:p:h"),
                        }
                    end
                end,
            },
        },
    })
else
    vim.notify("没有找到formatter")
    return
end
