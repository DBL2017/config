local installStatus = pcall(require, "neon")

if installStatus == false then
    vim.inspect("没有找到theme neon")
    return
end
--
-- default doom dark light
vim.g.neon_style = "dark"
vim.g.neon_italic_keyword = true
vim.g.neon_italic_function = true
vim.g.neon_transparent = true

vim.cmd({ cmd = "colorscheme", args = { "neon" } })
