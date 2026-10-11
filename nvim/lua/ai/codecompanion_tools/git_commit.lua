local log = require("codecompanion.utils.log")
return {
    name = "git_commit",
    cmds = {
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param args table
        ---@param input? any
        function(self, args, opts)
            local args = args or {}
            if not args.message or args.message == "" then
                return { status = "error", data = "message is not empty" }
            end

            local output = vim.fn.system({ "git", "commit", "-m", args.message })
            if vim.v.shell_error ~= 0 then
                return { status = "error", content = "Git commit failed:\n" .. output }
            end
            return { status = "success", content = "Git commit executed:\n" .. output }
        end,
    },
    system_prompt = [[
You are a Git version control assistant. When making commits:

- Ensure commits are atomic and focused
- Write clear, concise commit messages in the imperative mood
- Follow conventional commit format if applicable (e.g. "fix:", "feat:")
- Validate the Git repository exists before attempting commits
- Handle errors gracefully and provide detailed feedback

For git_commit specifically:
- Require a non-empty commit message parameter
- Return meaningful success/failure messages
- Output the actual Git command result to the user
    ]],
    schema = {
        type = "function",
        ["function"] = {
            name = "git_commit",
            description = "Git commit",
            parameters = {
                type = "object",
                properties = {
                    message = {
                        type = "string",
                        description = "The commit message for git",
                    },
                },
            },
        },
    },
    handlers = {
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param meta { tools: CodeCompanion.Tools }
        setup = function(self, meta)
            log:trace("[Git Commit Tool] setup handler executed")
        end,

        ---@param self CodeCompanion.Tool.GetChangedFiles
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return nil
        on_exit = function(self, meta)
            log:trace("[Git Commit Tool] on_exit handler executed")
        end,
    },
    output = {
        ---The message which is shared with the user when asking for their approval
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string
        prompt = function(self, meta)
            return string.format("Perform the git commit `%s`?", self.args.message)
        end,
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param stdout table
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        success = function(self, stdout, meta)
            local chat = meta.tools.chat
            local output = vim.iter(stdout):flatten():join("\n")
            return chat:add_tool_output(self, output, "Executed git commit successfully")
        end,
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param stderr table The error output from the command
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        error = function(self, stderr, meta)
            local chat = meta.tools.chat
            local errors = vim.iter(stderr):flatten():join("\n")
            return chat:add_tool_output(self, errors, "Git commit failed")
        end,

        ---Rejection message back to the LLM
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param meta { tools: CodeCompanion.Tools, cmd: table, opts: table }
        ---@return nil
        rejected = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user rejected to run the git commit tool")
        end,

        ---Cancellation message back to the LLM
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        ---@return nil
        cancelled = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user cancelled the execution of the git commit tool")
        end,
    },
    opts = {
        require_approval_before = true,
        -- 让后台 LLM 在 auto 模式下判断本次 commit 是否安全
        judge = true,
        -- 提交操作会修改提交历史，视为受保护，auto 模式下也默认询问
        protect = true,
    },
    gates = {
        ---@param self CodeCompanion.Tool.Git_Commit
        ---@return boolean commit 是写操作，不接受自动放行
        is_safe = function(self)
            return false
        end,

        ---@param self CodeCompanion.Tool.Git_Commit
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string 交给后台 judge 判断的上下文
        judge_context = function(self, meta)
            return string.format("Run the git commit: %s", self.args.message)
        end,
    },
}
