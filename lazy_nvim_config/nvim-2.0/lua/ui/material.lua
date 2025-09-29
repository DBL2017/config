local opts = {
    contrast = {
        sidebars = true,            -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
        floating_windows = true,    -- Enable contrast for floating windows
        line_numbers = true,        -- Enable contrast background for line numbers
        sign_column = true,         -- Enable contrast background for the sign column
        cursor_line = true,         -- Enable darker background for the cursor line
        non_current_windows = true, -- Enable darker background for non-current windows
        popup_menu = true,          -- Enable lighter background for the popup menu
    },

    styles = { -- Give comments style such as bold, italic, underline etc.
        comments = {
            italic = true, --[[ italic = true ]]
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
        "terminal",        -- Darker terminal background
        "packer",          -- Darker packer background
        "qf",              -- Darker qf list background
    },

    high_visibility = {
        lighter = true, -- Enable higher contrast text for lighter style
        darker = true,  -- Enable higher contrast text for darker style
    },

    disable = {
        colored_cursor = false, -- Disable the colored cursor
        borders = false,        -- Disable borders between vertically split windows
        background = false,     -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
        term_colors = false,    -- Prevent the theme from setting terminal colors
        eob_lines = true,       -- Hide the end-of-buffer lines
    },

    lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )

    async_loading = true,      -- Load parts of the theme asynchronously for faster startup (turned on by default)

    custom_highlights = {},    -- Overwrite highlights with your own

    plugins = {                -- Here, you can disable(set to false) plugins that you don't use or don't want to apply the theme to
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
}
return {
    {
        "marko-cerovac/material.nvim",
        lazy = false,    -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        config = function()
            require("material").setup(opts)
            vim.g.material_style = "darker"
            -- vim.g.material_style = "deep ocean"
            -- vim.g.material_style = "palenight"
            -- vim.g.material_style = "oceanic"
            -- vim.g.material_style = "lighter"
            -- 下面这行代码会在windows上出错
            -- require("material.functions").change_style("darker")
            -- vim.cmd({ cmd = "colorscheme", args = { "material" } })
        end,
    }
}
