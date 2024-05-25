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

-- 指定类型终端
map("n", "<C-G>", ":TermExec cmd='git status ./' name=GIT<CR>", opts)

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

-- 禁用方向键
map("n", "<Left>", "<NOP>", opts)
map("n", "<Right>", "<NOP>", opts)
map("n", "<Up>", "<NOP>", opts)
map("n", "<Down>", "<NOP>", opts)

-- 调整窗口小
map("n", "<C-Up>", ":resize -1<CR>", opts)
map("n", "<C-Down>", ":resize +1<CR>", opts)
map("n", "<C-Left>", ":vertical resize -3<CR>", opts)
map("n", "<C-Right>", ":vertical resize +3<CR>", opts)

-- 重定向退出键
map("n", "<leader>q", ":q!<CR>", opts)
map("v", "<leader>q", ":q!<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)
map("v", "<leader>w", ":w<CR>", opts)
map("n", "<leader>qa", ":qa!<CR>", opts)
map("v", "<leader>qa", ":qa!<CR>", opts)

-- nvim-tree
map("n", "<F2>", ":NvimTreeToggle<CR>", opts)
map("n", "<F12>", ":SymbolsOutline<CR>", opts)

-- telescope
-- " Find files using Telescope command-line sugar.
map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fr", ":Telescope oldfiles<CR>", opts)
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
map("n", "<leader>fb", ":Telescope buffers<CR>", opts)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opts)

-- formatter
-- map("n", "<leader>cf", ":FormatWrite<CR>", opts)

-- trouble
-- diagnostic键映射
map("n", "<leader>xx", "<cmd>TroubleToggle<cr>", opts)
map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", opts)
map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", opts)
map("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", opts)
map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", opts)
map("n", "gR", "<cmd>TroubleToggle lsp_references<cr>", opts)

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
-- vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)
