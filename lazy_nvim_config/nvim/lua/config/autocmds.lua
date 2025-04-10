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

local function fill_template(template_path, replacements)
    -- 检查模板文件是否存在
    if vim.fn.filereadable(template_path) == 0 then
        vim.notify("模板文件不存在: " .. template_path, vim.log.levels.WARN)
        return
    end

    -- 读取模板文件内容
    local template = table.concat(vim.fn.readfile(template_path), "\n")

    -- 替换占位符
    for placeholder, value in pairs(replacements) do
        template = template:gsub(placeholder, value)
    end

    -- 插入到新文件中
    vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
end
-- 创建.h文件时根据模板填充
autocmd("BufNewFile", {
    pattern = { "*.h", "*.c" },
    callback = function()
        local filename = vim.fn.expand("%:t")
        -- local date = os.date("%Y-%m-%d")
        local date = os.date("%d%b%y")
        local guard = string.format("__%s_H_", vim.fn.expand("%:t:r"):upper())
        local header = filename:gsub("%.c$", ".h")

        local replacements = {
            ["%%FILE%%"] = filename,
            ["%%DATE%%"] = date,
            ["%%GUARD%%"] = guard,
            ["%%HEADER%%"] = header,
        }

        local template_path
        if vim.fn.expand("%:e") == "h" then
            template_path = vim.fn.expand("~/.config/nvim/templates/c_header")
        elseif vim.fn.expand("%:e") == "c" then
            template_path = vim.fn.expand("~/.config/nvim/templates/c_source")
        else
            vim.notify("不支持的文件类型", vim.log.levels.INFO)
            return
        end

        fill_template(template_path, replacements)
    end,
})

-- 进入term时设置快捷键
autocmd({ "TermOpen" }, { command = "lua set_terminal_keymaps()" })

-- 光标设置
local function hiCursor()
    vim.api.nvim_set_hl(0, "Cursor", { reverse = true, fg = "NONE", bg = "NONE" })
    vim.api.nvim_set_hl(0, "CursorReset", { fg = "white", bg = "white" })
end

autocmd("ColorScheme", {
    pattern = "*",
    callback = hiCursor,
})
local function resetHi()
    vim.opt.guicursor = "a:block-CursorReset,a:blinkon150" -- 退出时设置
end

autocmd({ "VimLeave" }, {
    pattern = "*",
    callback = resetHi,
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

-- 根据上下文中的tab和空格数目决定是否启用tab转空格
autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
        local line_num = vim.fn.line(".")
        local start_line = math.max(1, line_num - 1)
        local line = vim.fn.getline(start_line)
        if line:match("^\t") then
            vim.bo.expandtab = false
        elseif line:match("^ ") then
            vim.bo.expandtab = true
        else
            vim.bo.expandtab = false
        end
        -- local end_line = math.min(vim.fn.line("$"), line_num + 10)
        -- local tab_count = 0
        -- local space_count = 0
        --
        -- for i = start_line, end_line do
        --     if i ~= line_num then
        --         local line = vim.fn.getline(i)
        --         if line:match("^\t") then
        --             tab_count = tab_count + 1
        --         elseif line:match("^ ") then
        --             space_count = space_count + 1
        --         else
        --         end
        --     end
        -- end
        --
        -- if tab_count > space_count then
        --     vim.bo.expandtab = false
        -- else
        --     vim.bo.expandtab = true
        -- end
    end,
})
