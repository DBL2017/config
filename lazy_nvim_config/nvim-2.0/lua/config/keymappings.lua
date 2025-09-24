----------------------------------------------------------Basic-------------------------------------------------------------
local custom_function = require("config.custom_function")
local custom_comment = require("config.custom_comment")

function save_all_and_quit()
    -- wirte all buffers first
    vim.api.nvim_command(":wa")
    -- quit all buffers
    vim.api.nvim_command(":qa")
end
vim.keymap.set({ "n", "v" }, "<LocalLeader>wq", "<cmd>lua save_all_and_quit()<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>q", "<cmd>q!<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>w", "<cmd>w<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>qa", "<cmd>qa!<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-q>", "<cmd>q!<CR>", { silent = true })

-- 查找
-- 自动将查找到的字符串设置到屏幕中央
vim.keymap.set("n", "n", "nzz", { silent = true })
vim.keymap.set("n", "N", "Nzz", { silent = true })

-- 将单行内选中的字符串当作文件打开
vim.keymap.set("v", "<LocalLeader>of", custom_function.open_selected_file, { desc = "Open file" })

-- 扩展复制
vim.keymap.set({ "n", "x" }, "<LocalLeader>yy", custom_function.copy_with_metadata, {
    desc = "复制带文件名和行号的内容",
})
vim.keymap.set({ "n", "x" }, "<LocalLeader>yf", function()
    custom_function.copy_with_metadata(true)
end, {
    desc = "Copy with filename and linenu",
})
-- 获取当前文件所在的路径名
vim.keymap.set("n", "<LocalLeader>yp", custom_function.copy_current_filepath, {
    desc = "Copy current file path",
})
-- 拷贝当前行的commit sha
vim.keymap.set("n", "<LocalLeader>yc", custom_function.get_line_commit, { desc = "Get line commit SHA" })

-- 对比当前行的commit与当前buffer的文件差异
vim.keymap.set("n", "<LocalLeader>gd", custom_function.git_diff_with_commit_sha, {
    desc = "Diff current line's Git commit",
})

