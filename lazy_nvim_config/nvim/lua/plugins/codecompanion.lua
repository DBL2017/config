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
            display = {
                -- Inline display configuration options:
                --   layout: (string) The layout for the inline display. Available options: "vertical", "horizontal", "buffer".
                inline = {
                    layout = "vertical", -- vertical|horizontal|buffer
                },
                chat = {
                    auto_scroll = false,
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
                        height = 0.4,
                        width = 0.45,
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
                    adapter = "siliconflow_r1",
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
                    adapter = "siliconflow_r1",
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
                agent = { adapter = "siliconflow_r1" },
            },
            opts = {
                log_level = "WARN", -- or "TRACE"
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
                                        "deepseek-ai/DeepSeek-V3",
                                    },
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
