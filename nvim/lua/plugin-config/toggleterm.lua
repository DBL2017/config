local installStatus = pcall(require, "toggleterm")
if installStatus == false then
    vim.notify("没有找到toggleterm")
    return
end

require("toggleterm").setup({
    open_mapping = [[<c-\>]],
    -- 打开新终端后自动进入插入模式
    start_in_insert = true,
    -- 在当前buffer的下方打开新终端
    direction = 'horizontal'
})
