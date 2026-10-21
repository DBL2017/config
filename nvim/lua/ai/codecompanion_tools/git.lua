local log = require("codecompanion.utils.log")

local function find_repository_root(path)
    if path == "" or vim.fn.filereadable(path) == 0 then
        return nil
    end

    local git_path = vim.fs.find(".git", {
        path = vim.fs.dirname(path),
        upward = true,
    })[1]

    if git_path then
        return vim.fs.dirname(git_path)
    end

    return nil
end

local function get_repository_root()
    local buffer_names = {
        vim.api.nvim_buf_get_name(0),
    }

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) then
            table.insert(buffer_names, vim.api.nvim_buf_get_name(buffer))
        end
    end

    for _, buffer_name in ipairs(buffer_names) do
        local repository_root = find_repository_root(buffer_name)
        if repository_root then
            return repository_root
        end
    end

    local output = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 and output[1] and output[1] ~= "" then
        return vim.trim(output[1])
    end

    return nil
end

local function make_response(status, msg)
    return { status = status, content = msg }
end

return {
    name = "git",
    cmds = {
        ---@param self CodeCompanion.Tool.Git
        ---@param args table
        function(self, args, opts)
            local action = args.action

            if not action or action == "" then
                return make_response("error", "Git action is required")
            end

            local repository_root = get_repository_root()
            if not repository_root then
                return make_response(
                    "error",
                    "Git repository could not be located from the current buffer or cwd"
                )
            end

            local cmd = { "git", "-C", repository_root }

            if action == "commit" then
                if not args.message or args.message == "" then
                    return make_response("error", "Commit message is required")
                end

                cmd = {
                    "git",
                    "-C",
                    repository_root,
                    "commit",
                    "-m",
                    args.message,
                }
            else
                table.insert(cmd, action)
                vim.list_extend(cmd, args.extra_args or {})
            end

            local output = vim.fn.system(cmd)
            local exit_code = vim.v.shell_error

            if exit_code ~= 0 then
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
                        enum = {
                            "commit",
                            "diff",
                            "push",
                            "pull",
                            "checkout",
                            "merge",
                            "rebase",
                            "stash",
                            "status",
                            "log",
                            "fetch",
                            "remote",
                        },
                    },
                    message = {
                        type = "string",
                    },
                    extra_args = {
                        type = "array",
                        items = {
                            type = "string",
                        },
                    },
                },
                required = {
                    "action",
                },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    opts = {
        require_approval_before = true,
        -- 按具体命令逐个审批（auto 模式不会整体放行，需先经 is_safe/judge 判定）
        require_cmd_approval = true,
        -- 让后台 LLM 在 auto 模式下判断非只读的 git 命令是否安全
        judge = true,
    },
    gates = {
        ---@param self CodeCompanion.Tool.Git
        ---@return boolean 只读且安全的命令在 auto 模式下直接放行
        is_safe = function(self)
            local read_only = { status = true, diff = true, log = true, fetch = true, remote = true }
            return read_only[self.args.action] == true
        end,

        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string 交给后台 judge 判断的上下文
        judge_context = function(self, meta)
            local cmd = { "git", self.args.action }
            vim.list_extend(cmd, self.args.extra_args or {})
            return string.format("Run the git command: %s", table.concat(cmd, " "))
        end,
    },
    handlers = {
        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        setup = function(self, meta)
            log:trace("[Git Tool] setup handler executed")
        end,

        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        on_exit = function(self, meta)
            log:trace("[Git Tool] on_exit handler executed")
        end,
    },
    output = {
        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string 实际执行的命令，用于按命令审批缓存
        cmd_string = function(self, meta)
            local action = self.args.action or "unknown"
            local repository_root = get_repository_root() or "<repository-root>"
            local cmd = { "git", "-C", repository_root, action }
            if action == "commit" then
                cmd = {
                    "git",
                    "-C",
                    repository_root,
                    action,
                    "-m",
                    self.args.message or "",
                }
            else
                vim.list_extend(cmd, self.args.extra_args or {})
            end
            return table.concat(cmd, " ")
        end,

        ---提示用户确认执行的命令
        ---@param self CodeCompanion.Tool.Git
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string
        prompt = function(self, meta)
            local action = self.args.action or "unknown"
            local extra_args = self.args.extra_args or {}
            local repository_root = get_repository_root() or "<repository-root>"
            local cmd = { "git", "-C", repository_root, action }

            if action == "commit" then
                if not self.args.message or self.args.message == "" then
                    return "Commit message is required for git commit. Please provide a message."
                end
                cmd = {
                    "git",
                    "-C",
                    repository_root,
                    action,
                    "-m",
                    self.args.message,
                }
            else
                vim.list_extend(cmd, extra_args)
            end
            return string.format("Execute command:\n`%s`\nConfirm?", table.concat(cmd, " "))
        end,

        ---成功输出
        ---@param self CodeCompanion.Tool.Git
        ---@param stdout string
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        success = function(self, stdout, meta)
            local chat = meta.tools.chat
            local output = vim.iter(stdout):flatten():join("\n")
            return chat:add_tool_output(self, output, "Executed git command successfully")
        end,

        ---错误输出
        ---@param self CodeCompanion.Tool.Git
        ---@param stderr string
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        error = function(self, stderr, meta)
            local chat = meta.tools.chat
            local errors = vim.iter(stderr):flatten():join("\n")
            return chat:add_tool_output(self, errors, "Git command failed")
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
