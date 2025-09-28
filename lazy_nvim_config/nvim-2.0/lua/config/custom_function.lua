M = {}

local function copy_current_filepath()
    local file_path = vim.api.nvim_buf_get_name(0)
    local dir_path = vim.fn.fnamemodify(file_path, ":h")
    -- local dir_name = vim.fn.fnamemodify(dir_path, ":t")
    vim.notify("Copied " .. dir_path)

    -- 写入系统剪贴板
    vim.fn.setreg("+", dir_path)
    if vim.fn.has("mac") == 1 then
        vim.fn.system("pbcopy", dir_path)
    else
        vim.fn.system("xclip -sel clipboard", dir_path) -- Linux/WSL
    end
end

M.copy_current_filepath = copy_current_filepath

-- 获取当前行的commit
local function get_line_commit()
    -- 检查是否在Git仓库
    if vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null") ~= "true\n" then
        vim.notify("Not in Git repository", vim.log.levels.ERROR)
        return
    end

    local filename = vim.fn.expand("%")
    local line_num = vim.fn.line(".")

    -- 使用更可靠的porcelain格式
    local blame_output =
        vim.fn.systemlist(string.format("git blame -L %d,%d --porcelain -- %s", line_num, line_num, filename))

    if #blame_output == 0 then
        vim.notify("Failed to get commit info", vim.log.levels.WARN)
        return
    end

    -- 修复1：获取列表第一项
    local blame_line = blame_output[1]
    if not blame_line then
        vim.notify("Empty blame output", vim.log.levels.WARN)
        return
    end

    -- 修复2：增加SHA格式校验
    local sha = blame_line:match("^%x+")
    if not sha or #sha ~= 40 or sha:match("^0+$") then
        vim.notify("Invalid commit SHA", vim.log.levels.WARN)
        return
    end

    -- 提取7位完整SHA
    sha = blame_line:sub(1, 7)

    vim.fn.setreg("+", sha)
    -- vim.notify("Copied SHA: " .. sha, vim.log.levels.INFO)
    return sha
end

M.get_line_commit = get_line_commit

-- 对比当前行所在的commit与当前文件的差异
local function git_diff_with_commit_sha()
    -- 获取当前文件 Git Blame 信息
    local gitsigns = require("gitsigns")
    local sha = get_line_commit()
    if sha then
        -- 调用 Gitsigns 对比当前文件与该 Commit 的差异
        gitsigns.diffthis(sha)
        vim.notify("Diff with commit: " .. sha, vim.log.levels.INFO)
        return
    end
    vim.notify("No Git commit found for this line.", vim.log.levels.WARN)
end

M.git_diff_with_commit_sha = git_diff_with_commit_sha

-- 复制内容并附加文件名与行号
local function copy_with_metadata(is_full_path)
    local buf_name = is_full_path and vim.fn.expand("%:p") or vim.fn.expand("%:t") -- 获取当前文件名（不含路径）
    local lines = {}

    -- 获取选区行号范围
    local start_line, end_line
    if vim.fn.mode() == "V" then -- 可视行模式
        start_line = vim.fn.line("v")
        end_line = vim.fn.line(".")
    else -- 普通模式（单行）
        start_line = vim.fn.line(".")
        end_line = start_line
    end

    -- 确保行号顺序正确
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    -- 提取文本并添加元数据
    local content = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    for i, line in ipairs(content) do
        local line_num = start_line + i - 1
        table.insert(
            lines,
            -- 多行保持格式，单行去掉行首空白字符
            string.format("%s:[%d]:%s", buf_name, line_num, start_line ~= end_line and line or line:gsub("^%s+", ""))
        )
    end
    -- 写入系统剪贴板
    local joined = table.concat(lines, "\n")
    vim.fn.setreg("+", joined)
    if vim.fn.has("mac") == 1 then
        vim.fn.system("pbcopy", joined)
    else
        vim.fn.system("xclip -sel clipboard", joined) -- Linux/WSL
    end
    -- 如果是可视模式，退出
    if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
        vim.api.nvim_input("<Esc>") -- 发送退出信号
    end
end

M.copy_with_metadata = copy_with_metadata

-- 将单行内选中的字符串当作文件打开
local function get_visual_selection()
    -- 获取当前选中的文本
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    -- vim.notify("start_pos" .. start_pos[3] .. "end_pos" .. end_pos[3])
    -- local line = vim.fn.getline(start_pos[2])
    -- if start_pos[2] ~= end_pos[2] then
    --     vim.notify("selection spans multiple lines", vim.log.levels.WARN)
    --     return nil
    -- end
    -- return line:sub(start_pos[3], end_pos[3]):gsub("^%s*(.-)%s*$", "%1")
    --
    -- 通过寄存器捕获选中内容
    -- 解决选取标记失效问题
    vim.cmd('normal! "zy') -- 将选区内容存入 z 寄存器
    return vim.fn.getreg("z"):gsub("^%s*(.-)%s*$", "%1")
end
local function open_selected_file()
    local filename = get_visual_selection()
    if filename ~= nil and #filename > 0 then
        vim.cmd("tabnew " .. filename)
        vim.notify("Open " .. filename)
    end
end

M.open_selected_file = open_selected_file

-- diagnosic jump
local function diagnostics_goto_prev()
    vim.diagnostic.jump({
        count = -1,
        float = true,
        wrap = false,
        severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
    })
end
local function diagnostics_goto_next()
    vim.diagnostic.jump({
        count = 1,
        float = true,
        wrap = false,
        severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
    })
end
M.diagnostic_goto_prev = diagnostics_goto_prev
M.diagnostic_goto_next = diagnostics_goto_next

return M
