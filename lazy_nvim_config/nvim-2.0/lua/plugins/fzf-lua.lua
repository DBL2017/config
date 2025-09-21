return {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- calling `setup` is optional for customization
        require("fzf-lua").setup({
            winopts = {
                split = "belowright new", -- open in a split instead?
                -- "belowright new"  : split below
                -- "aboveleft new"   : split above
                -- "belowright vnew" : split right
                -- "aboveleft vnew   : split left
                -- Only valid when using a float window
                -- (i.e. when 'split' is not defined, default)
                height = 0.85, -- window height
                width = 0.85, -- window width
                row = 0.25, -- window row position (0=top, 1=bottom)
                col = 0.50, -- window col position (0=left, 1=right)
                -- border argument passthrough to nvim_open_win(), also used
                -- to manually draw the border characters around the preview
                -- window, can be set to 'false' to remove all borders or to
                -- 'none', 'single', 'double', 'thicc' (+cc) or 'rounded' (default)
                border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                -- requires neovim > v0.9.0, passed as is to `nvim_open_win`
                -- can be sent individually to any provider to set the win title
                -- title         = "Title",
                -- title_pos     = "center",    -- 'left', 'center' or 'right'
                fullscreen = true, -- start fullscreen?
                preview = {
                    -- default     = 'bat',           -- override the default previewer?
                    -- default uses the 'builtin' previewer
                    border = "border", -- border|noborder, applies only to
                    -- native fzf previewers (bat/cat/git/etc)
                    wrap = "wrap", -- wrap|nowrap
                    hidden = "nohidden", -- hidden|nohidden
                    vertical = "down:45%", -- up|down:size
                    horizontal = "right:70%", -- right|left:size
                    layout = "flex", -- horizontal|vertical|flex
                    flip_columns = 120, -- #cols to switch to horizontal on flex
                    -- Only used with the builtin previewer:
                    title = true, -- preview border title (file/buf)?
                    title_pos = "center", -- left|center|right, title alignment
                    scrollbar = "float", -- `false` or string:'float|border'
                    -- float:  in-window floating border
                    -- border: in-border chars (see below)
                    scrolloff = "-2", -- float scrollbar offset from right
                    -- applies only when scrollbar = 'float'
                    scrollchars = { "█", "" }, -- scrollbar chars ({ <full>, <empty> }
                    -- applies only when scrollbar = 'border'
                    delay = 100, -- delay(ms) displaying the preview
                    -- prevents lag on fast scrolling
                    winopts = { -- builtin previewer window options
                        number = true,
                        relativenumber = false,
                        cursorline = true,
                        cursorlineopt = "both",
                        cursorcolumn = false,
                        signcolumn = "no",
                        list = false,
                        foldenable = false,
                        foldmethod = "manual",
                    },
                },
                on_create = function()
                    -- called once upon creation of the fzf main window
                    -- can be used to add custom fzf-lua mappings, e.g:
                    --   vim.keymap.set("t", "<C-j>", "<Down>", { silent = true, buffer = true })
                end,
                -- called once *after* the fzf interface is closed
                -- on_close = function() ... end
            },
            lsp = {
                jump1 = false, -- skip the UI when result is a single entry
            },
        })
    end,
}
