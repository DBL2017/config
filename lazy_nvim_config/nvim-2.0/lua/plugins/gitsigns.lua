return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require("gitsigns").setup({
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = {
                    text = "-",
                },
                changedelete = {
                    text = "~",
                },
            },
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = true, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                interval = 5000,
                follow_files = true,
            },
            attach_to_untracked = true,
            -- blame性能太低，在大项目中导致git cpu占用率太高
            current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                delay = 5000,
                ignore_whitespace = true,
                virt_text_priority = 100,
                use_focus = true,
            },
            current_line_blame_formatter = "<abbrev_sha> <author>, <author_time:%Y-%m-%d> - <summary>",
            sign_priority = 6,
            update_debounce = 100,
            status_formatter = nil, -- Use default
            max_file_length = 40000, -- Disable if file is longer than this (in lines)
            preview_config = {
                -- Options passed to nvim_open_win
                border = "rounded",
                style = "minimal",
                relative = "cursor",
                row = 0,
                col = 1,
            },
            on_attach = function(bufnr)
                set_gitsign_keymap(bufnr)
            end,
        })
    end,
}
