local opt = {
    noremap = true,
    silent = true,
}
local map = vim.api.nvim_set_keymap

-- 设置toggleterm的快捷键，使其能够在打开终端的情况下切换到其他窗口
function _G.set_terminal_keymaps()
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = 0 })
    vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = 0 })
    vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { buffer = 0 })
    vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { buffer = 0 })
end

-- 指定类型终端
map("n", "<C-G>", ":TermExec cmd='git status ./' name=GIT<CR>", opt)

-- 禁用方向键
map("n", "<Left>", "<NOP>", opt)
map("n", "<Right>", "<NOP>", opt)
map("n", "<Up>", "<NOP>", opt)
map("n", "<Down>", "<NOP>", opt)

-- 调整窗口小
map("n", "<C-Up>", ":resize -1<CR>", opt)
map("n", "<C-Down>", ":resize +1<CR>", opt)
map("n", "<C-Left>", ":vertical resize -3<CR>", opt)
map("n", "<C-Right>", ":vertical resize +3<CR>", opt)

-- 切换标签页
map("n", "<S-Left>", ":tabp<CR>", opt)
map("n", "<S-Right>", ":tabn<CR>", opt)
map("v", "<S-Left>", ":tabp<CR>", opt)
map("v", "<S-Right>", ":tabn<CR>", opt)

-- 重定向退出键
map("n", "<leader>q", ":q!<CR>", opt)
map("v", "<leader>q", ":q!<CR>", opt)
map("n", "<leader>w", ":w<CR>", opt)
map("v", "<leader>w", ":w<CR>", opt)
map("n", "<leader>qa", ":qa!<CR>", opt)
map("v", "<leader>qa", ":qa!<CR>", opt)

-- nvim-tree
map("n", "<F2>", ":NvimTreeToggle<CR>", opt)
map("n", "<F12>", ":SymbolsOutline<CR>", opt)

-- telescope
-- " Find files using Telescope command-line sugar.
map("n", "<leader>ff", ":Telescope find_files<CR>", opt)
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
map("n", "<leader>fg", ":Telescope live_grep<CR>", opt)
map("n", "<leader>fb", ":Telescope buffers<CR>", opt)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opt)

-- formatter
map("n", "<leader>cf", ":FormatWrite<CR>", opt)

-- trouble
-- diagnostic键映射
map("n", "<leader>xx", "<cmd>TroubleToggle<cr>", opt)
map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", opt)
map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", opt)
map("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", opt)
map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", opt)
map("n", "gR", "<cmd>TroubleToggle lsp_references<cr>", opt)

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opt)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opt)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opt)
-- vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opt)
