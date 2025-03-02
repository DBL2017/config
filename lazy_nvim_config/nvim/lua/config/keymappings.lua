local opts = {
    noremap = true,
    silent = true,
}
local map = vim.api.nvim_set_keymap

-- 设置toggleterm的快捷键，使其能够在打开终端的情况下切换到其他窗口
function _G.set_terminal_keymaps()
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = 0 })
    vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = 0 })
    -- 有些终端模拟器上，<Backspace>按键会发送0x08，与<C-h>一致，下面的映射就可能导致<BS>失效，需要修改终端模拟对<BS>的配置
    vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { buffer = 0 })
end

function SaveAllAndQuit()
    -- wirte all buffers first
    vim.api.nvim_command(":wa")
    -- quit all buffers
    vim.api.nvim_command(":qa")
end

map("n", "<Leader>wq", "<Cmd>lua SaveAllAndQuit()<CR>", opts)
map("v", "<Leader>wq", "<Cmd>lua SaveAllAndQuit()<CR>", opts)

-- 指定类型终端
map("n", "<C-G>", "<cmd>TermExec cmd='git status ./' name=GIT<CR>", opts)

-- tab快捷键
-- Move to previous/next
map("n", "<A-,>", "<Cmd>tabprevious<CR>", opts)
map("n", "<A-.>", "<Cmd>tabnext<CR>", opts)
-- Re-order to previous/next
map("n", "<A-Left>", "<cmd>-tabmove<CR>", opts)
map("n", "<A-Right>", "<cmd>+tabmove<CR>", opts)
-- Close buffer
map("n", "<A-c>", "<Cmd>tabclose<CR>", opts)
map("t", "<A-c>", "<Cmd>q!<CR>", opts)
-- tab
map("n", "<leader>ta", "<cmd>$tabnew<CR>", opts)
map("n", "<leader>tc", "<cmd>tabclose<CR>", opts)
map("n", "<leader>to", "<cmd>tabonly<CR>", opts)
map("n", "<leader>tn", "<cmd>tabn<CR>", opts)
map("n", "<leader>tp", "<cmd>tabp<CR>", opts)
map("n", "<A-0>", "<cmd>tablast<CR>", opts)
map("n", "<A-1>", "<cmd>tabnext 1<CR>", opts)
map("n", "<A-2>", "<cmd>tabnext 2<CR>", opts)
map("n", "<A-3>", "<cmd>tabnext 3<CR>", opts)
map("n", "<A-4>", "<cmd>tabnext 4<CR>", opts)
map("n", "<A-5>", "<cmd>tabnext 5<CR>", opts)
map("n", "<A-6>", "<cmd>tabnext 6<CR>", opts)
map("n", "<A-7>", "<cmd>tabnext 7<CR>", opts)
map("n", "<A-8>", "<cmd>tabnext 8<CR>", opts)
map("n", "<A-9>", "<cmd>tabnext 9<CR>", opts)

-- 禁用方向键
map("n", "<Left>", "<NOP>", opts)
map("n", "<Right>", "<NOP>", opts)
map("n", "<Up>", "<NOP>", opts)
map("n", "<Down>", "<NOP>", opts)

-- 调整窗口小
map("n", "<C-Up>", "<cmd>resize -1<CR>", opts)
map("n", "<C-Down>", "<cmd>resize +1<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -3<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +3<CR>", opts)

-- 重定向退出键
map("n", "<leader>q", "<cmd>q!<CR>", opts)
map("v", "<leader>q", "<cmd>q!<CR>", opts)
map("n", "<leader>w", "<cmd>w<CR>", opts)
map("v", "<leader>w", "<cmd>w<CR>", opts)
map("n", "<leader>qa", "<cmd>qa!<CR>", opts)
map("v", "<leader>qa", "<cmd>qa!<CR>", opts)

