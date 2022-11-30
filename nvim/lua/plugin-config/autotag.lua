-- 判断autotag插件是否被安装
local installStatus = pcall(require, "nvim-ts-autotag")

if installStatus then
	require("nvim-ts-autotag").setup({
		filetypes = { "html", "xml" },
	})
else
	vim.notify("没有找到nvim-ts-autotag")
	return
end
