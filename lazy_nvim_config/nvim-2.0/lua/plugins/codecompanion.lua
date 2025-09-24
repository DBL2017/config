local kimi_prompt = [[
你是一个名为CodeCompanion的长文本总结助手，工作在Neovim文本编辑器中，能够总结用户给出的文本，并生成摘要。你可以执行以下任务：
1. 仔细阅读提供的文章内容
2. 阅读文章内容后给文章打上标签，标签通常是领域、学科或专有名词，但不超过5个
3. 一句话总结文章内容并写成摘要，但不超过120字

请严格按照用户的要求执行任务。
使用用户提供的上下文和附件。
保持回答简短且客观，特别是当用户上下文超出你的核心任务范围时。
所有文本回答必须使用 Chinese 语言编写。
在回答中使用Markdown格式，且不要使用H1和H2标题。

附加上下文：
当前日期是%s
当前用户的neovim版本是%s
用户正在使用%s系统的机器上工作。如果适用，请使用系统特定的命令进行响应。
]]
local default_prompt = [[
你是一个名为"CodeCompanion"的AI编程助手，工作在Neovim文本编辑器中。你可以回答一般的编程问题并执行以下任务：
1. 回答一般的编程问题
2. 解释Neovim缓冲区中代码的工作原理
3. 审查Neovim缓冲区中选定的代码
4. 为选定的代码生成单元测试
5. 为代码中的问题提出修复方案
6. 为新工作区搭建代码框架
7. 查找与用户查询相关的代码
8. 为测试失败提出修复方案
9. 回答关于Neovim的问题

请严格按照用户的要求执行任务。
使用用户提供的上下文和附件。
保持回答简短且客观，特别是当用户上下文超出你的核心任务范围时。
所有非代码文本回答必须使用 Chinese 语言编写。
在回答中使用Markdown格式。
不要使用H1或H2标题。
当建议代码修改或新内容时，使用Markdown代码块。
要开始一个代码块，使用4个反引号。
在反引号后添加编程语言名称作为语言ID。
要结束一个代码块，在新行上使用4个反引号。
如果代码修改了现有文件或应放置在特定位置，添加带有'filepath:'和文件路径的行注释。
如果希望用户决定放置位置，则不添加文件路径注释。
在代码块中，使用'...existing code...'行注释来指示文件中已存在的代码。

代码块示例：

// filepath: /path/to/file
// ...existing code...
{ changed code }
// ...existing code...
{ changed code }
// ...existing code...


确保行注释使用正确的编程语言语法（例如Python用"#"、Lua用"--"）。
对于代码块，使用4个反引号开始和结束。
避免将整个回答用三重反引号包裹。
除非明确要求，否则不包含差异格式。
不要在代码块中包含行号。

当给定任务时：

1. 逐步思考，除非用户要求或任务非常简单，否则用伪代码描述计划
2. 输出代码块时，确保只包含相关代码，避免重复或不相关的代码
3. 以简短的建议结束回答，直接支持继续对话

附加上下文：
当前日期是%s
用户的Neovim版本是%s
用户正在使用%s系统的机器上工作。如果适用，请使用系统特定的命令进行响应。
]]

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
                        is_slash_cmd = true,
                        modes = { "v" },
                        short_name = "explain_in_chinese",
                        auto_submit = false,
                        user_prompt = false,
                        stop_context_insertion = true,
                        ignore_system_prompt = true,
                        -- adapter = {
                        --     name = "siliconflow_r1",
                        --     model = "deepseek-ai/DeepSeek-R1",
                        -- },
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                local machine = vim.uv.os_uname().sysname
                                if machine == "Darwin" then
                                    machine = "Mac"
                                end
                                if machine:find("Windows") then
                                    machine = "Windows"
                                end
                                -- 为每种不同的ai工具生成对应的系统提示词
                                return string.format(
                                    default_prompt,
                                    os.date("%B %d, %Y"),
                                    vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
                                    machine
                                )
                            end,
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
                                    [[请解释buffer %d 中的这段代码:<prompt>
```%s
%s
```
</prompt>
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
                ["Generate digest"] = {
                    strategy = "chat",
                    description = "对当前Buffer内容生成摘要",
                    opts = {
                        modes = { "n", "v" },
                        short_name = "generate_digest",
                        auto_submit = true,
                        user_prompt = false,
                        stop_context_insertion = true,
                        is_slash_cmd = true,
                        -- Do not send default system prompt
                        ignore_system_prompt = true,
                        -- To customize the chat buffer UI, you can set a custom intro message:
                        intro_message = "Welcome to generate digest!",
                        adapter = {
                            name = "kimi_openai_online",
                            model = "moonshot-v1-128k",
                        },
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                local machine = vim.uv.os_uname().sysname
                                if machine == "Darwin" then
                                    machine = "Mac"
                                end
                                if machine:find("Windows") then
                                    machine = "Windows"
                                end
                                return string.format(
                                    kimi_prompt,
                                    os.date("%B %d, %Y"),
                                    vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
                                    machine
                                )
                            end,
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
                                -- if #input <= 0 or input == nil then
                                local content = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false)
                                for i, line in ipairs(content) do
                                    input = input .. "\n" .. line
                                end
                                -- end

                                return string.format(
                                    [[请对buffer %d 中的内容生成摘要:<prompt>%s</prompt>]],
                                    context.bufnr,
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
                    provider = "fzf_lua", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
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
                        completion_provider = "blink", -- blink|cmp|coc|default
                        goto_file_action = "tabnew", -- this will always open the file in a new tab
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
                    adapter = "qwen2_coder_local",
                    keymaps = {
                        close = {
                            modes = { n = "<C-q>", i = "<C-q>" },
                            opts = { silent = true, desc = "Close chat" },
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
                        ---@param opts { adapter: CodeCompanion.HTTPAdapter, language: string }
                        ---@return string
                        system_prompt = function(opts)
                            local machine = vim.uv.os_uname().sysname
                            if machine == "Darwin" then
                                machine = "Mac"
                            end
                            if machine:find("Windows") then
                                machine = "Windows"
                            end
                            -- 为每种不同的ai工具生成对应的系统提示词
                            if opts.adapter == "kimi_openai_online" then
                                return string.format(
                                    kimi_prompt,
                                    os.date("%B %d, %Y"),
                                    vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
                                    machine
                                )
                            else
                                return string.format(
                                    default_prompt,
                                    os.date("%B %d, %Y"),
                                    vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
                                    machine
                                )
                            end
                        end,
                    },
                },
                inline = {
                    -- adapter = "siliconflow_r1",
                    adapter = "qwen2_coder_local",
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
                    adapter = "qwen2_coder_local",
                },
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
                        allow_insecure = true,
                    },
                    siliconflow_r1_deepseek_online = function()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_r1_deepseek_online",
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
                    qwen2_coder_local = function()
                        return require("codecompanion.adapters").extend("ollama", {
                            name = "qwen2_coder_local",
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
                    kimi_openai_online = function()
                        return require("codecompanion.adapters").extend("openai", {
                            name = "kimi_openai_online",
                            url = "https://api.moonshot.cn/v1/chat/completions",
                            env = {
                                api_key = function()
                                    return os.getenv("KIMI_API_KEY")
                                end,
                            },
                            headers = {
                                ["Content-Type"] = "application/json",
                                ["Authorization"] = "Bearer ${api_key}",
                            },
                            schema = {
                                model = {
                                    default = "moonshot-v1-128k",
                                    choices = {
                                        ["moonshot-v1-128k"] = { opts = { can_reason = true } },
                                    },
                                },
                            },
                        })
                    end,

                    qwen3_coder_plus_2025_online = function()
                        return require("codecompanion.adapters").extend("openai", {
                            name = "qwen3_coder_plus_2025_online",
                            url = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
                            env = {
                                api_key = function()
                                    return os.getenv("QWEN3_CODER_PLUS_2025")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "qwen3-coder-plus-2025-07-22",
                                    choices = {
                                        ["qwen3-coder-plus-2025-07-22"] = { opts = { can_reason = true } },
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
