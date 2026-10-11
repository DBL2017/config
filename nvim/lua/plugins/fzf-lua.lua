return {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    branch = "main",
    cmd = "FzfLua",
    config = function()
        -- calling `setup` is optional for customization
        require("fzf-lua").setup({
            winopts = {
                -- split = "belowright new", -- open in a split instead?
                -- split = "aboveleft new", -- open in a split instead?
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
                    scrollspeed = 5,
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
                on_create = function(e)
                    -- fzf 窗口是 terminal 模式，按键默认直接透传给 fzf 进程，
                    -- 普通模式的 <C-q> 映射不生效；这里在 Neovim 层拦截 <C-q>，
                    -- 不再依赖 fzf 自身的 abort 绑定（可能被 provider 或终端流控吞掉）
                    vim.keymap.set("t", "<C-q>", function()
                        require("fzf-lua").utils.fzf_exit()
                    end, { silent = true, nowait = true, buffer = e.bufnr })
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
