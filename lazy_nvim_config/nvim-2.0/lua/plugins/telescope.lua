return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    pin = true,
    config = function()
        require("telescope").setup({
            defaults = {
                -- 结果窗口的内容从窗口顶部开始
                sorting_strategy = "ascending",
                -- 打开弹窗后进入的初始模式，默认为 insert，也可以是 normal
                initial_mode = "normal",
                -- 窗口内快捷键
                -- mappings = require("keybindings").telescopeList,
                mappings = {
                    i = {
                        ["<C-q>"] = require("telescope.actions").close,
                        ["<S-Down>"] = require("telescope.actions").preview_scrolling_down,
                        ["<S-Up>"] = require("telescope.actions").preview_scrolling_up,
                    },
                    n = {
                        ["<C-q>"] = require("telescope.actions").close,
                        ["<S-Down>"] = require("telescope.actions").preview_scrolling_down,
                        ["<S-Up>"] = require("telescope.actions").preview_scrolling_up,
                    },
                },

                -- vertical , center、horizontal , cursor
                layout_strategy = "horizontal",
                layout_config = {
                    height = 0.99,
                    width = 0.99,
                    preview_width = 0.5, -- 预览窗口宽度比例（横向布局时生效）
                    preview_cutoff = 80, -- 预览窗口最小宽度（字符数），超过则自动隐藏
                    horizontal = { -- 横向布局时的专属配置
                        preview_width = 0.7,
                        prompt_position = "top",
                    },
                    vertical = { -- 纵向布局时的专属配置
                        preview_height = 0.6,
                    },
                },
            },
            pickers = {
                find_files = {
                    -- theme = "dropdown", -- 可选参数： dropdown, cursor, ivy
                },
            },
            extensions = {},
        })
    end,
}
