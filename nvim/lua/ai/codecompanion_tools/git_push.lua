local log = require("codecompanion.utils.log")
--- Get list of git remotes
---@return string[]|nil
local function get_git_remotes()
    local remotes = vim.fn.systemlist("git remote")
    if vim.v.shell_error ~= 0 or not remotes[1] then
        log:error("Failed to detect git remotes")
        return nil
    end
    return remotes
end
local function make_response(status, msg)
    return { status = status, data = msg }
end
return {
    name = "git_push",
    cmds = {
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param args table
        ---@param input? any
        function(self, args, opts)
            local args = args or {}

            -- Get current branch if not provided
            local branch
            if args.branch and args.branch ~= "" then
                branch = args.branch
            end

            -- Get current remote if not provided
            local remote
            if args.remote and args.remote ~= "" then
                remote = args.remote
            end

            if remote and branch and remote ~= "" and branch ~= "" then
                local output = vim.fn.system({ "git", "push", remote, branch })
                if vim.v.shell_error ~= 0 then
                    return make_response("error", string.format("Git push failed: %s", output))
                end
                return make_response("error", string.format("Git push executed: %s", output))
            else
                return make_response(
                    "error",
                    string.format("Git push with invalid remote: %s branch: %s", remote, branch)
                )
            end
        end,
    },
    system_prompt = [[
You are a specialized Git push assistant for Neovim, designed to safely and efficiently push changes to remote repositories.

Core Tasks:
1. Automatically detect the current branch and default remote ("github" or other specified).
2. Support both direct branch pushes (`remote/branch`) and custom push targets (e.g., `HEAD:refs/for/main`).
3. Execute `git push` with validation of remote and branch inputs.
4. Handle errors and provide structured feedback with Git command output.
5. Require user approval before execution when `require_approval_before` is enabled (default: true).

Functional Behavior:
- Validate inputs (remote must exist; branch must be non-empty).
- Display the exact Git command to the user for confirmation.
- Return success/failure responses with full output/error details.
- Log execution traces for debugging.

Edge Cases:
- Reject invalid remote/branch combinations.
- Handle detached HEAD state (not supported; warn user).
- Gracefully exit on user rejection/cancellation.
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
                        description = "The remote repository name.",
                        enum = get_git_remotes(),
                    },
                    branch = {
                        type = "string",
                        description = "The branch to push.",
                    },
                },
                required = { "remote", "branch" },
                additionalProperties = false,
            },
            strict = true,
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
                    self.args.remote or "github",
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
            return chat:add_tool_output(self, output, "Executed git push successfully")
        end,
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param stderr table The error output from the command
        ---@param meta { tools: CodeCompanion.Tools, cmd: table }
        error = function(self, stderr, meta)
            local chat = meta.tools.chat
            local errors = vim.iter(stderr):flatten():join("\n")
            chat:add_tool_output(self, errors)
            errors = vim.iter(stdout):flatten():join("\n")
            return chat:add_tool_output(self, errors)
        end,

        ---Rejection message back to the LLM
        ---@param self CodeCompanion.Tool.Git_Push
        ---@param meta { tools: CodeCompanion.Tools, cmd: table, opts: table }
        ---@return nil
        rejected = function(self, meta)
            meta.tools.chat:add_tool_output(self, "The user reject to run the git push tool")
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
