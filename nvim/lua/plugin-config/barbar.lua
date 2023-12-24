local installStatus = pcall(require, "barbar")

if installStatus then
    require("barbar").setup({
        insert_at_end = false,
        insert_at_start = false,
    })
else
    vim.notify("没有找到barbar")
    return
end
