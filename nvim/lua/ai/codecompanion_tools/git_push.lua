local log = require("codecompanion.utils.log")
return {
    name = "git_push",
    cmds = {
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param args table
        ---@param input? any
        function(self, args, opts)
            local args = args or {}
            -- Default values if not provided
            local remote = args.remote or "origin"
            local branch = args.branch or "main"

            local output = vim.fn.system({ "git", "push", remote, branch })
            if vim.v.shell_error ~= 0 then
                return { status = "error", content = "Git push failed:\n" .. output }
            end
            return { status = "success", content = "Git push executed:\n" .. output }
        end,
    },
    system_prompt = [[
You are a Git version control assistant. When pushing changes:

- Ensure the local branch is up to date with the remote
- Validate the Git repository exists before attempting pushes
- Handle errors gracefully and provide detailed feedback
- Confirm any required authentication (e.g., SSH key, credentials)

For git_push specifically:
- Return meaningful success/failure messages
- Output the actual Git command result to the user
    ]],
    schema = {
        type = "function",
        ["function"] = {
            name = "git_push",
            description = "Git push",
            parameters = {
                type = "object",
                properties = {
                    remote = {
                        type = "string",
                        description = "The remote repository name (e.g., origin)",
                        default = "origin",
                    },
                    branch = {
                        type = "string",
                        description = "The branch to push (e.g., main)",
                        default = "main",
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
            return string.format("Perform the git push to `%s/%s`?", self.args.remote, self.args.branch)
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
