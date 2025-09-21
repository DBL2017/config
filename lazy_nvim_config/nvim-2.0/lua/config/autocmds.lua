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
        vim.notify("Template file isn't existent." .. template_path, vim.log.levels.WARN)
        return
    end

    -- 读取模板文件内容
    local template = table.concat(vim.fn.readfile(template_path), "\n")

    -- 替换占位符
    for placeholder, value in pairs(replacements) do
        template = template:gsub(placeholder, value)
    end

    -- 插入到新文件中
    -- nvim_buf_set_lines(buffer, start_line, end_line, strict_indexing, replacement_lines)
    -- strict_indexing	布尔值	若为 true，行号越界时报错；若为 false，自动调整行号到有效范围。
    vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, 0, false, vim.split(template, "\n"))

    local filetype = vim.bo.filetype
    if filetype == "cpp" or filetype == "c" then
        -- 从开始位置查询brief并跳转到该位置，进入插入模式
        vim.fn.cursor(1, 1)
        local ok, result = pcall(vim.fn.search, "brief", "n") -- "n" 表示仅返回行号，不移动光标
        if ok then
            -- vim.notify("brief" .. result)
            local brief_line = result
            if brief_line > 0 then
                local win = vim.api.nvim_get_current_win()
                local line_text =
                    vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), brief_line - 1, brief_line, false)[1]
                -- vim.notify("line_text" .. line_text)
                vim.api.nvim_win_set_cursor(win, { 4, #line_text + 1 })
                vim.api.nvim_feedkeys("a", "n", false) -- 进入插入模式
            end
        end
    else
        -- 直接跳转到末尾
        vim.api.nvim_feedkeys("a", "n", false) -- 进入插入模式
        return
    end
end
-- 创建.h文件时根据模板填充
autocmd("BufNewFile", {
    pattern = { "*" },
    callback = function()
        local filename = vim.fn.expand("%:t")
        local filetype = vim.bo.filetype
        -- local date = os.date("%Y-%m-%d")
        local date = os.date("%d%b%y")

        local replacements = {
            ["%%FILE%%"] = filename,
            ["%%DATE%%"] = date,
        }

        local template_path
        if filetype == "cpp" then
            local guard = string.format("__%s_H_", vim.fn.expand("%:t:r"):upper())
            replacements["%%GUARD%%"] = guard
            template_path = vim.fn.expand("~/.config/nvim/templates/c/c_header")
        elseif filetype == "c" then
            local header = filename:gsub("%.c$", ".h")
            replacements["%%HEADER%%"] = header
            template_path = vim.fn.expand("~/.config/nvim/templates/c/c_source")
        elseif filetype == "make" then
            template_path = vim.fn.expand("~/.config/nvim/templates/makefile")
        else
            vim.notify("No avaliable template!", vim.log.levels.INFO)
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

