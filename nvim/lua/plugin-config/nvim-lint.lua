local installStatus = pcall(require, "lint")

if installStatus then
    require("lint").linters_by_ft = {
        markdown = { "vale" },
        c = { "cpplint" },
    }
else
    vim.notify("没有找到nvim-lint")
    return
end
