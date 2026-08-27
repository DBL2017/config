local log = require("codecompanion.utils.log")
return {
    name = "git_push",
    cmds = {
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param args table
        ---@param input? any
        function(self, args, opts)
            local args = args or {}

            -- If push_args is provided, use it directly
            if args.push_args and args.push_args ~= "" then
                local output = vim.fn.system({ "git", "push", args.push_args })
                if vim.v.shell_error ~= 0 then
                    return { status = "error", content = "Git push failed:\n" .. output }
                end
                return { status = "success", content = "Git push executed:\n" .. output }
            end

            -- Get current branch if not provided
            local branch
            if args.branch and args.branch ~= "" then
                branch = args.branch
            else
                local branch_output = vim.fn.systemlist("git branch --show-current")
                if vim.v.shell_error ~= 0 or not branch_output[1] then
                    return { status = "error", content = "Failed to detect current branch" }
                end
                branch = branch_output[1]
            end

            -- Get current remote if not provided
            local remote
            if args.remote and args.remote ~= "" then
                remote = args.remote
            else
                local remote_output = vim.fn.systemlist("git remote")
                if vim.v.shell_error ~= 0 or not remote_output[1] then
                    return { status = "error", content = "Failed to detect current remote" }
                end
                remote = remote_output[1]
            end

            local output = vim.fn.system({ "git", "push", remote, branch })
            if vim.v.shell_error ~= 0 then
                return { status = "error", content = "Git push failed:\n" .. output }
            end
            return { status = "success", content = "Git push executed:\n" .. output }
        end,
    },
    system_prompt = [[
You are a Git version control assistant. When pushing changes:

- If `push_args` is provided (e.g., `HEAD:refs/for/main`), use it directly for Gerrit-style pushes.
- Otherwise, detect the current branch and use "github" as the default remote.
- Handle errors gracefully and provide detailed feedback.

For git_push specifically:
- Return meaningful success/failure messages.
- Output the actual Git command result to the user.
    ]],
    schema = {
        type = "function",
        ["function"] = {
            name = "git_push",
            description = "Git push with support for custom push targets (e.g., Gerrit)",
            parameters = {
                type = "object",
                properties = {
                    remote = {
                        type = "string",
                        description = "The remote repository name (e.g., github). Defaults to 'github' if not provided.",
                        default = "github",
                    },
                    branch = {
                        type = "string",
                        description = "The branch to push. If not provided, automatically detects the current branch.",
                    },
                    push_args = {
                        type = "string",
                        description = "Custom push target (e.g., HEAD:refs/for/main). Overrides remote/branch if provided.",
                    },
                },
            },
        },
    },
    handlers = {
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools }
        setup = function(self, meta)
            log:trace("[Git Push Tool] setup handler executed")
        end,

        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return nil
        on_exit = function(self, meta)
            log:trace("[Git Push Tool] on_exit handler executed")
        end,
    },
    output = {
        ---The message which is shared with the user when asking for their approval
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools }
        ---@return string
        prompt = function(self, meta)
            if self.args.push_args then
                return string.format("Push to custom target:\n`%s`\nConfirm?", self.args.push_args)
            else
                return string.format(
                    "Push to `%s/%s`? (Auto-detected branch)",
                    self.args.remote or "origin",
                    self.args.branch or "main"
                )
            end
        end,

        ---@param self CodeCompanion.Tool.Git_Push
        ---@param stdout table
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        success = function(self, stdout, meta)
            local chat = meta.tools.chat
            local output = vim.iter(stdout):flatten():join("\n")
            return chat:add_tool_output(self, output, "Executing git push")
        end,
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param stderr table The error output from the command
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        error = function(self, stderr, meta)
            local chat = meta.tools.chat
            local errors = vim.iter(stderr):flatten():join("\n")
            return chat:add_tool_output(self, errors)
        end,

        ---Rejection message back to the LLM
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools, cmd: table, opts: table }
        ---@return nil
        rejected = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user declined to run the git push tool")
        end,

        ---Cancellation message back to the LLM
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        ---@return nil
        cancelled = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user cancelled the execution of the git push tool")
        end,
    },
    opts = {
        require_approval_before = true,
    },
}
