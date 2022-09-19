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
map("n", "<leader>q", ":qa!<CR>", opt)
map("v", "<leader>q", ":qa!<CR>", opt)

-- nvim-tree
map("n","<F2>",":NvimTreeToggle<CR>",opt)

-- telescope
-- " Find files using Telescope command-line sugar.
map("n", "<leader>ff", ":Telescope find_files<CR>", opt)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opt)
map("n", "<leader>fb", ":Telescope buffers<CR>", opt)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opt)

--[[ " Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr> ]]
