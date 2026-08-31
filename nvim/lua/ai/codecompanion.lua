-- 文件: lua/ai/codecompanion.lua
-- 说明: 为 codecompanion.nvim 插件提供 lazy.nvim 风格的配置项。
--       本文件包含适配器、界面(display)、交互(interactions)、扩展(extensions)
--       等配置，已以中文注释说明常用选项和可替换项。
--       在 Windows 平台上返回空配置以避免加载不兼容的插件或适配器。
local creds = require("config.credentials")
local platform = require("config.platform")

return -- lazy.nvim
{
    "DBL2017/codecompanion.nvim",
    -- module: 通过 module 字段指定按需加载的模块名。
    -- 作用: 当第一次 require('codecompanion') 时才加载该插件，避免在启动时立即下载/初始化大型 AI 插件。
    -- 取值范围: 字符串（插件导出的模块名）或 nil。
    -- 当前取值含义: "codecompanion" -> 插件会在调用 require('codecompanion') 时被加载，从而延迟启动开销。
    module = "codecompanion",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        --other plugins
        "ravitemer/codecompanion-history.nvim",
        "bahaaza/codecompanion-agentskills.nvim",
        "nvim-lualine/lualine.nvim",
    },
    cmd = {
        "CodeCompanion",
        "CodeCompanionChat",
        "CodeCompanionActions",
        "CodeCompanionHistory",
    },
    version = "^19.22.0",
    config = function()
        require("codecompanion").setup({
            prompt_library = {
                markdown = {
                    dirs = {
                        vim.fs.joinpath(vim.fn.getcwd(), ".prompts"),
                        vim.fs.joinpath(vim.fn.stdpath("config"), "prompts"),
                    },
                },
            },
            display = {
                action_palette = {
                    width = 100,
                    height = 0.45,
                    prompt = "Prompt ", -- Prompt used for interactive LLM calls
                    provider = "telescope", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
                    opts = {
                        show_default_actions = true, -- Show the default actions in the action palette?
                        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                        show_preset_prompts = false, -- 不显示预设的prompt
                        title = "CodeCompanion actions", -- The title of the action palette
                    },
                },
                -- Inline display configuration options:
                --   layout: (string) The layout for the inline display. Available options: "vertical", "horizontal", "buffer".
                inline = {
                    layout = "vertical", -- vertical|horizontal|buffer
                },
                chat = {
                    -- 自动滚动
                    auto_scroll = false, -- 默认会自动滚动到最后，设置为 false 可避免长回复时界面跳动

                    -- 补全引擎
                    completion_provider = "blink", -- 可选 blink|cmp|coc|default，决定使用哪种补全插件

                    -- 上下文折叠
                    icons = {
                        -- 折叠上下文时显示的图标
                        -- 当前效果：使用 "📎️" 作为折叠标识
                        -- 可选取值：任意字符串或图标
                        chat_context = "📎️",

                        -- 折叠 reasoning 时显示的图标
                        -- 当前效果：使用 " " 作为折叠标识
                        -- 可选取值：任意字符串或图标
                        chat_fold = " ",
                    },

                    -- 是否折叠上下文
                    -- 当前效果：true → 上下文会被折叠，只显示图标，不展开完整内容
                    -- 可选取值：true（折叠）、false（不折叠）
                    fold_context = true,

                    -- 是否折叠 reasoning 输出
                    -- 当前效果：true → 折叠，不完整显示 reasoning 内容
                    -- 可选取值：true（折叠）、false（不折叠）
                    fold_reasoning = true,

                    -- 是否显示 reasoning 输出
                    -- 当前效果：在办公环境显示，非办公环境不显示
                    -- 可选取值：true（显示）、false（隐藏）
                    show_reasoning = platform.is_office,

                    -- 布局
                    window = {
                        -- 是否在 buffer 列表中显示 Chat Buffer
                        -- 当前效果：会出现在 :ls 或 buffer 切换列表中
                        -- 可选取值：true（显示）、false（隐藏）
                        buflisted = true,

                        -- 切换 tab 时 Chat Buffer 是否保持打开，只有当pertab为false时有用
                        -- 当前效果：切换 tab 时 Chat Buffer 不会跟随
                        -- 可选取值：true（跟随）、false（不跟随）
                        sticky = false,

                        -- 是否为每个 tab 单独维护一个 Chat Buffer
                        -- 当前效果：每个 tab 都有用一个 Chat Buffer
                        -- 可选取值：true（每个 tab 独立）、false（共用）
                        pertab = true,

                        -- Chat Buffer 的布局方式
                        -- 当前效果：竖直分屏显示在右侧
                        -- 可选取值：float（浮动窗口）、vertical（竖直分屏）、horizontal（水平分屏）、tab（新 tab）、buffer（普通 buffer）
                        layout = "vertical",

                        -- 在竖直分屏布局下是否占满整个高度
                        -- 当前效果：Chat Buffer 占满编辑器高度
                        -- 可选取值：true（占满）、false（只占部分高度）
                        full_height = true,

                        -- Chat Buffer 的位置
                        -- 当前效果：固定在右侧分屏
                        -- 可选取值：left、right、top、bottom、nil（根据 splitright/splitbelow 自动决定）
                        position = "right",

                        -- Chat Buffer 的宽度比例
                        -- 当前效果：占编辑器宽度的 50%
                        -- 可选取值：0–1 的浮点数（比例），或函数动态计算
                        width = platform.is_office and 0.4 or 0.5,

                        -- Chat Buffer 的高度比例
                        -- 当前效果：占编辑器高度的 80%（竖直分屏时可忽略）
                        -- 可选取值：0–1 的浮点数（比例），或函数动态计算
                        height = 0.8,

                        -- 窗口边框样式
                        -- 当前效果：圆角边框，美观柔和
                        -- 可选取值：single、double、rounded、shadow
                        border = "rounded",

                        -- 窗口定位方式
                        -- 当前效果：相对于整个编辑器定位
                        -- 可选取值：editor（相对编辑器）、win（相对某个窗口）
                        relative = "editor",

                        opts = {
                            -- 保持缩进换行
                            breakindent = true,

                            -- 在单词边界换行
                            linebreak = true,

                            -- 长段落自动换行，避免横向滚动
                            wrap = true,

                            -- 不高亮当前行，避免干扰
                            cursorline = false,

                            -- 不显示标记列
                            signcolumn = "no",
                        },
                    },

                    roles = {
                        -- LLM 消息的标题名称
                        -- 当前效果：显示为 "CodeCompanion (适配器名称)"
                        -- 可选取值：字符串，或函数返回字符串
                        -- 如果是函数，第一个参数始终是当前适配器
                        llm = function(adapter)
                            return "CodeCompanion (" .. adapter.formatted_name .. ")"
                        end,

                        -- 用户消息的标题名称
                        -- 当前效果：显示为 "Me"
                        -- 可选取值：字符串（目前仅支持字符串）
                        user = "Me",
                    },

                    -- 其他 UI 选项
                    -- 聊天缓冲区的欢迎提示信息
                    -- 当前效果：显示 "Welcome to CodeCompanion ✨! Press ? for options"
                    -- 可选取值：任意字符串
                    intro_message = "Welcome to CodeCompanion ✨! Press ? for options",

                    -- 聊天消息之间的分隔符
                    -- 当前效果：使用 "─" 作为分隔符
                    -- 可选取值：任意字符串或符号
                    separator = "─",

                    -- 是否在聊天缓冲区显示上下文（来自编辑器和斜杠命令）
                    -- 当前效果：true → 显示上下文
                    -- 可选取值：true（显示）、false（隐藏）
                    show_context = true,

                    -- 是否显示标题分隔符
                    -- 当前效果：false → 不显示标题分隔符
                    -- 可选取值：true（显示）、false（隐藏）
                    -- 建议：如果使用外部 markdown 渲染插件，设为 false
                    show_header_separator = false,

                    -- 是否在聊天缓冲区顶部显示 LLM 设置
                    -- 当前效果：false → 不显示设置
                    -- 可选取值：true（显示）、false（隐藏）
                    show_settings = false,

                    -- 是否显示每个回复的 token 数量
                    -- 当前效果：true → 显示 token 数
                    -- 可选取值：true（显示）、false（隐藏）
                    show_token_count = true,

                    -- 是否显示工具执行时的加载提示
                    -- 当前效果：true → 显示工具执行中的提示信息
                    -- 可选取值：true（显示）、false（隐藏）
                    show_tools_processing = true,

                    -- 打开聊天缓冲区时是否直接进入插入模式
                    -- 当前效果：false → 打开时处于普通模式
                    -- 可选取值：true（插入模式）、false（普通模式）
                    start_in_insert_mode = false,
                },
                cli = {
                    window = {
                        layout = "vertical",
                        width = 0.5,
                        height = 0.6,
                        opts = { list = false },
                    },
                },
            },
            interactions = {
                chat = {
                    -- adapter = "siliconflow_r1",
                    -- adapter = "qwen2_coder_local",
                    adapter = platform.is_office and "tplink_qwen_internal" or "siliconflow_deepseek_online",
                    -- adapter = {
                    --     -- 适配器名称
                    --     -- 当前效果：使用 "anthropic" 适配器
                    --     -- 可选取值：copilot、acp、http 或其他自定义适配器名称
                    --     name = "claude_opus_online",
                    --
                    --     -- 模型名称
                    --     -- 当前效果：使用 "claude-haiku-4-5-20251001" 模型
                    --     -- 可选取值：根据适配器支持的模型名称而定
                    --     -- model = "claude-haiku-4-5-20251001",
                    -- },
                    editor_context = {
                        ["buffer"] = {
                            description = "Share the current buffer with the LLM(diff)",
                            opts = {
                                -- 默认参数设置为 "diff"
                                -- 当前效果：每次对话时自动同步 buffer 的差异部分
                                -- 可选取值："diff"（只共享修改部分）、"all"（共享整个 buffer）
                                default_params = "diff",
                            },
                        },
                        ["buffer-all"] = {
                            description = "Share the current buffer with the LLM(all)",
                            opts = {
                                -- 默认参数设置为 "diff"
                                -- 当前效果：每次对话时自动同步整个 buffer
                                -- 可选取值："diff"（只共享修改部分）、"all"（共享整个 buffer）
                                default_params = "all",
                            },
                        },
                    },
                    keymaps = {
                        close = {
                            modes = { n = "<C-q>", i = "<C-q>" },
                            opts = { silent = true, desc = "Close chat" },
                        },
                    },
                    slash_commands = {
                        ["file"] = {
                            opts = {
                                -- 指定 /file 命令的 provider
                                -- 当前效果：使用 telescope 作为 provider
                                -- 可选取值：
                                --   "default"   → 内置默认 provider
                                --   "telescope" → 使用 telescope 插件
                                --   "fzf_lua"   → 使用 fzf-lua 插件
                                --   "mini_pick" → 使用 mini_pick 插件
                                --   "snacks"    → 使用 snacks.nvim 插件
                                provider = "telescope",
                            },
                        },
                    },
                    opts = {
                        -- 指定补全引擎
                        -- 当前效果：使用 "blink" 作为补全引擎
                        -- 可选取值：
                        --   "blink"   → 使用 blink.cmp
                        --   "cmp"     → 使用 nvim-cmp
                        --   "coc"     → 使用 coc.nvim
                        --   "default" → 使用内置默认补全引擎
                        completion_provider = "blink",
                        -- 修饰用户消息的函数
                        -- 参数：
                        --   message → 用户输入的消息
                        --   adapter → 当前适配器
                        --   context → 当前上下文表
                        -- 返回值：修饰后的字符串
                        prompt_decorator = function(message, adapter, context)
                            -- 当前效果：将用户消息包裹在 <prompt></prompt> 标签中
                            return string.format([[%s]], message)
                        end,

                        context_management = {
                            -- 是否启用上下文管理
                            -- 当前效果：true → 启用上下文管理
                            -- 可选取值：true（启用）、false（禁用）
                            enabled = true,
                            editing = {
                                -- 编辑操作触发阈值
                                -- 当前效果：当上下文窗口使用达到 65% 时，删除旧的工具结果
                                -- 可选取值：小数（百分比）、整数（绝对 token 数）
                                trigger = 0.65, -- 65% of the context window
                                -- 排除的工具列表
                                -- 当前效果：memory 工具的输出不会被编辑
                                -- 可选取值：工具名称数组
                                exclude_tools = { "memory" }, -- Output from these tools is never edited

                                -- 保留的循环数
                                -- 当前效果：保留最近 3 个循环的完整工具结果
                                -- 可选取值：整数（循环数量）
                                keep_cycles = 3, -- Keep the last N cycles of tool results
                            },
                            compaction = {
                                -- 压缩操作触发阈值
                                -- 当前效果：当上下文窗口使用达到 85% 时，对消息历史进行摘要
                                -- 可选取值：小数（百分比）、整数（绝对 token 数）
                                trigger = 0.85, -- 85% of the context window
                                -- 最小 token 节省量
                                -- 当前效果：只有在至少节省 10000 token 时才进行压缩
                                -- 可选取值：整数（token 数）
                                min_token_savings = 10000, -- Only compact when at least this amount of tokens will be saved

                                -- 压缩使用的适配器
                                -- 当前效果：nil → 默认使用当前聊天适配器
                                -- 可选取值：nil（默认）、字符串（适配器名称）、表（包含 name 和 model）
                                adapter = nil,

                                -- 压缩失败时是否回退到聊天适配器
                                -- 当前效果：false → 不回退
                                -- 可选取值：true（回退）、false（不回退）
                                fallback_to_chat_adapter = false, -- on failure, retry with the chat adapter?
                            },
                        },
                    },
                    tools = {
                        git = require("ai.codecompanion_tools.git"),
                        groups = {
                            ["git_workflow"] = {
                                description = "My git workflow",
                                system_prompt = function(group, ctx)
                                    return string.format(
                                        "You are a git version control assistant. The date is %s. The user is on %s.",
                                        ctx.date,
                                        ctx.os
                                    )
                                end,
                                tools = { "git" },
                                opts = {
                                    collapse_tools = false,
                                    ignore_system_prompt = true, -- Remove the chat's default system prompt
                                    ignore_tool_system_prompt = false, -- Remove the default tool system prompt
                                    judge_in_yolo_mode = true,
                                },
                            },
                        },
                    },
                },
                inline = {
                    -- 作用: 配置内联模式下使用的 AI 适配器后端
                    -- 当前: 使用 Siliconflow Deepseek 在线版作为内联模式适配器
                    -- 可选: "copilot" | "openai" | "claude" | "gemini" | "siliconflow_r1" | "claude_opus_online"
                    -- 备注: 此适配器针对中文代码优化，支持长上下文理解
                    adapter = platform.is_office and "tplink_qwen_internal" or "siliconflow_deepseek_online",
                    keymaps = {
                        accept_change = {
                            -- 作用: 接受 AI 内联建议的代码更改
                            -- 当前: 普通模式下按 `ga` 触发接受操作
                            -- 可选: 任意合法的 Neovim 按键映射字符串，如 "<CR>" | "<leader>a" 等
                            modes = { n = "ga" },
                            description = "Accept the suggested change",
                        },
                        reject_change = {
                            -- 作用: 拒绝 AI 内联建议的代码更改
                            -- 当前: 普通模式下按 `gr` 触发拒绝操作，并设置 nowait 立即响应
                            -- 可选: 任意合法的 Neovim 按键映射字符串，如 "<Esc>" | "<leader>r" 等
                            modes = { n = "gr" },
                            opts = { nowait = true },
                            description = "Reject the suggested change",
                        },
                    },
                },
                agent = {
                    --adapter = "siliconflow_r1"
                    adapter = "copilot_acp",
                },
                cli = {
                    -- 默认 agent 可以设为 claude_code 或 copilot
                    agent = "copilot",
                    -- 定义 Copilot CLI agent
                    agents = {
                        copilot = {
                            cmd = "copilot", -- GitHub Copilot CLI 命令
                            args = {}, -- 启用 ACP 模式
                            description = "GitHub Copilot CLI",
                            provider = "terminal", -- 使用内置 terminal provider
                        },
                        claude_code = {
                            cmd = "claude",
                            args = {},
                            description = "Claude Code CLI",
                            provider = "terminal",
                        },
                    },

                    -- CLI 选项
                    opts = {
                        auto_insert = false,
                        reload = true,
                    },

                    -- 快捷键配置
                    keymaps = {
                        next_chat = {
                            modes = { n = "}" },
                            callback = "keymaps.next_chat",
                            description = "[Nav] Next interaction",
                        },
                        previous_chat = {
                            modes = { n = "{" },
                            callback = "keymaps.previous_chat",
                            description = "[Nav] Previous interaction",
                        },
                    },
                    -- 打开 CLI buffer 时调用 keymap 设置
                    on_open = function()
                        set_terminal_keymaps()
                    end,
                },
                code_review = {
                    enabled = false,
                },
                opts = {
                    -- 兼容Windows环境，解决中文日期格式导致LLM报错
                    date_format = "%Y-%m-%d", -- The date format to use in system prompts
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
                        -- 不显示预设的适配器
                        show_presets = false,
                    },
                    -- Define your custom adapters here
                    copilot_acp = function()
                        return require("codecompanion.adapters").extend("copilot_acp", {
                            name = "copilot_acp",
                            commands = {
                                default = {
                                    "copilot",
                                    "--acp",
                                },
                            },
                            env = {
                                COPILOT_PROVIDER = "github",
                                COPILOT_API_KEY = type(creds.copilot.api_key) == "function" and creds.copilot.api_key()
                                    or creds.copilot.api_key,
                            },
                            defaults = {
                                timeout = 30000, -- 20 seconds
                            },
                        })
                    end,
                },
                http = {
                    opts = {
                        show_defaults = false,
                        allow_insecure = true,
                        -- 不显示预设的适配器
                        show_presets = false,
                        -- 显示模型选择
                        show_model_choices = true,
                    },
                    siliconflow_deepseek_online = function()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_r1_deepseek_online",
                            url = "https://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = type(creds.siliconflow.api_key) == "function" and creds.siliconflow.api_key()
                                    or creds.siliconflow.api_key,
                            },
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = true,
                            },
                            parameters = {
                                sync = true,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-ai/DeepSeek-V4-Flash",
                                    choices = {
                                        -- can_reason: false 表示禁用复杂推理任务
                                        ["deepseek-ai/DeepSeek-R1"] = { opts = { can_reason = false } },
                                        ["deepseek-ai/DeepSeek-V3"] = { opts = { can_reason = false } },
                                        ["deepseek-ai/DeepSeek-V4-Flash"] = {
                                            meta = { context_window = 1048576 },
                                            opts = { can_reason = false, can_use_tools = true },
                                        },
                                        ["deepseek-ai/DeepSeek-V4-Pro"] = { opts = { can_reason = true } },
                                    },
                                },
                                max_tokens = {
                                    default = 8192,
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
                                api_key = type(creds.kimi.api_key) == "function" and creds.kimi.api_key()
                                    or creds.kimi.api_key,
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
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = false,
                            },
                            parameters = {
                                sync = true,
                            },
                        })
                    end,

                    dashscope_online = function()
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
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = false,
                            },
                            parameters = {
                                sync = true,
                            },
                        })
                    end,
                    claude_opus_online = function()
                        return require("codecompanion.adapters").extend("openai", {
                            name = "claude_opus_online",
                            url = "https://api.qnaigc.com/v1/chat/completions", -- 七牛云兼容模式地址
                            env = {
                                api_key = type(creds.claude.api_key) == "function" and creds.claude.api_key()
                                    or creds.claude.api_key,
                            },
                            schema = {
                                model = {
                                    default = "claude-4.6-sonnet", -- 默认模型
                                    -- default = "anthropic/claude-opus-4.6",
                                    choices = {
                                        -- ["anthropic/claude-opus-4.6"] = { opts = { can_reason = true } },
                                        ["claude-4.6-opus"] = { opts = { can_reason = true } },
                                        ["claude-4.6-sonnet"] = { opts = { can_reason = true } },
                                    },
                                },
                                num_ctx = {
                                    default = 8192, -- 上下文长度
                                },
                                keep_alive = {
                                    default = "5m",
                                },
                                -- 下面两行不生效，需要主调插件源码中openai.lua中的top_p
                                temperature = nil,
                                top_p = nil, -- 显式覆盖掉 top_p，七牛云不支持同时出现temperature和top_p
                            },
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = false,
                            },
                            parameters = {
                                sync = true,
                            },
                        })
                    end,
                    tplink_web_internal = function()
                        return require("codecompanion.adapters").extend("tplink", {
                            name = "tplink",
                            url = "https://aichat.tp-link.com/api/chat/chat",
                            env = {
                                username = type(creds.tplink.username) == "function" and creds.tplink.username()
                                    or creds.tplink.username,
                                password = type(creds.tplink.password) == "function" and creds.tplink.password()
                                    or creds.tplink.password(),
                            },
                            opts = {
                                vision = true,
                                thinking = false,
                                stream = true,
                            },
                            parameters = {
                                sync = true,
                            },
                        })
                    end,
                    tplink_qwen_internal = function()
                        return require("codecompanion.adapters").extend("tplink_qwen", {
                            name = "tplink_qwen_internal",
                            url = "http://172.29.158.38:8000/v1/chat/completions",
                            env = {
                                api_key = function()
                                    return nil
                                end, -- 本地模型通常不需要 API key
                            },
                            headers = {
                                ["Content-Type"] = "application/json",
                            },
                            opts = {
                                vision = true,
                                thinking = true,
                                stream = true,
                            },
                            schema = {
                                model = {
                                    default = "Qwen3.6-35B-A3B",
                                    choices = {
                                        ["Qwen3.6-35B-A3B"] = {
                                            meta = { context_window = 262144 },
                                            opts = { can_reason = true, can_use_tools = true },
                                        },
                                    },
                                },
                                max_tokens = {
                                    default = 8192,
                                },
                                think = {
                                    default = true,
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
            extensions = {
                history = {
                    enabled = true,
                    opts = {
                        -- Keymap to open history from chat buffer (default: gh)
                        keymap = "gh",
                        -- Keymap to save the current chat manually (when auto_save is disabled)
                        save_chat_keymap = "sc",
                        -- Save all chats by default (disable to save only manually using 'sc')
                        auto_save = false,
                        -- Number of days after which chats are automatically deleted (0 to disable)
                        expiration_days = 0,
                        -- Picker interface (auto resolved to a valid picker)
                        picker = "telescope", --- ("telescope", "snacks", "fzf-lua", or "default")
                        ---Optional filter function to control which chats are shown when browsing
                        chat_filter = nil, -- function(chat_data) return boolean end
                        -- Customize picker keymaps (optional)
                        picker_keymaps = {
                            rename = { n = "r", i = "<M-r>" },
                            delete = { n = "d", i = "<M-d>" },
                            duplicate = { n = "<C-y>", i = "<C-y>" },
                        },
                        ---Automatically generate titles for new chats
                        auto_generate_title = true,
                        title_generation_opts = {
                            ---Adapter for generating titles (defaults to current chat adapter)
                            adapter = platform.is_office and "tplink_qwen_internal" or "siliconflow_deepseek_online", -- "copilot"
                            ---Model for generating titles (defaults to current chat model)
                            model = platform.is_office and "Qwen3.6-35B-A3B" or nil, -- "gpt-4o"
                            ---Number of user prompts after which to refresh the title (0 to disable)
                            refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
                            ---Maximum number of times to refresh the title (default: 3)
                            max_refreshes = 3,
                            format_title = function(original_title)
                                -- this can be a custom function that applies some custom
                                -- formatting to the title.
                                return original_title
                            end,
                        },
                        ---On exiting and entering neovim, loads the last chat on opening chat
                        continue_last_chat = false,
                        ---When chat is cleared with `gx` delete the chat from history
                        delete_on_clearing_chat = false,
                        ---Directory path to save the chats
                        dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
                        ---Enable detailed logging for history extension
                        enable_logging = false,

                        -- Summary system
                        summary = {
                            -- Keymap to generate summary for current chat (default: "gcs")
                            create_summary_keymap = "gcs",
                            -- Keymap to browse summaries (default: "gbs")
                            browse_summaries_keymap = "gbs",

                            generation_opts = {
                                adapter = nil, -- defaults to current chat adapter
                                model = nil, -- defaults to current chat model
                                context_size = 90000, -- max tokens that the model supports
                                include_references = true, -- include slash command content
                                include_tool_outputs = true, -- include tool execution results
                                system_prompt = nil, -- custom system prompt (string or function)
                                format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
                            },
                        },

                        -- Memory system (requires VectorCode CLI)
                        memory = {
                            -- Automatically index summaries when they are generated
                            auto_create_memories_on_summary_generation = true,
                            -- Path to the VectorCode executable
                            vectorcode_exe = "vectorcode",
                            -- Tool configuration
                            tool_opts = {
                                -- Default number of memories to retrieve
                                default_num = 10,
                            },
                            -- Enable notifications for indexing progress
                            notify = true,
                            -- Index all existing memories on startup
                            -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
                            index_on_startup = false,
                        },
                    },
                },
                agentskills = {
                    opts = {
                        paths = {
                            { "~/.config/skills", recursive = true }, -- Recursive search
                        },
                        notify_on_discovery = true, -- Show a notification when skills are discovered
                    },
                },
            },
            mcp = {
                servers = {
                    ["filesystem"] = {
                        cmd = {
                            "npx",
                            "-y",
                            "@modelcontextprotocol/server-filesystem",
                            vim.fn.getcwd(),
                        },
                        -- 最新版本的mcp已经启用roots
                        -- roots = function()
                        --     return { { name = "project", path = vim.fn.getcwd() } }
                        -- end,
                    },
                    ["sequential-thinking"] = {
                        cmd = { "npx", "-y", "@modelcontextprotocol/server-sequential-thinking" },
                    },
                    -- 联网
                    ["tavily-mcp"] = {
                        cmd = { "npx", "-y", "tavily-mcp@latest" },
                    },
                    ["obsidian"] = {
                        -- 使用 mcp-remote 包装 HTTP MCP server
                        cmd = {
                            "mcp-remote",
                            "http://192.168.100.1:27123/mcp/",
                            "--allow-http",
                            "--header",
                            "Authorization: Bearer ${AUTH_TOKEN}",
                        },
                        env = {
                            -- OBSIDIAN_TOKEN = os.getenv("OBSIDIAN_TOKEN"), -- 如果需要认证
                            AUTH_TOKEN = os.getenv("OBSIDIAN_API_KEY"),
                        },
                    },
                    ["zotero-mcp"] = {
                        -- 使用 mcp-remote 包装 HTTP MCP server
                        cmd = {
                            "mcp-remote",
                            "http://192.168.100.1:23120/mcp",
                            "--debug",
                        },
                    },
                },
                opts = {
                    -- default_servers = { "sequential-thinking" },
                },
            },
        })
    end,
}
