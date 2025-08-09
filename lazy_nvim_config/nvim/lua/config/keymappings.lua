local custom = require("config.custom_function")
local conform = require("conform")

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
-- map("n", "<Left>", "<NOP>", opts)
-- map("n", "<Right>", "<NOP>", opts)
-- map("n", "<Up>", "<NOP>", opts)
-- map("n", "<Down>", "<NOP>", opts)

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

-- 2. 优化 float 窗口打开行为（通过自定义函数封装）
local function open_optimized_diagnostic_float()
    vim.diagnostic.open_float({
        -- 可选：限制窗口最大宽度/高度
        max_width = math.floor(vim.o.columns * 0.5), -- 最大宽度为屏幕50%
        max_height = math.floor(vim.o.lines * 0.4), -- 最大高度为屏幕40%
    })
end

-- 3. 绑定快捷键（例如 <leader>d 打开优化后的诊断窗口）
vim.keymap.set("n", "<space>e", open_optimized_diagnostic_float, { desc = "Open optimized diagnostics" })
vim.keymap.set("n", "[d", custom.diagnostic_goto_prev, opts)
vim.keymap.set("n", "]d", custom.diagnostic_goto_next, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- 自动将查找到的字符串设置到屏幕中央
map("n", "n", "nzz", { noremap = true, silent = true })
map("n", "N", "Nzz", { noremap = true, silent = true })

-- 将单行内选中的字符串当作文件打开
vim.keymap.set("v", "<leader>of", custom.open_selected_file, { desc = "Open file" })

-- 格式化
vim.keymap.set({ "n", "x" }, "<space>f", conform.format, { desc = "Format current buffer" })

-- 绑定快捷键 (Ctrl+Alt+c)
-- "x"在 Neovim 键位映射中表示可视模式（Visual Mode）涵盖以下操作场景：
-- 通过 v 进入的字符选择模式
-- 通过 V 进入的行选择模式
-- 通过 Ctrl+v 进入的块选择模式
vim.keymap.set({ "n", "x" }, "<Leader>yy", custom.copy_with_metadata, {
    desc = "复制带文件名和行号的内容",
})
vim.keymap.set({ "n", "x" }, "<Leader>yf", function()
    custom.copy_with_metadata(true)
end, {
    desc = "复制带文件名和行号的内容",
})
-- 拷贝当前行的commit sha
vim.keymap.set("n", "<Leader>yc", custom.get_line_commit, { desc = "Get line commit SHA" })
-- 对比当前行的commit与当前buffer的文件差异
vim.keymap.set("n", "<Leader>gd", custom.git_diff_with_commit_sha, {
    desc = "Diff current line's Git commit",
})
-- 获取当前文件所在的路径名
vim.keymap.set("n", "<Leader>yp", custom.copy_current_filepath, {
    desc = "Copy current file path",
})

-- 普通模式下在当前位置插入时间
vim.keymap.set("n", "<leader>ti", "i<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})
-- 普通模式下在下一行插入时间
vim.keymap.set("n", "<leader>to", "o<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})
-- 普通模式下在上一行插入时间
vim.keymap.set("n", "<leader>tO", "O<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
