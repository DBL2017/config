require("telescope").setup({
    defaults = {
        -- 打开弹窗后进入的初始模式，默认为 insert，也可以是 normal
        initial_mode = "insert",
        -- vertical , center , cursor
        layout_strategy = "horizontal",
        -- 窗口内快捷键
        -- mappings = require("keybindings").telescopeList,
        mappings = {
            i = {
                ["<esc>"] = require("telescope.actions").close,
            },
        },

        layout_config = {
            vertical = { width = 0.5, height = 0.85 },
            -- cursor = {width = 0.7, height = 0.55}
        },
    },
    pickers = {
        find_files = {
            -- theme = "dropdown", -- 可选参数： dropdown, cursor, ivy
        },
    },
    extensions = {},
})
