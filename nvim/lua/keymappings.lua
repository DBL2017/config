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

-- nvim-tree
map("n","<F2>",":NvimTreeToggle<CR>",opt)
