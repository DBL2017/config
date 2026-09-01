local M = {}

local SYSTEM_PROMPT = [[
你是一个资深代码评审专家，正在为 Gerrit change 做代码评审。

评审原则：
- 优先发现真实的逻辑错误、边界条件、并发问题、安全风险、性能问题和回归风险。
- 不要纠结纯格式问题，除非它会影响可读性、维护性或行为。
- 如果 diff 信息不足以判断，请明确说明缺少什么上下文，不要臆测。

输出要求：
- 使用中文。
- 按严重程度排序。
- 每个问题给出文件、原因、影响和建议修改方式。
- 如果没有明显问题，请明确说明。
]]

local function diff_file_list(diff)
    local files = {}

    for _, file in ipairs(diff.files or {}) do
        table.insert(files, string.format("- %s", file))
    end

    if #files == 0 then
        return "- 未获取到文件列表"
    end

    return table.concat(files, "\n")
end

local function open_codecompanion_review(diff_info)
    local config = require("codecompanion.config")
    local change = diff_info.change or {}
    local diff = table.concat(diff_info.raw or {}, "\n")

    local prompt = string.format(
        [[
请基于下面的 Gerrit change diff 做代码评审。

评审对象：
- Number: %s
- Project: %s
- Branch: %s
- Subject: %s
- CommitMessage:
%s

变更文件：
%s

```diff
%s
```
]],
        change.number or "",
        change.project or "",
        change.branch or "",
        change.subject or "",
        diff_info.commitMessage,
        diff_file_list(diff_info),
        diff
    )

    local chat = require("codecompanion").chat({
        stop_context_insertion = true,
        intro_message = "Gerrit AI Review",
    })

    if not chat then
        vim.notify("CodeCompanion chat 创建失败", vim.log.levels.ERROR)
        return
    end

    -- 部分推理模型（thinking/can_reason 开启，例如 tplink_qwen_internal）在处理较长的
    -- diff 时，容易把 max_tokens 全部消耗在 reasoning 阶段，导致最终没有正式回复内容
    -- 写入 chat 窗口（只显示 reasoning）。这里适当调大 max_tokens，避免被截断。
    if chat.settings and type(chat.settings.max_tokens) == "number" then
        chat.settings.max_tokens = math.max(chat.settings.max_tokens * 4, 32768)
    end

    chat:set_system_prompt(SYSTEM_PROMPT, { visible = true })
    chat:add_buf_message({
        role = config.constants.USER_ROLE,
        content = prompt,
    })
    chat.ui:open()
    vim.schedule(function()
        -- chat:submit()
    end)
end

function M.review(change_number)
    local arg = change_number
    if arg == "" then
        arg = nil
    end

    require("gerrit").get_diff(arg, function(diff, err)
        if not diff then
            vim.notify(err or "Gerrit diff 获取失败", vim.log.levels.ERROR)
            return
        end

        if not diff.raw or #diff.raw == 0 then
            vim.notify("该 patch set diff 为空", vim.log.levels.WARN)
            return
        end

        open_codecompanion_review(diff)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("GerritAIReview", function(opts)
        M.review(opts.args)
    end, {
        nargs = "?",
        desc = "使用 CodeCompanion 评审 Gerrit change diff",
    })
end

return M
