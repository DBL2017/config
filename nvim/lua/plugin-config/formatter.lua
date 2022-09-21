-- Utilities for creating configurations
local util = require("formatter.util")

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup({
    -- Enable or disable logging
    logging = true,
    -- Set the log level
    log_level = vim.log.levels.DEBUG,
    -- All formatter configurations are opt-in
    filetype = {
        -- Formatter configurations for filetype "lua" go here
        -- and will be executed in order
        lua = {
            -- "formatter.filetypes.lua" defines default configurations for the
            -- "lua" filetype
            require("formatter.filetypes.lua").stylua,

            -- You can also define your own configuration
            function()
                -- Supports conditional formatting
                if util.get_current_buffer_file_name() == "special.lua" then return nil end

                -- Full specification of configurations is down below and in Vim help
                -- files
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
                        util.escape_path(util.get_current_buffer_file_path()),
                    },
                    stdin = true,
                }
            end,
        },
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
        -- Use the special "*" filetype for defining formatter configurations on
        -- any filetype
        ["*"] = {
            -- "formatter.filetypes.any" defines default configurations for any
            -- filetype
            require("formatter.filetypes.any").remove_trailing_whitespace,
        },
    },
})
