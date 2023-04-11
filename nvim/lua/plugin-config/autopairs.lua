-- 判断autopairs插件是否被安装
local installStatus = pcall(require, "nvim-autopairs")

if installStatus then
    require("nvim-autopairs").setup({
        disable_filetype = { "TelescopePrompt", "vim" },
    })
else
    vim.notify("没有找到nvim-autopairs")
    return
end
