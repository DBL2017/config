return {
    "nvim-telescope/telescope.nvim",
    -- module: 当指定时，lazy.nvim 会在第一次 require("telescope.builtin") 时加载该插件。
    -- 作用: 通过 module 延迟加载插件，只有在真正调用其模块时才进行加载，从而提高启动速度。
    -- 取值范围: 字符串（模块名）或 nil。
    -- 当前取值含义: "telescope.builtin" -> 只有调用 require('telescope.builtin') 或其子模块时才会加载 telescope 插件。
    module = "telescope.builtin",
    cmd = { "Telescope" },
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    pin = true,
    event = "VeryLazy",
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
                    -- 预览内容一次滚动5行，默认为半屏
                    scroll_speed = 5,
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
            extensions = {
                frecency = {
                    auto_validate = false,
                    matcher = "fuzzy",
                    path_display = { "filename_first" },
                },
            },
        })
    end,
}
