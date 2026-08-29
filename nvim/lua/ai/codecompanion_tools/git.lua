local log = require("codecompanion.utils.log")

local function make_response(status, msg)
    return { status = status, data = msg }
end

return {
    name = "git",
    cmds = {
        ---@param self CodeCompanion.Tool.Git
        ---@param args table
        function(self, args, opts)
            local action = args.action
            local extra_args = args.extra_args or {}

            if not action or action == "" then
                return make_response("error", "Git action is required")
            end

            -- 构造命令：git <action> <extra_args...>
            local cmd = { "git", action }
            vim.list_extend(cmd, extra_args)

            local output = vim.fn.system(cmd)
            if vim.v.shell_error ~= 0 then
                return make_response("error", string.format("Git %s failed: %s", action, output))
            end
            return make_response("success", string.format("Git %s executed: %s", action, output))
        end,
    },
    system_prompt = [[
You are a specialized Git assistant for Neovim, designed to safely and flexibly execute Git commands.

Core Tasks:
1. Accept a Git `action` (e.g., commit, push, pull, checkout, merge) and optional `extra_args` array.
2. Construct the command as: `git <action> <extra_args...>`.
3. Execute the command and return structured feedback with success or error details.
4. Require user approval before execution when `require_approval_before` is enabled (default: true).
5. Provide clear, concise output suitable for interactive chat.

Functional Behavior:
- Validate inputs (action must be non-empty).
- Display the exact Git command to the user for confirmation.
- Return success/failure responses with full command output.
- Log execution traces for debugging.

Edge Cases:
- Reject empty or unsupported actions.
- Handle shell errors gracefully and return error messages.
- Allow arbitrary Git arguments via `extra_args` for advanced use cases (e.g., `--rebase`, `HEAD:refs/for/develop`).
- Respect user rejection or cancellation with clear feedback.

Interaction Style:
- Always show the constructed Git command before execution.
- Use structured responses: {status: "success"|"error", data: "<output>"}.
- Keep explanations concise, technical, and focused on Git workflow.

    ]],
    schema = {
        type = "function",
        ["function"] = {
            name = "git",
            description = "Run git commands with arbitrary arguments",
            parameters = {
                type = "object",
                properties = {
                    action = {
                        type = "string",
                        description = "The git action to perform (e.g. commit, push, pull, checkout)",
                        enum = {
                            "commit",
                            "push",
                            "pull",
                            "checkout",
                            "merge",
                            "rebase",
                            "stash",
                            "status",
                            "log",
                            "fetch",
                        },
                    },
                    extra_args = {
                        type = "array",
                        description = "Extra arguments for git command",
                        items = { type = "string" },
                    },
                },
                required = { "action" },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    opts = {
        require_approval_before = true,
    },
    handlers = {
        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        setup = function(self, meta)
            log:trace("[Git Tool] setup handler executed")
            -- 可以在这里动态扩展，比如未来要根据仓库状态调整 schema
        end,

        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        on_exit = function(self, meta)
            log:trace("[Git Tool] on_exit handler executed")
        end,
    },
    output = {
        ---提示用户确认执行的命令
        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string
        prompt = function(self, meta)
            local action = self.args.action or "unknown"
            local extra_args = self.args.extra_args or {}
            local cmd = { "git", action }
            vim.list_extend(cmd, extra_args)
            return string.format("Execute command:\n`%s`\nConfirm?", table.concat(cmd, " "))
        end,

        ---成功输出
        ---@param self CodeCompanion.Tool.Git
        ---@param stdout string
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        success = function(self, stdout, meta)
            local chat = meta.tools.chat
            return chat:add_tool_output(self, stdout, "Executed git command successfully")
        end,

        ---错误输出
        ---@param self CodeCompanion.Tool.Git
        ---@param stderr string
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        error = function(self, stderr, meta)
            local chat = meta.tools.chat
            return chat:add_tool_output(self, stderr, "Git command failed")
        end,

        ---用户拒绝
        rejected = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user rejected execution of the git command")
        end,

        ---用户取消
        cancelled = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user cancelled execution of the git command")
        end,
    },
}
