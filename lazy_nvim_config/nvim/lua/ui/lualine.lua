-- 定义视觉宽度计算函数
-- 实时显示字符数，中文字符以2计数
local function str_width()
    local line_text = vim.api.nvim_get_current_line()
    local cursor_pos = vim.api.nvim_win_get_cursor(0) -- 获取光标位置 [行, 列]
    local col_index = cursor_pos[2] -- 列索引（从0开始）
    local partial_line = string.sub(line_text, 1, col_index + 1) -- 截取到光标位置

    local total_len = 0
    local i = 1
    while i <= #line_text do
        local b = line_text:byte(i)
        if b >= 224 and b < 240 then -- 覆盖绝大多数中文
            total_len = total_len + 2
            i = i + 3
        elseif b >= 240 then -- 处理4字节字符
            total_len = total_len + 1
            i = i + 4
        else
            total_len = total_len + 1
            i = i + 1
        end
    end

    -- 截至到当前光标的字符数
    local partial_len = 0
    i = 1
    while i <= #partial_line do
        local b = partial_line:byte(i)
        if b >= 224 and b < 240 then -- 覆盖绝大多数中文
            partial_len = partial_len + 2
            i = i + 3
        elseif b >= 240 then -- 处理4字节字符
            partial_len = partial_len + 1
            i = i + 4
        else
            partial_len = partial_len + 1
            i = i + 1
        end
    end
    return string.format([[%d:%d]], partial_len, total_len)
end

local opts = {
    options = {
        icons_enabled = false,

        theme = "auto",

        section_separators = { left = ">", right = "<" },

        component_separators = { left = "|", right = "|" },

        ignore_focus = {},

        --[[ 总是居中分离，防止A|B|C或X|Y|Z独占整个状态栏 ]]
        always_divide_middle = false,

        --[[ 是否所有窗口都使用同一个状态栏 >0.7]]
        globalstatus = false,

        --[[ 根据内容刷新状态栏的最低时间 ]]
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        },
    },

    --[[ 每个section显示的component如下所示 ]]
    sections = {
        lualine_a = { "mode" },
        lualine_b = {
            "branch",
            {
                "diff",
                colored = true, -- Displays a colored diff status if set to true
                diff_color = {
                    -- Same color values as the general color option can be used here.
                    -- Changes the diff's added color
                    added = "DiffAdd",
                    -- Changes the diff's modified color
                    modified = "DiffChange",
                    -- Changes the diff's removed color you
                    removed = "DiffDelete",
                },
                -- Changes the symbols used by the diff.
                symbols = { added = "+", modified = "~", removed = "-" },
                -- A function that works as a data source for diff.
                -- It must return a table as such:
                -- { added = add_count, modified = modified_count, removed = removed_count }
                -- or nil on failure. count <= 0 won't be displayed.
                source = nil,
            },
            {
                "diagnostics",

                -- Table of diagnostic sources, available sources are:
                --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
                -- or a function that returns a table as such:
                --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
                -- sources = { "nvim_diagnostic", "nvim_lsp", "nvim_workspace_diagnostic" },
                sources = { "nvim_diagnostic" },

                -- Displays diagnostics for the defined severity types
                sections = { "error", "warn", "info", "hint" },

                diagnostics_color = {
                    -- Same values as the general color option can be used here.
                    -- Changes diagnostics' error color.
                    error = "DiagnosticError",
                    -- Changes diagnostics' warn color.
                    warn = "DiagnosticWarn",
                    -- Changes diagnostics' info color.
                    info = "DiagnosticInfo",
                    -- Changes diagnostics' hint color.
                    hint = "DiagnosticHint",
                },
                symbols = { error = "E", warn = "W", info = "I", hint = "H" },
                -- symbols = { error = "", warn = "", info = "", hint = "" },
                -- Displays diagnostics status in color if set to true.
                colored = true,
                -- Update diagnostics in insert mode.
                update_in_insert = false,
                -- Show diagnostics even if there are none.
                always_visible = false,
            },
        },
        lualine_c = {
            {
                "filename",
                -- Displays file status (readonly status, modified status)
                file_status = true,
                -- Display new file status (new file means no write after created)
                newfile_status = true,
                -- 0: Just the filename 1: Relative path 2: Absolute path 3: Absolute path, with tilde as the home directory
                path = 2,

                -- Shortens path to leave 40 spaces in the window
                shorting_target = 40,
                -- for other components. (terrible name, any suggestions?)
                symbols = {
                    -- Text to show when the file is modified.
                    modified = "[+]",
                    -- Text to show when the file is non-modifiable or readonly.
                    readonly = "[-]",
                    -- Text to show for unnamed buffers.
                    unnamed = "[No Name]",
                    -- Text to show for new created file before first writting
                    newfile = "[New]",
                },
            },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "searchcount", "selectioncount", "progress" },
        lualine_z = {
            "location",
            str_width,
        },
    },

    disabled_filetypes = {
        --[[ 禁用statyskube的文件类型如下 ]]
        statusline = {},
        --[[ 禁用winbar的文件类型如下 ]]
        winbar = {},
    },

    --[[ 不活跃的信息 ]]
    inactive_sections = {
        lualine_a = {},
        lualine_b = { "branch" },
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },

    -- 为了兼容barbar.nvim
    tabline = {},
    -- tabline = {
    --     lualine_a = {},
    --     lualine_b = { "buffers" },
    --     lualine_c = {},
    --     lualine_x = { "os.date('%c')" },
    --     lualine_y = {},
    --     lualine_z = { "location" },
    -- },

    winbar = {},
    inactive_winbar = {},
    extensions = { "quickfix" },
}
return {
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup(opts)
        end,
    },
}
