return {
    "nvim-lua/plenary.nvim",
    -- 主动安装master分支最新提交，用以解决CodeCompanion流式HTTP请求无法处理回调的问题
    -- https://github.com/nvim-lua/plenary.nvim/pull/557
    branch = "master",
    lazy = false,
}
