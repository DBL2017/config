return -- lazy.nvim
{
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        -- Other package managers
        require("codecompanion").setup({
            prompt_library = {
                ["Explain in chinese"] = {
                    strategy = "chat",
                    description = "中文解释代码",
                    opts = {
                        is_slash_cmd = false,
                        modes = { "v" },
                        short_name = "explain_in_chinese",
                        auto_submit = true,
                        user_prompt = false,
                        stop_context_insertion = true,
                        -- adapter = {
                        --     name = "siliconflow_r1",
                        --     model = "deepseek-ai/DeepSeek-R1",
                        -- },
                    },
                    prompts = {
                        {
                            role = "system",
                            content = [[当被要求解释代码时，请遵循以下步骤：
1. 识别编程语言。
2. 描述代码的目的，并引用该编程语言的核心概念。
3. 解释每个函数或重要的代码块，包括参数和返回值。
4. 突出说明使用的任何特定函数或方法及其作用。
5. 如果适用，提供该代码如何融入更大应用程序的上下文。
]],
                            opts = {
                                visible = false,
                            },
                        },
                        {
                            role = "user",
                            content = function(context)
                                local input = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )

                                return string.format(
[[请解释 buffer %d 中的这段代码:
```%s
%s
```
]],
                                    context.bufnr,
                                    context.filetype,
                                    input
                                )
                            end,
                            opts = {
                                contains_code = true,
                            },
                        },
                    },
                },
            },
            display = {
                action_palette = {
                    width = 100,
                    height = 0.45,
                    prompt = "Prompt ", -- Prompt used for interactive LLM calls
                    -- provider = "default", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
                    opts = {
                        show_default_actions = true, -- Show the default actions in the action palette?
                        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                        title = "CodeCompanion actions", -- The title of the action palette
                    },
                },
                -- Inline display configuration options:
                --   layout: (string) The layout for the inline display. Available options: "vertical", "horizontal", "buffer".
                inline = {
                    layout = "vertical", -- vertical|horizontal|buffer
                },
                chat = {
                    auto_scroll = true,
                    opts = {
                        completion_provider = "cmp", -- blink|cmp|coc|default
                    },
                    -- Change the default icons
                    icons = {
                        buffer_pin = " ",
                        buffer_watch = "👀 ",
                    },

                    -- Alter the sizing of the debug window
                    debug_window = {
                        ---@return number|fun(): number
                        width = vim.o.columns - 5,
                        ---@return number|fun(): number
                        height = vim.o.lines - 2,
                    },

                    -- Options to customize the UI of the chat buffer
                    window = {
                        layout = "horizontal", -- float|vertical|horizontal|buffer
                        position = "bottom", -- left|right|top|bottom (nil will default depending on vim.opt.splitright|vim.opt.splitbelow)
                        border = "single",
                        height = 0.45,
                        width = 0.4,
                        relative = "editor",
                        full_height = true, -- when set to false, vsplit will be used to open the chat buffer vs. botright/topleft vsplit
                        sticky = false, -- when set to true and `layout` is not `"buffer"`, the chat buffer will remain opened when switching tabs
                        opts = {
                            breakindent = true,
                            cursorcolumn = false,
                            cursorline = false,
                            foldcolumn = "0",
                            linebreak = true,
                            list = false,
                            numberwidth = 1,
                            signcolumn = "no",
                            spell = false,
                            wrap = true,
                        },
                    },

                    ---Customize how tokens are displayed
                    ---@param tokens number
                    ---@param adapter CodeCompanion.Adapter
                    ---@return string
                    token_count = function(tokens, adapter)
                        return " (" .. tokens .. " tokens)"
                    end,
                },
            },
            strategies = {
                chat = {
                    -- adapter = "siliconflow_r1",
                    adapter = "qwen2_coder",
                    keymaps = {
                        close = {
                            modes = { n = "<C-q>", i = "<C-q>" },
                            opts = {},
                        },
                    },
                    variables = {
                        ["buffer"] = {
                            opts = {
                                default_params = "pin", -- or 'watch'
                            },
                        },
                    },
                    slash_commands = {
                        ["file"] = {
                            -- Location to the slash command in CodeCompanion
                            callback = "strategies.chat.slash_commands.file",
                            description = "Select a file using Telescope",
                            opts = {
                                provider = "telescope", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks"
                                contains_code = true,
                            },
                        },
                    },
                    opts = {
                        ---Decorate the user message before it's sent to the LLM
                        ---@param message string
                        ---@param adapter CodeCompanion.Adapter
                        ---@param context table
                        ---@return string
                        prompt_decorator = function(message, adapter, context)
                            return string.format([[<prompt>%s</prompt>]], message)
                        end,
                    },
                },
                inline = {
                    -- adapter = "siliconflow_r1",
                    adapter = "qwen2_coder",
                    keymaps = {
                        accept_change = {
                            modes = { n = "ga" },
                            description = "Accept the suggested change",
                        },
                        reject_change = {
                            modes = { n = "gr" },
                            opts = { nowait = true },
                            description = "Reject the suggested change",
                        },
                    },
                },
                agent = {
                    --adapter = "siliconflow_r1"
                    adapter = "qwen2_coder",
                },
            },
            opts = {
                log_level = "TRACE", -- or "TRACE"
                language = "Chinese",
            },
            adapters = {
                acp = {
                    opts = {
                        show_defaults = false,
                    },
                    -- Define your custom adapters here
                },
                http = {
                    opts = {
                        show_defaults = false,
                        allow_insecure = true,
                    },
                    siliconflow_r1 = function()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_r1",
                            url = "https://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-ai/DeepSeek-R1",
                                    choices = {
                                        ["deepseek-ai/DeepSeek-R1"] = { opts = { can_reason = false } },
                                        ["deepseek-ai/DeepSeek-V3"] = { opts = { can_reason = false } },
                                    },
                                },
                            },
                        })
                    end,
                    qwen2_coder = function()
                        return require("codecompanion.adapters").extend("ollama", {
                            name = "qwen2.5-coder:0.5b",
                            url = "http://192.168.100.1:11434/api/chat", -- 本地服务地址
                            env = {
                                api_key = function()
                                    return nil
                                end, -- 本地模型通常不需要 API key
                            },
                            headers = {
                                ["Content-Type"] = "application/json",
                            },
                            parameters = {
                                sync = true,
                            },
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = true,
                            },
                            schema = {
                                model = {
                                    default = "qwen2.5-coder:0.5b", -- 模型名称需与服务端一致
                                    choices = {
                                        ["qwen2.5-coder:0.5b"] = {
                                            opts = {
                                                can_reason = true, -- 支持推理任务
                                                -- max_tokens = 4096, -- 最大 token 数
                                            },
                                        },
                                    },
                                },
                                num_ctx = {
                                    default = 16384,
                                },
                                think = {
                                    default = false,
                                },
                                keep_alive = {
                                    default = "5m",
                                },
                            },
                        })
                    end,

                    -- aliyun_deepseek = function()
                    --     return require("codecompanion.adapters").extend("deepseek", {
                    --         name = "aliyun_deepseek",
                    --         url = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
                    --         env = {
                    --             api_key = function()
                    --                 return os.getenv("DEEPSEEK_API_ALIYUN")
                    --             end,
                    --         },
                    --         schema = {
                    --             model = {
                    --                 default = "deepseek-r1",
                    --                 choices = {
                    --                     ["deepseek-r1"] = { opts = { can_reason = true } },
                    --                 },
                    --             },
                    --         },
                    --     })
                    -- end,
                },
            },
        })
    end,
}
