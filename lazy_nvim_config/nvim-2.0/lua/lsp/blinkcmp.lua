return {
    "saghen/blink.cmp",
    enabled = not vim.g.vscode, -- 在vscode-neovim禁用
    -- enabled = false, -- 在vscode-neovim禁用
    dependencies = {
        "rafamadriz/friendly-snippets",
        "Kaiser-Yang/blink-cmp-avante",
        "Kaiser-Yang/blink-cmp-dictionary",
        dependencies = { "nvim-lua/plenary.nvim" },
    },
    version = "*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        cmdline = {
            keymap = {
                -- 选择并接受预选择的第一个
                -- ["<CR>"] = { "select_and_accept", "fallback" },
            },
            completion = {
                -- 不预选第一个项目，选中后自动插入该项目文本
                list = { selection = { preselect = false, auto_insert = false } },
                -- 自动显示补全窗口，仅在输入命令时显示菜单，而搜索或使用其他输入菜单时则不显示
                menu = {
                    auto_show = function(ctx)
                        return vim.fn.getcmdtype() == ":"
                        -- enable for inputs as well, with:
                        -- or vim.fn.getcmdtype() == '@'
                    end,
                },
                -- 不在当前行上显示所选项目的预览
                ghost_text = { enabled = false },
            },
        },
        keymap = {
            preset = "none",
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            -- fallback命令将运行下一个非闪烁键盘映射(回车键的默认换行等操作需要)
            ["<CR>"] = { "accept", "fallback" }, -- 更改成'select_and_accept'会选择第一项插入
            ["<C-q>"] = { "cancel" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" }, -- 同时存在补全列表和snippet时，补全列表选择优先级更高

            ["<C-b>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },

            ["<C-e>"] = { "snippet_forward", "select_next", "fallback" }, -- 同时存在补全列表和snippet时，snippet跳转优先级更高
            ["<C-u>"] = { "snippet_backward", "select_prev", "fallback" },
        },
        completion = {
            -- 示例：使用'prefix'对于'foo_|_bar'单词将匹配'foo_'(光标前面的部分),使用'full'将匹配'foo__bar'(整个单词)
            keyword = { range = "full" },
            -- 选择补全项目时显示文档(0秒延迟)
            documentation = { auto_show = true, auto_show_delay_ms = 0, window = { border = "rounded" } },
            -- 不预选第一个项目，选中后自动插入该项目文本
            list = { selection = { preselect = false, auto_insert = false } },
            -- 不在当前行上显示所选项目的预览
            ghost_text = { enabled = false },

            -- 针对菜单的外观配置
            menu = {
                min_width = 15,
                max_height = 15,
                border = "rounded", -- Defaults to `vim.o.winborder` on nvim 0.11+
                draw = {
                    -- Aligns the keyword you've typed to a component in the menu
                    align_to = "label", -- or 'none' to disable, or 'cursor' to align to the cursor
                    -- Left and right padding, optionally { left, right } for different padding on each side
                    padding = 1,
                    -- Gap between columns
                    gap = 2,
                    -- Priority of the cursorline highlight, setting this to 0 will render it below other highlights
                    cursorline_priority = 10000,
                    -- Appends an indicator to snippets label
                    snippet_indicator = "~",
                    -- Use treesitter to highlight the label text for the given list of sources
                    -- treesitter = {},
                    treesitter = { "lsp" },

                    -- Components to render, grouped by column
                    columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },

                    -- Definitions for possible components to render. Each defines:
                    --   ellipsis: whether to add an ellipsis when truncating the text
                    --   width: control the min, max and fill behavior of the component
                    --   text function: will be called for each item
                    --   highlight function: will be called only when the line appears on screen
                    components = {
                        kind_icon = {
                            ellipsis = false,
                            text = function(ctx)
                                local kind_icons = {
                                    Text = "󰉿",
                                    Method = "󰆧",
                                    Function = "󰊕",
                                    Constructor = "",
                                    Field = "󰜢",
                                    Variable = "󰀫",
                                    Class = "󰠱",
                                    Interface = "",
                                    Module = "",
                                    Property = "󰜢",
                                    Unit = "󰑭",
                                    Value = "󰎠",
                                    Enum = "",
                                    Keyword = "󰌋",
                                    Snippet = "",
                                    Color = "󰏘",
                                    File = "󰈙",
                                    Reference = "󰈇",
                                    Folder = "󰉋",
                                    EnumMember = "",
                                    Constant = "󰏿",
                                    Struct = "󰙅",
                                    Event = "",
                                    Operator = "󰆕",
                                    TypeParameter = " ",
                                }
                                return kind_icons[ctx.kind] .. ctx.icon_gap

                                -- return ctx.kind_icon .. ctx.icon_gap
                            end,
                            -- Set the highlight priority to 20000 to beat the cursorline's default priority of 10000
                            highlight = function(ctx)
                                return { { group = ctx.kind_hl, priority = 20000 } }
                            end,
                        },

                        kind = {
                            ellipsis = false,
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.kind
                            end,
                            highlight = function(ctx)
                                return ctx.kind_hl
                            end,
                        },

                        label = {
                            width = { fill = true, max = 60 },
                            text = function(ctx)
                                return ctx.label .. ctx.label_detail
                            end,
                            highlight = function(ctx)
                                -- label and label details
                                local highlights = {
                                    {
                                        0,
                                        #ctx.label,
                                        group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
                                    },
                                }
                                if ctx.label_detail then
                                    table.insert(
                                        highlights,
                                        { #ctx.label, #ctx.label + #ctx.label_detail, group = "BlinkCmpLabelDetail" }
                                    )
                                end

                                -- characters matched on the label by the fuzzy matcher
                                for _, idx in ipairs(ctx.label_matched_indices) do
                                    table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                                end

                                return highlights
                            end,
                        },
                        label_description = {
                            width = { max = 30 },
                            text = function(ctx)
                                return ctx.label_description
                            end,
                            highlight = "BlinkCmpLabelDescription",
                        },

                        source_name = {
                            width = { max = 30 },
                            text = function(ctx)
                                return "[" .. ctx.source_name .. "]"
                            end,
                            highlight = "BlinkCmpSource",
                        },

                        source_id = {
                            width = { max = 30 },
                            text = function(ctx)
                                return ctx.source_id
                            end,
                            highlight = "BlinkCmpSource",
                        },
                    },
                },
            },
        },
        -- 指定文件类型启用/禁用
        enabled = function()
            return not vim.tbl_contains({
                -- "lua",
                -- "markdown"
            }, vim.bo.filetype) and vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
        end,

        appearance = {
            -- 将后备高亮组设置为 nvim-cmp 的高亮组
            -- 当您的主题不支持blink.cmp 时很有用
            -- 将在未来版本中删除
            use_nvim_cmp_as_default = true,
            -- 将“Nerd Font Mono”设置为“mono”，将“Nerd Font”设置为“normal”
            -- 调整间距以确保图标对齐
            nerd_font_variant = "mono",
        },

        -- 已定义启用的提供程序的默认列表，以便您可以扩展它
        sources = {
            default = {
                "dictionary",
                "buffer",
                "lsp",
                "codecompanion",
                "path",
                "snippets",
                "avante",
            },
            providers = {
                -- score_offset设置优先级数字越大优先级越高
                lsp = {
                    name = "LSP",
                    module = "blink.cmp.sources.lsp",
                    opts = {}, -- Passed to the source directly, varies by source

                    --- NOTE: All of these options may be functions to get dynamic behavior
                    --- See the type definitions for more information
                    enabled = true, -- Whether or not to enable the provider
                    async = false, -- Whether we should show the completions before this provider returns, without waiting for it
                    timeout_ms = 2000, -- How long to wait for the provider to return before showing completions and treating it as asynchronous
                    transform_items = nil, -- Function to transform the items before they're returned
                    should_show_items = true, -- Whether or not to show the items
                    max_items = 10, -- Maximum number of items to display in the menu
                    min_keyword_length = 3, -- Minimum number of characters in the keyword to trigger the provider
                    -- If this provider returns 0 items, it will fallback to these providers.
                    -- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
                    fallbacks = {},
                    score_offset = 5, -- Boost/penalize the score of the items
                    override = nil, -- Override the source's functions
                },
                buffer = {
                    name = "BUF",
                    enabled = true,
                    max_items = 10, -- Maximum number of items to display in the menu
                    min_keyword_length = 3, -- Minimum number of characters in the keyword to trigger the provider
                    score_offset = 4,
                },
                -- codecompanion = {
                --     enabled = true,
                --     min_keyword_length = 3, -- Minimum number of characters in the keyword to trigger the provider
                --     score_offset = 4,
                -- },
                codecompanion = {
                    name = "CodeCompanion",
                    module = "codecompanion.providers.completion.blink",
                    enabled = true,
                    score_offset = 6,
                },

                path = { name = "PTH", score_offset = 3 },
                snippets = {
                    name = "SNP",
                    min_keyword_length = 3, -- Minimum number of characters in the keyword to trigger the provider
                    score_offset = 2,
                },
                cmdline = {
                    min_keyword_length = function(ctx)
                        -- when typing a command, only show when the keyword is 3 characters or longer
                        if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
                            return 3
                        end
                        return 0
                    end,
                },
                avante = {
                    module = "blink-cmp-avante",
                    name = "Avante",
                    opts = {
                        -- options for blink-cmp-avante
                    },
                },
                dictionary = {
                    enabled = false,
                    module = "blink-cmp-dictionary",
                    name = "Dict",
                    -- Make sure this is at least 2.
                    -- 3 is recommended
                    min_keyword_length = 3,
                    score_offset = 10,
                    opts = {
                        -- Specify the dictionary files' path
                        -- example: { vim.fn.expand('~/.config/nvim/dictionary/words.dict') }
                        -- dictionary_files = { vim.fn.expand("~/.config/nvim/dict/stardict-ecdict-2.4.2.dict") },
                        -- All .txt files in these directories will be treated as dictionary files
                        -- example: { vim.fn.expand('~/.config/nvim/dictionary') }
                        -- dictionary_directories = vim.fn.expand("~/.config/nvim/dict"),
                    },
                },
            },
        },
    },
    -- 由于“opts_extend”，您的配置中的其他位置无需重新定义它
    opts_extend = { "sources.default" },
}
