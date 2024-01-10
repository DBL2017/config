local autocmd = vim.api.nvim_create_autocmd

-- 自动保存编辑的缓冲区

-- 重新打开缓冲区恢复光标位置
autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.fn.setpos(".", vim.fn.getpos("'\""))
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

-- 进入term时设置快捷键
autocmd({ "TermOpen" }, { command = "lua set_terminal_keymaps()" })


-- 光标设置
local function hiCursor()
    vim.api.nvim_set_hl(0, "Cursor", { fg = '#cc9900', bg = '#339966' })
    vim.api.nvim_set_hl(0, "CursorReset", { fg = 'white', bg = 'white' })
end

autocmd("ColorScheme", {
    pattern = "*",
    callback = hiCursor,
})
local function resetHi()
    vim.opt.guicursor = 'a:block-CursorReset,a:blinkon150' -- 退出时设置
end

autocmd({ "VimLeave" }, {
    pattern = "*",
    callback = resetHi
})

-- 支持输入法切换
-- if vim.fn.has("linux") == 1 then
--     local reservedIM1 = "xkb:us::eng"
--     local reservedIM2 = "xkb:us::eng"
--     autocmd({ "InsertEnter" }, {
--         pattern = "*",
--         callback = function()
--             reservedIM1 = vim.trim(vim.fn.system("ibus engine"))
--             -- print(reservedIM1,reservedIM2)
--             if reservedIM2 then
--                 vim.trim(vim.fn.system("ibus engine " .. reservedIM2))
--             end
--         end,
--     })
--     autocmd({ "InsertLeave" }, {
--         pattern = "*",
--         callback = function()
--             reservedIM2 = vim.trim(vim.fn.system("ibus engine"))
--             -- print(reservedIM1,reservedIM2)
--             if reservedIM1 then
--                 vim.trim(vim.fn.system("ibus engine " .. reservedIM1))
--             end
--         end,
--     })
-- end
