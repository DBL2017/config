local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("default", { clear = true })

-- 重新打开缓冲区恢复光标位置
autocmd("BufReadPost", {
    pattern = "*",
    group = group,
    callback = function()
        if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.fn.setpos(".", vim.fn.getpos("'\""))
        end
    end,
    desc = "自动恢复光标位置",
})

--- 关闭新行注释
autocmd({
    "BufEnter",
}, {
    pattern = "*",
    callback = function()
        vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
    end,
    desc = "关闭新行注释",
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
                -- vim.api.nvim_win_set_cursor(win, { 4, #line_text + 1 })
                -- vim.api.nvim_feedkeys("a", "n", false) -- 进入插入模式
            end
        end
    else
        -- 直接跳转到末尾
        -- vim.api.nvim_feedkeys("a", "n", false) -- 进入插入模式
        return
    end
end
-- 创建.h文件时根据模板填充
autocmd("BufNewFile", {
    pattern = { "*" },
    group = group,
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
    desc = "自动填充文件模版",
})

-- 光标设置
local function hiCursor()
    vim.api.nvim_set_hl(0, "Cursor", { reverse = true, fg = "NONE", bg = "NONE" })
    vim.api.nvim_set_hl(0, "CursorReset", { fg = "white", bg = "white" })
end

autocmd("ColorScheme", {
    pattern = "*",
    group = group,
    callback = hiCursor,
    desc = "光标设置",
})
local function resetHi()
    vim.opt.guicursor = "a:block-CursorReset,a:blinkon150" -- 退出时设置
end

autocmd({ "VimLeave" }, {
    pattern = "*",
    group = group,
    callback = resetHi,
    desc = "退出时自动恢复光标",
})

-- 基于文件类型设置是否将tab转为space，以及tab的占位符大小
autocmd("FileType", {
    pattern = {
        "cpp",
        "c",
    },
    group = group,
    callback = function()
        -- tab转空格
        vim.bo.expandtab = false
        -- tab占位符的宽度，不修改键入tab时的行为，可用来格式化对齐
        vim.o.tabstop = 8
        -- 键入tab时插入的空格数
        vim.o.softtabstop = 4
        vim.bo.softtabstop = 4
        -- 由于tabstop==4，即tab占用4个字符长度；softtabstop==4，因此键入tab时插入4个空格。
        -- 如果expandtab==true, tabstop==8 and softtabstop==4，那么第一次键入tab会插入4个空格，第二次键入tab继续插入4个空格。
        -- 如果expandtab==false, tabstop==8 and softtabstop==4，那么第一次键入tab会插入4个空格，第二次键入tab会替换之前空格为tab键（8）。
        -- 上面这些仅在行内生效，行首会被当作缩进处理，受限于shiftwidth的配置
        -- 在行首键入tab时会受到shiftwidth的影响
        -- 缩进时的空格数量
        vim.o.shiftwidth = 4
    end,
    desc = "C[PP]设置Tab不转空格，宽度为8",
})

-- 在 treesitter-context 设置后添加
-- 解决切换tab时nvim-treesitter-context失效的问题
vim.api.nvim_create_autocmd({
    "TabEnter",
    "BufEnter",
    "WinEnter",
    -- "CursorMoved",
    -- "CursorMovedI",
}, {
    pattern = "*",
    group = group,
    callback = function()
        local ok, ctx = pcall(require, "treesitter-context")
        if ok then
            ctx.enable()
        end
    end,
    desc = "刷新 Treesitter 上下文",
})

-- 解决启动terminal之后，:wqa进程阻止退出的问题
-- E948: Job still running
-- E676: No matching autocommands for buftype= buffer
-- Press ENTER or type command to continue
vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
        local ok, terms = pcall(require, "toggleterm.terminal")
        if ok then
            for _, term in pairs(terms.get_all()) do
                term:shutdown()
            end
        end
    end,
    desc = "退出前自动清理terminal",
})

-- 当前nvim打开之前已经打开的文件时，会提示警告swap文件已存在并跳过
-- 原始实现见下面的文件
-- :lua print(vim.env.VIMRUNTIME)
-- $VIMRUNTIME/lua/vim/_defaults.lua
vim.api.nvim_create_autocmd("SwapExists", {
    group = group,
    callback = function()
        local choice = vim.fn.confirm(
            "Swap file exists!\nHow do you want to proceed?",
            "&Open Read Only\n&Delete Swap and Edit\n&Quit",
            1
        )

        if choice == 1 then
            -- 只读模式打开
            vim.v.swapchoice = "o"
        elseif choice == 2 then
            -- 删除交换文件
            local swapfile = vim.v.swapname
            local ok, err = pcall(os.remove, swapfile)
            if ok then
                -- 删除成功，正常编辑
                vim.v.swapchoice = "e"
            else
                -- 删除失败，降级为只读模式
                vim.notify("Failed to delete swap file: " .. err, vim.log.levels.WARN)
                vim.v.swapchoice = "o"
            end
        else
            -- 退出
            vim.v.swapchoice = "q"
        end
    end,
    desc = "阻止重复编辑文件，支持删除交换文件后编辑",
})

-- 删除会话时进行通知
vim.api.nvim_create_autocmd("User", {
    pattern = "PersistedDeletePost",
    group = group,
    callback = function(event)
        vim.notify("Session `" .. event.data.path .. "` deleted")
    end,
    desc = "删除会话时给出提示",
})
