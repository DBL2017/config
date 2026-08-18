return {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text" },
    init = function()
        vim.g.bullets_enabled_file_types = {
            "markdown",
            "text",
        }

        vim.g.bullets_set_mappings = 1
        vim.g.bullets_auto_initiate = 1
        vim.g.bullets_enable_indent = 1

        -- ✅ 正确：编号层级规则（重点）
        vim.g.bullets_outline_levels = {
            "num", -- 1. 2. 3.
            "abc", -- a. b. c.
            "rom", -- i. ii. iii.
            "std-", -- -
        }

        -- 分隔符（统一控制 . 或 )
        vim.g.bullets_delimiter = "."

        vim.g.bullets_checkbox_markers = " x"
    end,
}