-- nvim-tree
map("n", "<F2>", "<cmd>NvimTreeToggle<CR>", opts)
-- lspsaga
map("n", "<F12>", "<cmd>Lspsaga outline<CR>", opts)
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
map("n", "pd", "<cmd>Lspsaga peek_definition<CR>", opts)
map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)

-- FzfLua
map("n", "fgd", "<cmd>FzfLua lsp_definitions<CR>", opts)
map("n", "fgD", "<cmd>FzfLua lsp_declarations<CR>", opts)
map("n", "flr", "<cmd>FzfLua lsp_references<CR>", opts)
map("n", "flf", "<cmd>FzfLua lsp_finder<CR>", opts)
map("n", "fli", "<cmd>FzfLua lsp_implementations<CR>", opts)
map("n", "flt", "<cmd>FzfLua lsp_typedefs<CR>", opts)
map("n", "fca", "<cmd>FzfLua code_action<CR>", opts)

map("n", "fgc", "<cmd>FzfLua git_commits<CR>", opts)
map("n", "fgb", "<cmd>FzfLua git_bcommits<CR>", opts)
map("n", "fgr", "<cmd>FzfLua grep_cword<CR>", opts)

-- telescope
-- " Find files using Telescope command-line sugar.
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts)
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)

-- formatter
-- map("n", "<leader>cf", "<cmd>FormatWrite<CR>", opts)

-- trouble
-- diagnostic键映射
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", opts)
map("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics toggle<cr>", opts)
map("n", "<leader>xd", "<cmd>Trouble document_diagnostics toggle<cr>", opts)
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", opts)
map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", opts)
map("n", "gR", "<cmd>Trouble lsp_references toggle<cr>", opts)

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- 自动将查找到的字符串设置到屏幕中央
map("n", "n", "nzz", { noremap = true, silent = true })
map("n", "N", "Nzz", { noremap = true, silent = true })

-- 将单行内选中的字符串当作文件打开
local function get_visual_selection()
    -- 获取当前选中的文本
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local line = vim.fn.getline(start_pos[2])
    if start_pos[2] ~= end_pos[2] then
        vim.notify("selection spans multiple lines", vim.log.levels.WARN)
        return nil
    end
    return line:sub(start_pos[3], end_pos[3]):gsub("^%s*(.-)%s*$", "%1")
end
function open_selected_file()
    local filename = get_visual_selection()
    if filename ~= nil and #filename > 0 then
        vim.cmd("tabnew " .. filename)
    end
end
-- 将函数映射到快捷键 <leader>gf
map("v", "<leader>of", ":lua open_selected_file() <CR>", { noremap = true, silent = true })
-- 将单行内选中的字符串当作文件打开
--
map("n", "<space>f", ':lua require("conform").format() <CR>', { noremap = true, silent = true })
map("v", "<space>f", ':lua require("conform").format() <CR>', { noremap = true, silent = true })

-- 复制内容并附加文件名与行号
local function copy_with_metadata()
    local buf_name = vim.fn.expand("%:t") -- 获取当前文件名（不含路径）
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
-- 绑定快捷键 (Ctrl+Alt+c)
-- "x"在 Neovim 键位映射中表示可视模式（Visual Mode）涵盖以下操作场景：
-- 通过 v 进入的字符选择模式
-- 通过 V 进入的行选择模式
-- 通过 Ctrl+v 进入的块选择模式
vim.keymap.set({ "n", "x" }, "<Leader>yy", copy_with_metadata, {
    desc = "复制带文件名和行号的内容",
})

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
    local sha = blame_line:sub(1, 7)

    vim.fn.setreg("+", sha)
    -- vim.notify("Copied SHA: " .. sha, vim.log.levels.INFO)
    return sha
end

vim.keymap.set("n", "<Leader>yc", get_line_commit, { desc = "Get line commit SHA" })

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
vim.keymap.set("n", "<Leader>gd", git_diff_with_commit_sha, {
    desc = "Diff current line's Git commit",
})
