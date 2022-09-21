local opt = {
    noremap = true,
    silent = true
}
local map = vim.api.nvim_set_keymap

-- 切换标签页
map("n","<S-Left>",":tabp<CR>",opt)
map("n","<S-Right>",":tabn<CR>",opt)
map("v","<S-Left>",":tabp<CR>",opt)
map("v","<S-Right>",":tabn<CR>",opt)

-- 重定向退出键
map("n", "<leader>q", ":q!<CR>", opt)
map("v", "<leader>q", ":q!<CR>", opt)
map("n", "<leader>qa", ":qa!<CR>", opt)
map("v", "<leader>qa", ":qa!<CR>", opt)

-- nvim-tree
map("n","<F2>",":NvimTreeToggle<CR>",opt)

-- telescope
-- " Find files using Telescope command-line sugar.
map("n", "<leader>ff", ":Telescope find_files<CR>", opt)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opt)
map("n", "<leader>fb", ":Telescope buffers<CR>", opt)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opt)

-- formatter
map('n', "<leader>cf", ":FormatWrite<CR>", opt)
