local installStatus = pcall(require, "cmp-npm")

if installStatus then
    require("cmp-npm").setup({})
else
    vim.notify("没有找到cmp")
    return
end
