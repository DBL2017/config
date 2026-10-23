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
        -- lualine: 用于状态栏显示（history 扩展可能用到）
        "nvim-lualine/lualine.nvim",
    },
    cmd = {
        "CodeCompanion", -- 打开主菜单
        "CodeCompanionChat", -- 打开聊天窗口
        "CodeCompanionActions", -- 打开操作面板
        "CodeCompanionHistory", -- 打开历史记录
    },
    -- 锁定插件版本范围，避免升级引入破坏性变更
    version = "^19.22.0",
    config = function()
        require("codecompanion").setup({
            -- 提示词库（prompt library）配置
            prompt_library = {
                markdown = {
                    -- 自定义提示词目录：优先使用项目目录，其次使用用户配置目录
                    dirs = {
                        vim.fs.joinpath(vim.fn.getcwd(), ".prompts"), -- 项目级 .prompts 目录
                        vim.fs.joinpath(vim.fn.stdpath("config"), "prompts"), -- 用户配置 prompts 目录
                    },
                },
            },
            rules = {
                default = {
                    files = {
                        vim.fs.joinpath(vim.fn.stdpath("config"), "rules", "clang_format_rules.md"),
                    },
                },
                learning_to_code = {
                    description = "Learning to Code",
                    enabled = true,
                    files = {
                        vim.fs.joinpath(vim.fn.stdpath("config"), "rules", "learning_to_code.md"),
                    },
                },
                tplink_rules = {
                    description = "Rule files for TPLink C",
                    enabled = true,
                    files = {
                        vim.fs.joinpath(vim.fn.stdpath("config"), "rules", "tplink_c_coding_standard.md"),
                    },
                },
                opts = {
                    chat = {
                        -- autoload = platform.is_office and "tplink_rules" or "default",
                        -- 不要在prompt_library中自动加载rules，可以主动配置到对应的prompt中
                        autoload_groups_in_prompt_library = false,
                        enabled = false,
                    },
                },
            },
            skills = {
                dirs = {
                    vim.fs.joinpath(vim.fn.stdpath("config"), "skills"),
                    vim.fs.joinpath(vim.fn.stdpath("config"), "..", "skills"),
                },
                ["demo"] = {
                    description = "demo",
                    skills = { "demo-skill" },
                },
                ["tplink-security"] = {
                    description = "security code",
                    skills = {
                        "skl-archer-platform-code-baseline",
                        "skl-c-lua-safecoding",
                        "skl-repo-security-scan",
                    },
                },
                ["tplink-baseline"] = {
                    description = "tplink baseline",
                    skills = {
                        "gerrit-code-review",
                        "ai-review-line-number-resolution",
                        "code-review-token-optimization",
                        "deadlock-review-rules",
                        "resource_management_review",
                        "sashiko-kernel-review",
                    },
                },
                ["tplink-jira"] = {
                    description = "tplink jira",
                    skills = {
                        "tempo-submit",
                    },
                },
                ["common"] = {
                    description = "common skills",
                    skills = {
                        "academy-guide",
                        "algorithmic-art",
                        "brand-guidelines",
                        "canvas-design",
                        "claude-api",
                        "discernment-nudge",
                        "doc-coauthoring",
                        "docx",
                        "frontend-design",
                        "internal-comms",
                        "mcp-builder",
                        "pdf",
                        "pptx",
                        "problem-analysis-documentation",
                        "skill-creator",
                        "slack-gif-creator",
                        "theme-factory",
                        "web-artifacts-builder",
                        "webapp-testing",
                        "xlsx",
                    },
                },
                opts = {
                    chat = {
                        enabled = true,
                        -- Skills and groups can be autoloaded into the chat buffer on startup.
                        autoload = platform.is_office and { "tplink-baseline", "tplink-security" } or {},
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
                    auto_scroll = true, -- 默认会自动滚动到最后，设置为 false 可避免长回复时界面跳动

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
                    show_reasoning = false,

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
                        -- 当前效果：办公环境占 40%（0.4），非办公环境占 50%（0.5）
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
                            linebreak = false,

                            -- 长段落自动换行，避免横向滚动
                            wrap = true,

                            -- 不高亮当前行，避免干扰
                            cursorline = true,

                            -- 不显示标记列
                            signcolumn = "no",
                            -- nvim-tree 开关时保持 Chat 窗口的初始宽度
                            winfixwidth = true,
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
                    show_header_separator = true,

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
                -- 后台交互：用便宜的模型执行标题生成、LLM judge 等任务
                background = {
                    -- 后台交互使用的默认适配器
                    adapter = platform.is_office and "tplink_qwen_internal" or "siliconflow_deepseek_online",
                    chat = {
                        callbacks = {
                            ["on_ready"] = {
                                actions = {
                                    "interactions.background.builtin.chat_make_title",
                                },
                                enabled = true,
                            },
                        },
                        opts = {
                            enabled = true,
                        },
                    },
                    gates = {
                        judge = {
                            -- 是否启用 LLM judge 机制
                            -- 当前效果：true → 在 auto 模式下，不在安全列表的命令先由后台 LLM 判断是否安全
                            -- 可选取值：true（启用）、false（禁用）
                            enabled = true,
                        },
                    },
                },
                chat = {
                    -- 聊天功能使用的适配器
                    -- 当前效果：办公环境用 copilot_acp，非办公环境用 siliconflow_deepseek_online
                    -- 可选取值：任意已定义适配器名称（见下方 adapters 部分）
                    -- 注：以下为备选适配器配置示例，默认已注释
                    adapter = platform.is_office and "copilot_acp" or "siliconflow_deepseek_online",
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
                                -- 当前效果：使用 @buffer 添加上下文时，发送当前 buffer 的差异部分
                                -- 可选取值："diff"（只共享修改部分）、"all"（共享整个 buffer）
                                default_params = "diff",
                            },
                        },
                        ["buffer-all"] = {
                            description = "Share the current buffer with the LLM(all)",
                            opts = {
                                -- 默认参数设置为 "all"
                                -- 当前效果：使用 @buffer-all 添加上下文时，发送当前 buffer 的全部内容
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
                                dirs = {
                                    vim.fn.getcwd(),
                                    vim.fs.joinpath(vim.fn.expand("~"), "windows_share/mobaxterm"),
                                    vim.fs.joinpath(vim.fn.expand("~"), "ai"),
                                },
                            },
                        },
                    },
                    opts = {
                        -- 已添加到聊天上下文的这些文件类型会持续监听变化，
                        -- 后续对话时自动同步修改内容，无需重新添加 buffer。
                        -- 这里的 key 使用文件扩展名，不包含点号。
                        sync_diff = {
                            ipynb = true,
                            lua = true,
                            py = true,
                            js = true,
                            jsx = true,
                            ts = true,
                            tsx = true,
                            json = true,
                            yaml = true,
                            yml = true,
                            md = true,
                            sh = true,
                            bash = true,
                            go = true,
                            rs = true,
                            c = true,
                            h = true,
                            cpp = true,
                            hpp = true,
                            java = true,
                            html = true,
                            css = true,
                        },
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
                        -- 联网搜索工具，使用 duckduckgo 作为搜索后端
                        ["web_search"] = {
                            opts = {
                                adapter = "duckduckgo",
                            },
                        },
                        ["grep_search"] = {
                            ---@param adapter CodeCompanion.HTTPAdapter
                            ---@return boolean
                            enabled = function(adapter)
                                return vim.fn.executable("rg") == 1
                            end,
                        },
                        -- 长期记忆工具，基于本地目录持久化聊天记忆
                        ["memory"] = {
                            opts = {
                                -- 白名单：指定可写入记忆的目录及其别名
                                whitelist = {
                                    -- { path = vim.fs.joinpath(vim.fn.getcwd()), as = "/memories" },
                                    { path = "~/projects/notes/content/post", as = "/notes" }, -- 笔记目录
                                    -- 使用 Neovim 展开的用户目录，避免 Windows 未设置 HOME 时传入 nil。
                                    { path = vim.fs.joinpath(vim.fn.expand("~"), "ai"), as = "ai" }, -- AI 目录
                                },
                            },
                        },
                        -- 执行 shell 命令。在 auto 模式下命中 safe_commands 不询问，其余交由 LLM judge 判断
                        ["run_command"] = {
                            opts = {
                                judge = true, -- 让后台 LLM 判断不在安全列表的命令是否安全
                                require_approval_before = true,
                                require_cmd_approval = true,
                                safe_commands = {
                                    "git status",
                                    "git diff",
                                    "git log",
                                    "ls",
                                    "pwd",
                                    "make build",
                                    "make test",
                                    "grep",
                                    "find",
                                }, -- 命中这些命令作为前缀的命令在 auto 模式下免询问
                                timeout = 300000, -- 命令超时（毫秒）
                            },
                        },
                        -- 删除文件。受保护，在任何模式下都默认询问
                        ["delete_file"] = {
                            opts = {
                                protect = true,
                                judge = true,
                                require_approval_before = true,
                            },
                        },
                        -- 自定义 git 工具（来自 codecompanion_tools/git.lua）
                        git = require("ai.codecompanion_tools.git"),
                        -- 工具组：将多个工具组合为一个动作
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
                                    collapse_tools = false, -- 不折叠工具输出
                                    ignore_system_prompt = true, -- 移除聊天的默认系统提示词
                                    ignore_tool_system_prompt = false, -- 保留工具默认系统提示词
                                    judge = true,
                                },
                            },
                        },
                        opts = {
                            -- 所有聊天缓冲区默认的审批模式
                            -- 当前效果：auto → 除受保护规则/需要审批的命令外，工具自动运行
                            -- 可选取值："ask"（每次询问）、"auto"（自动放行）、"yolo"（全部放行）
                            approval_mode = "auto",
                            -- 工具出错（status=error）时是否自动回传给 LLM
                            auto_submit_errors = true,
                            -- 工具成功时是否自动回传给 LLM
                            auto_submit_success = true,
                            -- 工具运行需要审批时是否发送通知
                            notify_on_approval = true,
                        },
                    },
                    -- 聊天会话持久化（v19+ 内置的 sessions 系统，取代 history 扩展）
                    sessions = {
                        -- 是否启用会话管理
                        -- 当前效果：true → 聊天会被记录为会话，可通过 :CodeCompanionHistory 浏览/恢复
                        -- 可选取值：true（启用）、false（禁用）
                        enabled = true,

                        -- 是否在交互结束时自动保存会话
                        -- 当前效果： false→ 手动保存之后每轮会话结束会根据continuous_save判断是否自动保存
                        -- 可选取值：true（自动保存）、false（仅手动保存）
                        autosave = false,

                        -- 是否在流式响应过程中持续保存
                        -- 当前效果：true → LLM 输出过程中就写入磁盘，Neovim 崩溃时可恢复到最新状态
                        -- 可选取值：true（持续保存）、false（仅在响应结束后保存）
                        continuous_save = true,

                        -- 会话文件的存储目录
                        -- 当前效果：保存到 Neovim 数据目录下的 codecompanion/sessions
                        -- 可选取值：任意绝对路径字符串
                        save_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "codecompanion", "sessions"),
                    },
                },
                inline = {
                    -- 作用: 配置内联模式下使用的 AI 适配器后端
                    -- 当前: 使用 Siliconflow Deepseek 在线版作为内联模式适配器
                    -- 可选: "copilot" | "openai" | "claude" | "gemini" |
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
                language = "English",
            },
            adapters = {
                acp = {
                    opts = {
                        show_defaults = false,
                        -- 不显示预设的适配器
                        show_presets = false,
                    },
                    -- 以下为自定义适配器：扩展内置适配器以满足特定需求
                    -- 办公环境默认聊天适配器，基于 GitHub Copilot ACP
                    copilot_acp = function()
                        return require("codecompanion.adapters").extend("copilot_acp", {
                            name = "copilot_acp",
                            -- copilot不需要设置环境变量api_key，而是copilot_cli直接读取环境变量COPILOT_GITHUB_TOKEN
                            defaults = {
                                timeout = 30000, -- 30 seconds
                                model = platform.is_office and "gpt-5.6-luna" or nil, -- Add default model here
                                mcpServers = "inherit_from_config",
                            },
                        })
                    end,
                },
                http = {
                    opts = {
                        show_defaults = false,
                        allow_insecure = true, -- 允许使用非 HTTPS 接口
                        -- 不显示预设的适配器
                        show_presets = false,
                        -- 显示模型选择
                        show_model_choices = true,
                    },
                    -- 非办公环境默认聊天适配器：硅基流动（SiliconFlow）上的 DeepSeek 在线版
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
                                        -- DeepSeek-R1：专为复杂推理任务设计的模型（数学、逻辑、算法难题、深度分析）。
                                        -- 擅长长链式链式思考（chain-of-thought），在数学竞赛、代码难题、逻辑推理等对精细推理要求高的场景表现最佳。
                                        -- 注意：当前配置 can_reason = false，若需要完整推理能力可改为 true。
                                        ["deepseek-ai/DeepSeek-R1"] = { opts = { can_reason = false } },
                                        -- DeepSeek-V3：通用高性能模型，均衡的对话与代码能力。
                                        -- 擅长日常对话、代码生成与重构、文档总结、知识问答等常规任务，性价比高、兼容性好。
                                        ["deepseek-ai/DeepSeek-V3"] = { opts = { can_reason = false } },
                                        -- DeepSeek-V4-Flash：主打快速推理与低延迟吞吐。
                                        -- 上下文窗口超大（1M），适合实时交互、大量代码补全、日志/长文档处理、流水线批处理等对速度敏感、对深度推理要求不高的场景。
                                        ["deepseek-ai/DeepSeek-V4-Flash"] = {
                                            meta = { context_window = 1048576 },
                                            opts = {
                                                can_reason = false,
                                                can_use_tools = true,
                                                -- vLLM 支持 OpenAI 的 response_format.json_schema，
                                                -- 缺少该声明会让 background judge 的结构化裁决被静默丢弃，
                                                -- 导致 "The judge returned an unreadable response"。
                                                can_form_structured_outputs = true,
                                            },
                                        },
                                        -- DeepSeek-V4.1-Flash：V4-Flash 的增强升级版，在保持高速推理的同时提升回答质量。
                                        -- 适合追求速度与质量平衡的日常辅助：代码编写/解释、快速总结、实时代码审查等。
                                        ["deepseek-ai/DeepSeek-V4.1-Flash"] = {
                                            meta = { context_window = 1048576 },
                                            opts = {
                                                can_reason = false,
                                                can_use_tools = true,
                                                -- vLLM 支持 OpenAI 的 response_format.json_schema，
                                                -- 缺少该声明会让 background judge 的结构化裁决被静默丢弃，
                                                -- 导致 "The judge returned an unreadable response"。
                                                can_form_structured_outputs = true,
                                            },
                                        },
                                        -- DeepSeek-V4-Pro：旗舰级模型，最强的综合能力（推理、代码、Agent 任务）。
                                        -- 擅长高难度的代码生成与调试、复杂架构设计、长链路 Agent/工具调用、深度分析与疑难问题排查。成本较高，建议用于关键任务。
                                        ["deepseek-ai/DeepSeek-V4-Pro"] = {
                                            opts = { can_reason = true },
                                        },
                                        -- Qwen/Qwen3.6-35B-A3B：MoE 稀疏模型（激活 3.5B 参数），推理高效、开销低。
                                        -- 擅长代码生成与理解、工具调用，在中低硬件成本下保持不错的综合性能，适合日常代码辅助与批量任务。
                                        ["Qwen/Qwen3.6-35B-A3B"] = {
                                            meta = { context_window = 256 * 1024 },
                                            opts = { can_reason = false, can_use_tools = true },
                                        },
                                        -- Qwen/Qwen3.8-27B：Dense 稠密模型，代码与数学能力突出。
                                        -- 擅长编程（生成、调试、优化）、数学推理、结构化任务，推理质量稳定，适合需要较高精度代码处理的场景。
                                        ["Qwen/Qwen3.8-27B"] = {
                                            meta = { context_window = 262144 },
                                            opts = {
                                                can_reason = false,
                                                can_use_tools = true,
                                                -- vLLM 支持 OpenAI 的 response_format.json_schema，
                                                -- 缺少该声明会让 background judge 的结构化裁决被静默丢弃，
                                                -- 导致 "The judge returned an unreadable response"。
                                                can_form_structured_outputs = true,
                                            },
                                        },
                                        -- Pro/moonshotai/Kimi-K2.6（月之暗面）：Agentic 编码与工具调用能力出众。
                                        -- 擅长多步骤编程任务（自动改代码、跑测试、迭代修复）、长上下文理解和复杂工具编排，适合深度 Coding Agent 工作流。
                                        ["Pro/moonshotai/Kimi-K2.6"] = {
                                            meta = { context_window = 262144 },
                                            opts = {
                                                can_reason = false,
                                                can_use_tools = true,
                                                -- vLLM 支持 OpenAI 的 response_format.json_schema，
                                                -- 缺少该声明会让 background judge 的结构化裁决被静默丢弃，
                                                -- 导致 "The judge returned an unreadable response"。
                                                can_form_structured_outputs = true,
                                            },
                                        },
                                    },
                                },
                                max_tokens = {
                                    -- The maximum number of tokens to generate, excluding chain-of-thought. Avoid setting max_tokens to the window's upper bound; reserve ~10k tokens as buffer for input and system overhead.
                                    default = 32768,
                                },
                                ["enable_thinking"] = {
                                    default = false,
                                },
                                ["thinking.type"] = {
                                    default = "disabled",
                                },
                            },
                        })
                    end,
                    -- 本地局域网 Ollama 上的 Qwen2.5-Coder 模型
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
                    -- 月之暗面（Moonshot/Kimi）OpenAI 兼容接口在线适配器
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

                    -- 阿里云百炼（DashScope）OpenAI 兼容接口适配器
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
                    -- 七牛云 API 的 Claude 在线适配器（OpenAI 兼容模式）
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
                    -- 公司内网 TP-Link 网页版适配器（使用账号密码登录）
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
                    -- 办公环境内联适配器：内网 vLLM 服务上的 Qwen3，关闭了 thinking 输出
                    tplink_qwen_internal = function()
                        return require("codecompanion.adapters").extend("tplink_qwen", {
                            name = "tplink_qwen_internal",
                            url = "http://172.29.158.38:8000/v1/chat/completions",
                            env = {
                                api_key = function()
                                    return nil
                                end, -- 本地模型通常不需要 API key
                            },
                            schema = {
                                model = {
                                    default = "Qwen3.6-35B-A3B",
                                    choices = {
                                        ["Qwen3.6-35B-A3B"] = {
                                            meta = { context_window = 262144 },
                                            opts = {
                                                can_reason = true,
                                                can_use_tools = true,
                                                -- vLLM 支持 OpenAI 的 response_format.json_schema，
                                                -- 缺少该声明会让 background judge 的结构化裁决被静默丢弃，
                                                -- 导致 "The judge returned an unreadable response"。
                                                can_form_structured_outputs = true,
                                            },
                                        },
                                    },
                                },
                                max_tokens = {
                                    default = 32768,
                                },
                                -- 注意：tplink_qwen 基础适配器继承自 deepseek，"thinking.type" 是
                                -- DeepSeek/DashScope 商用 API 的参数格式（parameters.thinking.type）。
                                -- 但本适配器实际请求的是内网自建的 vLLM 服务(172.29.158.38:8000)，
                                -- vLLM 对 Qwen3 系列模型识别的关闭思考参数是请求体顶层的
                                -- chat_template_kwargs.enable_thinking，而不是 thinking.type。
                                -- 之前设置 thinking.type = "disabled" 会被 vLLM 静默忽略（未知字段），
                                -- 导致 Qwen3 仍按默认 enable_thinking=true 持续输出大量 reasoning，
                                -- 挤占 max_tokens 使正式回复被截断。这里改为发送 vLLM 真正认识的字段。
                                ["chat_template_kwargs.enable_thinking"] = {
                                    mapping = "parameters",
                                    type = "boolean",
                                    default = false,
                                    desc = "vLLM: 关闭 Qwen3 的 thinking/reasoning 输出",
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
            extensions = {},
            -- MCP（Model Context Protocol）服务器配置
            mcp = {
                servers = {
                    -- 文件系统访问服务器
                    ["filesystem"] = {
                        cmd = {
                            "npx",
                            "-y",
                            "@modelcontextprotocol/server-filesystem",
                            vim.fn.expand("~"), -- 跨平台获取用户目录
                        },
                        -- 最新版本的mcp已经启用roots
                        -- 旧版通过 roots 限制可访问目录（当前版本已内置，无需设置）
                        -- roots = function()
                        --     return { { name = "project", path = vim.fn.getcwd() } }
                        -- end,
                    },
                    -- 顺序思考服务器（用于复杂推理任务）
                    ["sequential-thinking"] = {
                        cmd = { "npx", "-y", "@modelcontextprotocol/server-sequential-thinking" },
                    },
                    -- 联网搜索服务器
                    ["tavily-mcp"] = {
                        cmd = { "npx", "-y", "tavily-mcp@latest" },
                    },
                    -- Obsidian 笔记库访问服务器
                    ["obsidian"] = {
                        -- 使用 mcp-remote 包装 HTTP MCP server，通过局域网远程连接
                        cmd = {
                            "mcp-remote",
                            "http://192.168.100.1:27123/mcp/", -- Obsidian Local REST API 地址
                            "--allow-http", -- 允许 HTTP 调用
                            "--header",
                            "Authorization: Bearer ${AUTH_TOKEN}", -- 携带认证令牌请求头
                        },
                        env = {
                            -- OBSIDIAN_TOKEN = os.getenv("OBSIDIAN_TOKEN"), -- 如需要认证可启用
                            -- 从环境变量读取 Obsidian API Key
                            AUTH_TOKEN = os.getenv("OBSIDIAN_API_KEY"),
                        },
                    },
                    -- Zotero 文献管理服务器
                    ["zotero-mcp"] = {
                        -- 使用 mcp-remote 包装 HTTP MCP server，远程连接 Zotero API
                        cmd = {
                            "mcp-remote",
                            "http://192.168.100.1:23120/mcp", -- Zotero MCP 服务地址
                            "--debug",
                        },
                    },
                    ["mcp-atlassian"] = {
                        cmd = { "uvx", "mcp-atlassian" },
                        env = {
                            CONFLUENCE_URL = os.getenv("CONFLUENCE_URL"),
                            CONFLUENCE_USERNAME = os.getenv("CONFLUENCE_USERNAME"),
                            CONFLUENCE_API_TOKEN = os.getenv("CONFLUENCE_API_TOKEN"),
                            JIRA_URL = os.getenv("JIRA_URL"),
                            JIRA_USERNAME = os.getenv("JIRA_USERNAME"),
                            JIRA_API_TOKEN = os.getenv("JIRA_API_TOKEN"),
                        },
                    },
                },
                opts = {
                    acp_enabled = true,
                    -- 默认启用的 MCP 服务器
                    default_servers = platform.is_office and { "sequential-thinking", "filesystem" }
                        or { "sequential-thinking", "filesystem" },
                },
            },
        })
    end,
}
