local autocmd = vim.api.nvim_create_autocmd

-- 自动保存编辑的缓冲区

-- 重新打开缓冲区恢复光标位置
autocmd("BufReadPost",{
    pattern = "*",
    callback = function()
        if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.fn.setpos(".", vim.fn.getpos("'\""))
            vim.cmd("silent! foldopen")
        end
    end
})

-- 关闭新行注释
autocmd({
    "BufEnter"
},{
    pattern = "*",
    callback = function()
        vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
    end
})
