local opt = {
    noremap = true,
    silent = true
}
local map = vim.api.nvim_set_keymap

-- 切换标签页
map("n","<S-Left>","gt",opt)
map("n","<S-Right>","gt",opt)
map("v","<S-Left>","gt",opt)
map("v","<S-Right>","gt",opt)

-- nvim-tree
map("n","<F2>",":NvimTreeToggle<CR>",opt)
