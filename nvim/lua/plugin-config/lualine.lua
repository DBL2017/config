--[[ +-------------------------------------------------+
[ | A | B | C                             X | Y | Z |
[ +-------------------------------------------------+ ]]
require('lualine').setup {
    options = {
        --[[ 状态栏中显示图标 ]]
        icons_enabled = false,

        --[[ 设置lualine主题
        [ 仅支持https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md中定义的值 ]]
        theme = 'solarized_dark',

        --[[ A|B|C为左侧3个section. X|Y|Z为右侧3个section
        [ section_separators为section之间的分隔符 ]]
        section_separators = { left = '>', right = '<'},

        --[[ A、B、C分别为3个section，每个section中都包含1个或多个component
        [ component之间的分隔符如下 ]]
        component_separators = { left = '|', right = '|'},

        ignore_focus = {},

        --[[ 总是居中分离，防止A|B|C或X|Y|Z独占整个状态栏 ]]
        always_divide_middle = false,

        --[[ 是否所有窗口都使用同一个状态栏 >0.7]]
        globalstatus = true,

        --[[ 根据内容刷新状态栏的最低时间 ]]
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },

    --[[ 每个section显示的component如下所示 ]]
    sections = {
        lualine_a = {'mode'},
        lualine_b = {
            'branch',
            {
                'diff',
                colored = true, -- Displays a colored diff status if set to true
                diff_color = {
                    -- Same color values as the general color option can be used here.
                    -- Changes the diff's added color
                    added    = 'DiffAdd',
                    -- Changes the diff's modified color
                    modified = 'DiffChange',
                    -- Changes the diff's removed color you
                    removed  = 'DiffDelete',
                },
                -- Changes the symbols used by the diff.
                symbols = {added = '+', modified = '~', removed = '-'},
                -- A function that works as a data source for diff.
                -- It must return a table as such:
                -- { added = add_count, modified = modified_count, removed = removed_count }
                -- or nil on failure. count <= 0 won't be displayed.
                source = nil
            },
            {
                'diagnostics',

                -- Table of diagnostic sources, available sources are:
                --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
                -- or a function that returns a table as such:
                --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
                sources = { 'nvim_diagnostic', 'nvim_lsp' },

                -- Displays diagnostics for the defined severity types
                sections = { 'error', 'warn', 'info', 'hint' },

                diagnostics_color = {
                    -- Same values as the general color option can be used here.
                    -- Changes diagnostics' error color.
                    error = 'DiagnosticError',
                    -- Changes diagnostics' warn color.
                    warn  = 'DiagnosticWarn',
                    -- Changes diagnostics' info color.
                    info  = 'DiagnosticInfo',
                    -- Changes diagnostics' hint color.
                    hint  = 'DiagnosticHint',
                },
                symbols = {error = 'E', warn = 'W', info = 'I', hint = 'H'},
                -- Displays diagnostics status in color if set to true.
                colored = true,
                -- Update diagnostics in insert mode.
                update_in_insert = false,
                -- Show diagnostics even if there are none.
                always_visible = false,
            }
        },
        lualine_c = {'filename'},
        lualine_x = {'encoding','fileformat','filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'},
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
        lualine_b = {'branch'},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },

    --tabline = {
    --    lualine_a = {'buffers'},
    --    lualine_b = {},
    --    lualine_c = {
    --        {
    --            'filename',
    --            -- Displays file status (readonly status, modified status)
    --            file_status = true,
    --            -- Display new file status (new file means no write after created)
    --            newfile_status = true,
    --            -- 0: Just the filename 1: Relative path 2: Absolute path 3: Absolute path, with tilde as the home directory
    --            path = 2,

    --            -- Shortens path to leave 40 spaces in the window
    --            shorting_target = 40,
    --            -- for other components. (terrible name, any suggestions?)
    --            symbols = {
    --                -- Text to show when the file is modified.
    --                modified = '[+]',
    --                -- Text to show when the file is non-modifiable or readonly.
    --                readonly = '[-]',
    --                -- Text to show for unnamed buffers.
    --                unnamed = '[No Name]',
    --                -- Text to show for new created file before first writting
    --                newfile = '[New]'
    --            }
    --        }
    --    },
    --    lualine_x = {"os.date('%c')"},
    --    lualine_y = {},
    --    lualine_z = {'tabs'}
    --},

    winbar = {},
    inactive_winbar = {},
    extensions = {'quickfix'}
}
