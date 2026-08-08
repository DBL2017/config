local config = require("nvim-comment.config")
local comment = require("nvim-comment.comment")

local M = {}

function M.setup(opts)
    config.setup(opts)

    -- create a user command to generate comments: :NvimComment <kind>
    if vim.api and vim.api.nvim_create_user_command then
        vim.api.nvim_create_user_command("NvimComment", function(opts)
            local kind = opts.args or "function"
            comment.insert_comment(kind)
        end, {nargs = "?", complete = function(arglead, cmdline, cursorpos)
            return {"function", "variable", "macro"}
        end})

        -- alias
        vim.api.nvim_create_user_command("NvimCommentGenerate", function(opts)
            local kind = opts.args or "function"
            comment.insert_comment(kind)
        end, {nargs = "?", complete = function() return {"function", "variable", "macro"} end})
    end
end

return M
