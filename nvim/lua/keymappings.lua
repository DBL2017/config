local opt = {
    noremap = true,
    silent = true
}
local map = vim.api.nvim_set_keymap

-- 切换标签页
map("n","<S-Left>","gt<CR>",opt)
map("n","<S-Right>","gt<CR>",opt)
map("v","<S-Left>","gt<CR>",opt)
map("v","<S-Right>","gt<CR>",opt)

-- nvim-tree
map("n","<F2>",":NvimTreeToggle<CR>",opt)
