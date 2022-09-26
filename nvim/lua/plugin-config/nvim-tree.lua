local installStatus = pcall(require, "nvim-tree")

if installStatus == false then return installStatus end

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1
--[[ https://github.com/kyazdani42/nvim-web-devicons is optional and used to display file icons. It requires a patched font: https://www.nerdfonts.com ]]
require("nvim-tree").setup({
    --[[ 如果启动buffer是目录，或为空，或未命名，则打开nvim-tree窗口 ]]
    open_on_setup = true,

    --[[ 如果启动buffer是一个文件，则打开nvim-tree窗口，但焦点在文件窗口
	但如果update_focused_file is enabled，文件将被发现

	如果设置为true，会导致lualine在第一次打开文件时git diff数据错误 ]]
    open_on_setup_file = false,

    --[[ 更新BufEnter上的焦点文件，递归展开文件夹，直到找到该文件 ]]
    update_focused_file = {
        enable = true,
        --[[ 如果文件不在当前目录及子目录下，则更新文件树的根目录 ]]
        update_root = true,
        --[[ 不会更新下面设置的文件的BufEnter以及目录树 ]]
        ignore_list = {},
    },

    --[[ 下面配置的文件类型，在打开对应文件时不会打开nvim-tree窗口 ]]
    ignore_ft_on_setup = {},

    --[[ 当切换tab或打开新tab时打开nvim-tree窗口，前提是nvim-tree已经打开 ]]
    open_on_tab = true,

    --[[ 下面配置的文件类型，在切换tab或打开新tab时不会打开nvim-tree窗口 ]]
    ignore_buf_on_tab_change = {},

    --[[ 每次写入缓冲区时自动加载explorer ]]
    auto_reload_on_write = true,

    --[[ 当光标位于已经关闭的文件夹上创建文件在其内部，否则是同级 ]]
    create_in_closed_folder = true,

    --[[ 同级目录下的文件排序方式，分别可取值为name,case_sensitive,modification_time,extension或自定义function ]]
    sort_by = "case_sensitive",

    --[[ 如果缓冲区为空，则只打开nvim-tree窗口 ]]
    hijack_unnamed_buffer_when_opening = false,

    --[[ 光标处在文件树中文件名的第一个字符上 ]]
    hijack_cursor = true,

    --[[ 首选根目录
       [ 当update_focused_file.update_root is true，文件未在当前目录时，需要切换文件树的根目录，优先选择下面配置的目录 ]]
    root_dirs = {},

    --[[ 首选根目录
       [ 当update_focused_file.update_root is true，文件未在当前目录时，需要切换文件树的根目录，优先启动时的根目录 ]]
    prefer_startup_root = false,

    --[[ 激活buf时重新加载文件树 ]]
    reload_on_bufenter = true,

    --[[ 在标志列显示LSP和COC的分析结果 ]]
    diagnostics = {
        enable = true,
        --[[ 在父目录上显示图标 ]]
        show_on_dirs = true,
        --[[ 事件和更新时间 ]]
        debounce_delay = 50,
        icons = {
            hint = "H",
            info = "I",
            warning = "W",
            error = "E",
        },
    },

    --[[ Git图标和颜色 ]]
    git = {
        enable = true,
        --[[ 忽略.gitignore配置的文件 ]]
        ignore = true,
        --[[ 当目录本身没有状态图标时，显示子目录的状态图标 ]]
        show_on_dirs = true,
        timeout = 1000,
    },

    --[[ 使用libuv fs_event来监控文件系统
       [ disable BufEnter,BufWritePost event ]]
    filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
    },

    --[[ 创建文件树缓冲区时运行
       [ 绑定快捷键到树缓冲区 ]]
    on_attach = function(bufnr)
        local inject_node = require("nvim-tree.utils").inject_node
        -- 绑定快捷键到内部缓冲区
        vim.keymap.set(
            "n",
            "<CR>",
            inject_node(function(node)
                if node then
                    print(node.absolute_path)
                    require("nvim-tree.api").node.open.tab()
                end
            end),
            { buffer = bufnr, noremap = true }
        )
        vim.bo[bufnr].path = "/tmp"
    end,

    --[[ 移除默认快捷键 ]]
    remove_keymaps = false,

    --[[ 窗口或缓冲区设置 ]]
    view = {
        --[[ 根据最长文件名设置窗口宽度
	   [ side为left或right时生效 ]]
        adaptive_size = false,

        --[[ 重新进入nvim-tree窗口时，使当前位置处于中间，类似于zz ]]
        centralize_selection = true,

        --[[ 在顶部隐藏根目录 ]]
        hide_root_folder = false,

        width = 30,
        height = 30,

        --[[ option: left,right,top,bottom ]]
        side = "left",

        --[[ nvim-tree窗口打印行号 ]]
        number = true,
        relativenumber = false,

        --[[ 标志列 ]]
        signcolumn = "yes",

        --[[ 浮动窗口 ]]
        float = {
            enable = false,
            open_win_config = {
                relative = "editor",
                border = "rounded",
                width = 30,
                height = 30,
                row = 1,
                col = 1,
            },
        },
    },

    renderer = {
        --[[ 文件夹后带/ ]]
        add_trailing = true,

        group_empty = false,

        --[[ 浮动窗口显示全名 ]]
        full_name = true,

        highlight_git = true,

        --[[ 高亮打开的文件 ]]
        --none, icon, name, all
        highlight_opened_files = "all",

        root_folder_modifier = ":~",

        --[[ 使用图标的前提是要修复相应字体中的图标，可以安装nerd-font ]]
        icons = {
            --[[ git标志位置: after, before, signcolumn ]]
            git_placement = "signcolumn",
            show = {
                file = true,
                folder = true,
                folder_arrow = true,
                git = true,
            },
            glyphs = {
                default = "",
                symlink = "",
                bookmark = "",
                folder = {
                    arrow_closed = "",
                    arrow_open = "",
                    default = "",
                    open = "",
                    empty = "",
                    empty_open = "",
                    symlink = "",
                    symlink_open = "",
                },
                git = {
                    unstaged = "✗",
                    staged = "✓",
                    unmerged = "",
                    renamed = "➜",
                    untracked = "★",
                    deleted = "",
                    ignored = "◌",
                },
            },
        },
        --[[ 突出显示的文件名 ]]
        special_files = {
            "Cargo.toml",
            "Makefile",
            "README.md",
            "readme.md",
        },
        --[[ 符号连接显示目的文件 ]]
        symlink_destination = true,
    },

    filters = {
        --[[ 不显示以.开头的文件 ]]
        dotfiles = false,

        --[[ 自定义不不显示的文件 ]]
        custom = { "^\\.git" },

        --[[ 从过滤中排除的目录，始终显示下面设置的 ]]
        exclude = {},
    },

    actions = {
        use_system_clipboard = true,
        --[[ 打开文件时的行为配置 ]]
        open_file = {
            --[[ 打开文件时关闭nvim-tree window ]]
            quit_on_open = true,

            --[[ 打开文件时调整nvim-tree window的大小 ]]
            resize_window = true,

            window_picker = {
                enable = true,
                chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                exclude = {
                    filetype = {
                        "notify",
                        "packer",
                        "qf",
                        "diff",
                        "fugitive",
                        "fugitiveblame",
                    },
                    buftype = { "nofile", "terminal", "help" },
                },
            },
        },

        --[[ 从树中删除文件时关闭任何显示该文件的窗口 ]]
        remove_file = {
            close_window = true,
        },
    },
})
