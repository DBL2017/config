local installStatus = pcall(require, "material")

vim.cmd({ cmd = "colorscheme", args = { "material" } })

if installStatus then
    require("material").setup({
        contrast = {
            sidebars = true, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
            floating_windows = true, -- Enable contrast for floating windows
            line_numbers = true, -- Enable contrast background for line numbers
            sign_column = true, -- Enable contrast background for the sign column
            cursor_line = true, -- Enable darker background for the cursor line
            non_current_windows = true, -- Enable darker background for non-current windows
            popup_menu = true, -- Enable lighter background for the popup menu
        },

        styles = { -- Give comments style such as bold, italic, underline etc.
            comments = {
                italic = true,--[[ italic = true ]]
            },
            strings = { --[[ bold = true ]]
            },
            keywords = {
                bold = true,
                --[[ underline = true ]]
            },
            functions = { --[[ bold = true, undercurl = true ]]
            },
            variables = {},
            operators = {},
            types = {},
        },

        contrast_filetypes = { -- Specify which filetypes get the contrasted (darker) background
            "terminal", -- Darker terminal background
            "packer", -- Darker packer background
            "qf", -- Darker qf list background
        },

        high_visibility = {
            lighter = true, -- Enable higher contrast text for lighter style
            darker = true, -- Enable higher contrast text for darker style
        },

        disable = {
            colored_cursor = false, -- Disable the colored cursor
            borders = false, -- Disable borders between verticaly split windows
            background = false, -- Prevent the theme from setting the background (NeoVim then uses your teminal background)
            term_colors = false, -- Prevent the theme from setting terminal colors
            eob_lines = true, -- Hide the end-of-buffer lines
        },

        lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )

        async_loading = true, -- Load parts of the theme asyncronously for faster startup (turned on by default)

        custom_highlights = {}, -- Overwrite highlights with your own

        plugins = { -- Here, you can disable(set to false) plugins that you don't use or don't want to apply the theme to
            trouble = true,
            nvim_cmp = true,
            neogit = true,
            gitsigns = true,
            git_gutter = true,
            telescope = true,
            nvim_tree = true,
            sidebar_nvim = true,
            lsp_saga = true,
            nvim_dap = true,
            nvim_navic = true,
            which_key = true,
            sneak = true,
            hop = true,
            indent_blankline = true,
            nvim_illuminate = true,
            mini = true,
        },
    })

    -- material_stype option
    -- darker
    -- lighter
    -- oceanic
    -- palenight
    -- deep ocean
    require("material.functions").change_style("darker")
else
    vim.notify("没有找到material")
    return
end