-- 普通模式下在当前位置插入时间
vim.keymap.set("n", "<LocalLeader>ti", "i<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})
-- 普通模式下在下一行插入时间
vim.keymap.set("n", "<LocalLeader>to", "o<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})
-- 普通模式下在上一行插入时间
vim.keymap.set("n", "<LocalLeader>tO", "O<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})

-- 在当前函数上方插入注释
vim.keymap.set("n", "<LocalLeader>fO", function()
    local ok, err = pcall(custom_comment.insert_comment, "function")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end)
-- 在当前变量上方插入注释
vim.keymap.set("n", "<LocalLeader>vO", function()
    local ok, err = pcall(custom_comment.insert_comment, "variable")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end)
-- 在当前宏上方插入注释
vim.keymap.set("n", "<LocalLeader>mO", function()
    local ok, err = pcall(custom_comment.insert_comment, "macro")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end)

-- 原生lsp
vim.keymap.set("n", "<LocalLeader>lr", function()
    vim.lsp.buf.references()
end, {
    silent = true,
    desc = "lsp_reference",
})

-- tab快捷键
-- Move to previous/next
vim.keymap.set("n", "<A-,>", "<cmd>tabprevious<CR>", { silent = true, desc = "tabprevious" })
vim.keymap.set("n", "<A-.>", "<cmd>tabnext<CR>", { silent = true, desc = "tabnext" })
-- Re-order to previous/next
vim.keymap.set("n", "<A-Left>", "<cmd>-tabmove<CR>", { silent = true, desc = "-tabmove" })
vim.keymap.set("n", "<A-Right>", "<cmd>+tabmove<CR>", { silent = true, desc = "+tabmove" })
-- Close buffer
vim.keymap.set("n", "<A-c>", "<cmd>tabclose<CR>", { silent = true, desc = "tabclose" })
vim.keymap.set("t", "<A-c>", "<cmd>q!<CR>", { silent = true, desc = "q!" })
-- tab
vim.keymap.set("n", "<LocalLeader>ta", "<cmd>$tabnew<CR>", { silent = true, desc = "$tabnew" })
vim.keymap.set("n", "<LocalLeader>tc", "<cmd>tabclose<CR>", { silent = true, desc = "tabclose" })
vim.keymap.set("n", "<LocalLeader>to", "<cmd>tabonly<CR>", { silent = true, desc = "tabonly" })
vim.keymap.set("n", "<LocalLeader>tn", "<cmd>tabn<CR>", { silent = true, desc = "tabn" })
vim.keymap.set("n", "<LocalLeader>tp", "<cmd>tabp<CR>", { silent = true, desc = "tabp" })
vim.keymap.set("n", "<A-0>", "<cmd>tablast<CR>", { silent = true, desc = "tablast" })
vim.keymap.set("n", "<A-1>", "<cmd>tabnext 1<CR>", { silent = true, desc = "tabnext 1" })
vim.keymap.set("n", "<A-2>", "<cmd>tabnext 2<CR>", { silent = true, desc = "tabnext 2" })
vim.keymap.set("n", "<A-3>", "<cmd>tabnext 3<CR>", { silent = true, desc = "tabnext 3" })
vim.keymap.set("n", "<A-4>", "<cmd>tabnext 4<CR>", { silent = true, desc = "tabnext 4" })
vim.keymap.set("n", "<A-5>", "<cmd>tabnext 5<CR>", { silent = true, desc = "tabnext 5" })
vim.keymap.set("n", "<A-6>", "<cmd>tabnext 6<CR>", { silent = true, desc = "tabnext 6" })
vim.keymap.set("n", "<A-7>", "<cmd>tabnext 7<CR>", { silent = true, desc = "tabnext 7" })
vim.keymap.set("n", "<A-8>", "<cmd>tabnext 8<CR>", { silent = true, desc = "tabnext 8" })
vim.keymap.set("n", "<A-9>", "<cmd>tabnext 9<CR>", { silent = true, desc = "tabnext 9" })

-- 禁用方向键
-- vim.keymap.set("n", "<Left>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Right>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Up>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Down>", "<NOP>", {silent=true,desc=""})

-- 调整窗口小
vim.keymap.set("n", "<C-Up>", "<cmd>resize -1<CR>", { silent = true, desc = "resize -1" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize +1<CR>", { silent = true, desc = "resize +1" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -3<CR>", { silent = true, desc = "vertical resize -3" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +3<CR>", { silent = true, desc = "vertical resize +3" })

-- diagnostics
-- 2. 优化 float 窗口打开行为（通过自定义函数封装）
local function open_optimized_diagnostic_float()
    vim.diagnostic.config({
        virtual_lines = false,
    })
    vim.diagnostic.open_float({
        -- 可选：限制窗口最大宽度/高度
        max_width = math.floor(vim.o.columns * 0.5), -- 最大宽度为屏幕50%
        max_height = math.floor(vim.o.lines * 0.4), -- 最大高度为屏幕40%
    })
end
vim.keymap.set("n", "<space>e", open_optimized_diagnostic_float, { desc = "Open optimized diagnostics" })
-- vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, {silent=true, desc=""})
vim.keymap.set("n", "[d", custom_function.diagnostic_goto_prev, { silent = true, desc = "" })
vim.keymap.set("n", "]d", custom_function.diagnostic_goto_next, { silent = true, desc = "" })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { silent = true, desc = "" })

----------------------------------------------------------Plugins-------------------------------------------------------------
-- nvim-ufo
-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
-- vim.keymap.set("n", "zR", require("ufo").openAllFolds, { silent = true, desc = "Open all folds" })
-- vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { silent = true, desc = "Close all folds" })

-- 格式化
vim.keymap.set({ "n", "v" }, "<space>f", require("conform").format, { desc = "Format current buffer" })

-- 文件树
vim.keymap.set({ "n", "v", "i" }, "<F2>", "<cmd>NvimTreeToggle<CR>", { desc = "Open file explore" })

-- CodeCompanion
vim.keymap.set({ "n", "v" }, "<LocalLeader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>at", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])
vim.keymap.set({ "v" }, "<LocalLeader>ae", function()
    require("codecompanion").prompt("explain_in_chinese")
end, { noremap = true, silent = true })

-- telescope
-- " Find files using Telescope command-line sugar.
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
vim.keymap.set("n", "tfr", function()
    require("telescope.builtin").find_files()
end, { silent = true, desc = "Search for files" })

vim.keymap.set("n", "tfr", function()
    require("telescope.builtin").oldfiles()
end, { silent = true, desc = "Lists previously open files" })

vim.keymap.set("n", "tfh", function()
    require("telescope.builtin").help_tags()
end, { silent = true, desc = "Lists available help tags" })

vim.keymap.set("n", "tfg", function()
    require("telescope.builtin").live_grep({ cwd = vim.fn.expand("%:p:h") })
end, { silent = true, desc = "Search for a string and get results live as you type" })

vim.keymap.set("n", "tfb", function()
    require("telescope.builtin").buffers()
end, { silent = true, desc = "Lists open buffers in current neovim instance" })

vim.keymap.set("n", "tgd", function()
    require("telescope.builtin").lsp_definitions()
end, { silent = true, desc = "Goto the definition of the word under the cursor" })

vim.keymap.set("n", "tlr", function()
    require("telescope.builtin").lsp_references()
end, { silent = true, desc = "Lists LSP references for word under the cursor" })

-- FzfLua
vim.keymap.set("n", "fgd", "<cmd>FzfLua lsp_definitions<CR>", { silent = true, desc = "Definitions" })
vim.keymap.set("n", "fgD", "<cmd>FzfLua lsp_declarations<CR>", { silent = true, desc = "Declarations" })
vim.keymap.set("n", "flr", "<cmd>FzfLua lsp_references<CR>", { silent = true, desc = "References" })
vim.keymap.set("n", "flf", "<cmd>FzfLua lsp_finder<CR>", { silent = true, desc = "All lsp locations" })
vim.keymap.set("n", "fli", "<cmd>FzfLua lsp_implementations<CR>", { silent = true, desc = "Implementations" })
vim.keymap.set("n", "flt", "<cmd>FzfLua lsp_typedefs<CR>", { silent = true, desc = "Type definitions" })
vim.keymap.set("n", "fca", "<cmd>FzfLua code_action<CR>", { silent = true, desc = "Code actions" })

vim.keymap.set("n", "fgc", "<cmd>FzfLua git_commits<CR>", { silent = true, desc = "Git commit log(project)" })
vim.keymap.set("n", "fgb", "<cmd>FzfLua git_bcommits<CR>", { silent = true, desc = "Git commit log(buffer)" })
vim.keymap.set("n", "fgr", "<cmd>FzfLua grep_cword<CR>", { silent = true, desc = "Search word under cursor" })

-- Outline
vim.keymap.set("n", "<F12>", "<cmd>Outline<CR>", { silent = true, desc = "Toggle outline" })

-- Toggleterm
-- 设置toggleterm的快捷键，使其能够在打开终端的情况下切换到其他窗口
function _G.set_terminal_keymaps()
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = 0 })
    vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = 0 })
    -- 有些终端模拟器上，<Backspace>按键会发送0x08，与<C-h>一致，下面的映射就可能导致<BS>失效，需要修改终端模拟对<BS>的配置
    vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { buffer = 0 })
end

-- Trouble
-- diagnostic键映射
vim.keymap.set(
    "n",
    "<LocalLeader>xx",
    "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
    { silent = true, desc = "Trouble diagnostic toggle" }
)
vim.keymap.set("n", "<LocalLeader>xw", "<cmd>Trouble workspace_diagnostics toggle<cr>", { silent = true, desc = "" })
vim.keymap.set("n", "<LocalLeader>xd", "<cmd>Trouble document_diagnostics toggle<cr>", { silent = true, desc = "" })
vim.keymap.set("n", "<LocalLeader>xl", "<cmd>Trouble loclist toggle<cr>", { silent = true, desc = "" })
vim.keymap.set("n", "<LocalLeader>xq", "<cmd>Trouble quickfix toggle<cr>", { silent = true, desc = "" })
vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<cr>", { silent = true, desc = "" })

-- lspsaga
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true, desc = "Lspsaga hover" })
vim.keymap.set("n", "pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true, desc = "Lspsaga peek_definition" })
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true, desc = "Lspsaga code actions" })
