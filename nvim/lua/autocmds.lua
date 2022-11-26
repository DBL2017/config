local autocmd = vim.api.nvim_create_autocmd

-- 自动保存编辑的缓冲区

-- 重新打开缓冲区恢复光标位置
autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.fn.setpos(".", vim.fn.getpos("'\""))
            vim.cmd("silent! foldopen")
        end
    end,
})

-- 关闭新行注释
autocmd({
    "BufEnter",
}, {
    pattern = "*",
    callback = function()
        -- vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
    end,
})

-- 写入代码自动格式化
-- autocmd({
--     "BufWritePost",
-- }, {
--     pattern = "*",
--     callback = function() vim.cmd({ cmd = "FormatWrite" }) end,
-- })

--[[ -- 写入代码自动格式化
-- autocmd({
--     "InsertLeave",
-- }, {
--     pattern = "*",
--     callback = function() require("lint").try_lint() end,
-- }) ]]

-- 支持输入法切换
if vim.fn.has("linux") == 1 then
    local reservedIM1 = "xkb:us::eng"
    local reservedIM2 = "xkb:us::eng"
    autocmd({ "InsertEnter", "VimLeave" }, {
        callback = function()
            reservedIM1 = vim.trim(vim.fn.system("ibus engine"))
            if reservedIM2 then vim.trim(vim.fn.system("ibus engine " .. reservedIM2)) end
        end,
    })
    autocmd({ "InsertLeave", "VimEnter" }, {
        callback = function()
            reservedIM2 = vim.trim(vim.fn.system("ibus engine"))
            if reservedIM1 then vim.trim(vim.fn.system("ibus engine " .. reservedIM1)) end
        end,
    })
end
