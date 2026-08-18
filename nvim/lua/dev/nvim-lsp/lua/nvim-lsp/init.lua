local config = require("nvim-lsp.config")
local lsp = require("nvim-lsp.lsp")

local M = {}

function M.setup(opts)
    config.setup(opts)
    -- 注册命令
    vim.api.nvim_create_user_command("LspAttachBuffer", function()
        lsp.attach_buffer()
    end, {})

    vim.api.nvim_create_user_command("LspDetachBuffer", function()
        lsp.detach_current()
    end, {})

    vim.api.nvim_create_user_command("LspAttachAll", function()
        lsp.attach_all()
    end, {})

    vim.api.nvim_create_user_command("LspDetachAll", function()
        lsp.detach_all()
    end, {})

    vim.api.nvim_create_user_command("LspDetachOthers", function()
        lsp.detach_all()
    end, {})
    -- 自动命令：在 BufRead 或 BufNewFile 时自动附加 LSP
    if config.options.auto_attach then
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            callback = function(args)
                lsp.attach_buffer(args.buf)
            end,
        })
    end
end

return M
