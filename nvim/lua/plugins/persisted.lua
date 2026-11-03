return -- Lua
{
    "DBL2017/persisted.nvim",
    lazy = false,
    opts = {
        use_git_branch = true,
        telescope = {
            mappings = { -- Mappings for managing sessions in Telescope
                copy_session = "<A-c>",
                change_branch = "<A-b>",
                delete_session = "<A-d>",
            },
        },
    },
    config = function(_, opts)
        local persisted = require("persisted")
        persisted.branch = function()
            local branch = vim.fn.systemlist("git branch --show-current")[1]
            return vim.v.shell_error == 0 and branch or nil
        end
        persisted.setup(opts)
    end,
}
