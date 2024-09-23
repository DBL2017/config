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

map('n', '<Leader>wq', "<Cmd>lua SaveAllAndQuit()<CR>", opts)
map('v', '<Leader>wq', "<Cmd>lua SaveAllAndQuit()<CR>", opts)

-- 指定类型终端
map("n", "<C-G>", "<cmd>TermExec cmd='git status ./' name=GIT<CR>", opts)

-- barbar快捷键
-- Move to previous/next
map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
map("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)
-- Re-order to previous/next
map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts)
map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", opts)
-- Goto buffer in position...
map("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", opts)
map("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", opts)
map("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", opts)
map("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", opts)
map("n", "<A-5>", "<Cmd>BufferGoto 5<CR>", opts)
map("n", "<A-6>", "<Cmd>BufferGoto 6<CR>", opts)
map("n", "<A-7>", "<Cmd>BufferGoto 7<CR>", opts)
map("n", "<A-8>", "<Cmd>BufferGoto 8<CR>", opts)
map("n", "<A-9>", "<Cmd>BufferGoto 9<CR>", opts)
map("n", "<A-0>", "<Cmd>BufferLast<CR>", opts)
-- Pin/unpin buffer
map("n", "<A-p>", "<Cmd>BufferPin<CR>", opts)
-- Close buffer
map("n", "<A-c>", "<Cmd>BufferClose<CR>", opts)
map("t", "<A-c>", "<Cmd>q!<CR>", opts)
-- tab
map("n", "<leader>ta", "<cmd>$tabnew<CR>", opts)
map("n", "<leader>tc", "<cmd>tabclose<CR>", opts)
map("n", "<leader>to", "<cmd>tabonly<CR>", opts)
map("n", "<leader>tn", "<cmd>tabn<CR>", opts)
map("n", "<leader>tp", "<cmd>tabp<CR>", opts)
-- move current tab to previous position
map("n", "<leader>tmp", "<cmd>-tabmove<CR>", opts)
-- move current tab to next position
map("n", "<leader>tmn", "<cmd>+tabmove<CR>", opts)

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

-- FzfLua
map("n", "fgd", "<cmd>FzfLua lsp_definitions<CR>", opts)
map("n", "fgD", "<cmd>FzfLua lsp_declarations<CR>", opts)
map("n", "flr", "<cmd>FzfLua lsp_references<CR>", opts)
map("n", "flf", "<cmd>FzfLua lsp_finder<CR>", opts)
map("n", "fli", "<cmd>FzfLua lsp_implementations<CR>", opts)
map("n", "flt", "<cmd>FzfLua lsp_typedefs<CR>", opts)

map("n", "fgc", "<cmd>FzfLua git_commits<CR>", opts)

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
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", opts)
map("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics toggle<cr>", opts)
map("n", "<leader>xd", "<cmd>Trouble document_diagnostics toggle<cr>", opts)
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", opts)
map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", opts)
map("n", "gR", "<cmd>Trouble lsp_references toggle<cr>", opts)

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)
