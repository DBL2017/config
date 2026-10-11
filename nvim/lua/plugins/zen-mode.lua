-- Lua
return {
    -- Zen Mode：通过隐藏编辑器周边干扰，提供更专注的写作/阅读界面。
    "folke/zen-mode.nvim",
    -- 只有执行 :ZenMode 时才加载插件，减少 Neovim 启动时的开销。
    cmd = "ZenMode",
    config = function()
        -- 配置 Zen Mode 的窗口样式，以及进入专注模式时需要临时调整的编辑器选项。
        require("zen-mode").setup({
            window = {
                -- 编辑区外背景的透明度；数值越大，背景越暗。
                backdrop = 0.2,
                -- 编辑区宽度占当前窗口的 80%；设置为 0 可让编辑区占满宽度。
                width = 0.8,
                -- 编辑区高度占当前窗口的 100%。
                height = 1,
                options = {
                    -- 保留 signcolumn，避免诊断、断点等标记导致文本左右跳动。
                    signcolumn = "yes",
                    -- 显示绝对行号。
                    number = true,
                    -- 不显示相对行号。
                    relativenumber = false,
                    -- 高亮当前行，便于定位光标所在位置。
                    cursorline = true,
                    -- 高亮当前列，便于阅读和对齐文本。
                    cursorcolumn = true,
                    -- 显示空白字符（例如 Tab 和行尾空格）。
                    list = true,
                },
            },

            plugins = {
                options = {
                    -- 允许 Zen Mode 临时调整下列 Neovim 界面选项。
                    enabled = true,
                    -- 隐藏光标所在位置的标尺信息。
                    ruler = false,
                    -- 保留命令执行提示。
                    showcmd = true,
                    -- 使用全局状态栏，而不是每个窗口各显示一个状态栏。
                    laststatus = 3,
                },
                -- TODO:
                todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
            },
        })
    end,
}
