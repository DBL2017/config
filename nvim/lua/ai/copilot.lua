return {
    "github/copilot.vim",
    cmd = "Copilot",
    init = function()
        vim.g.copilot_no_maps = true
        vim.g.conpilot_auto_enable = false
    end,
    config = function()
        -- Block the normal Copilot suggestions
        -- 不显示 Copilot 的默认建议
        vim.api.nvim_create_augroup("github_copilot", { clear = true })
        -- Create an autocommand to handle FileType and BufUnload events for Copilot
        if vim.g.conpilot_auto_enable then
            vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
                group = "github_copilot",
                callback = function(args)
                    vim.fn["copilot#On" .. args.event]()
                end,
            })
            vim.fn["copilot#OnFileType"]()
        end
    end,
}
