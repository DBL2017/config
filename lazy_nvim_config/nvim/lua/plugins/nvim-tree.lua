-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
return {
    "kyazdani42/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
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
                width = 40,
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
                custom = {},
                exclude = {},
            },

            update_focused_file = {
                enable = true,
                update_root = {
                    enable = true,
                    ignore_list = {},
                },
                exclude = false,
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
                    quit_on_open = true,
                },
                remove_file = {
                    close_window = true,
                },
            },
        })
    end,
}
