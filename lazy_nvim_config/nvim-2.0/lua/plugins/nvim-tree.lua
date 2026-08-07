-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
return {
    "kyazdani42/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    cmd = {
        "NvimTreeOpen",
        "NvimTreeToggle",
    },
    tag = "v1.14.0",
    config = function()
        require("nvim-tree").setup({
            -- 激活buf时重新加载文件树
            reload_on_bufenter = true,

            -- 光标在文件名的第一个字母
            hijack_cursor = true,
            select_prompts = true,

            sort = {
                -- Can be one of `"name"`, `"case_sensitive"`, `"modification_time"`, `"extension"`,
                sorter = "case_sensitive",
            },
            view = {
                side = "left",
                width = 30,
                number = true,
            },
            renderer = {
                group_empty = true,
                --[[ 浮动窗口显示全名 ]]
                full_name = true,
                hidden_display = "none",
                -- root_folder_label = ":p",
                highlight_git = "all",
                highlight_diagnostics = "all",
                highlight_opened_files = "all",
                highlight_modified = "all",
                highlight_bookmarks = "all",
                highlight_clipboard = "name",
                indent_markers = {
                    enable = true,
                    inline_arrows = true,
                    icons = {
                        corner = "└",
                        edge = "│",
                        item = "│",
                        bottom = "─",
                        none = " ",
                    },
                },
                --[[ 使用图标的前提是要修复相应字体中的图标，可以安装nerd-font ]]
                icons = {
                    --[[ git标志位置: after, before, signcolumn ]]
                    git_placement = "signcolumn",
                },
            },
            filters = {
                enable = true,
                git_ignored = false,
                dotfiles = false,
                git_clean = false,
                no_buffer = false,
                no_bookmark = false,
                custom = { ".swp", "*.o" },
                exclude = {},
            },

            update_focused_file = {
                -- 自动聚焦当前文件
                enable = true,
                update_root = {
                    -- 不更新根目录，此时可能会出现多级目录
                    enable = false,
                    ignore_list = {},
                },
                exclude = false,
            },

            git = {
                enable = false,
                show_on_dirs = true,
                show_on_open_dirs = true,
                disable_for_dirs = {},
                timeout = 400,
                cygwin_support = false,
            },
            tab = {
                sync = {
                    open = true,
                    close = true,
                    ignore = {},
                },
            },
            actions = {
                use_system_clipboard = true,
                change_dir = {
                    enable = true,
                    global = false,
                    restrict_above_cwd = false,
                },
                expand_all = {
                    max_folder_discovery = 300,
                    exclude = {},
                },
                file_popup = {
                    open_win_config = {
                        col = 1,
                        row = 1,
                        relative = "cursor",
                        border = "shadow",
                        style = "minimal",
                    },
                },
                open_file = {
                    --[[ 打开文件后不自动关闭 ]]
                    quit_on_open = false,
                    window_picker = {
                        enable = false,
                    },
                },
                remove_file = {
                    close_window = true,
                },
            },
        })
    end,
}
