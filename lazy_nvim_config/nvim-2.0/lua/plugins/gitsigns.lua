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
            numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = true, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                interval = 1000,
                follow_files = true,
            },
            attach_to_untracked = true,
            current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
                ignore_whitespace = true,
                virt_text_priority = 100,
                use_focus = false,
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
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end
                -- Navigation
                map("n", "]c", function()
                    -- diff模式时返回]c，用来触发默认动作
                    if vim.wo.diff then
                        return "]c"
                    end
                    vim.schedule(function()
                        gs.nav_hunk("next", { preview = true })
                    end)
                    return "<Ignore>"
                end, { expr = true })

                map("n", "[c", function()
                    -- diff模式时返回]c，用来触发默认动作
                    if vim.wo.diff then
                        return "[c"
                    end
                    vim.schedule(function()
                        gs.nav_hunk("prev", {
                            preview = true,
                        })
                    end)
                    return "<Ignore>"
                end, { expr = true })
                -- hunk stage
                map("n", "<LocalLeader>hs", function()
                    gs.stage_hunk()
                end, {})
                -- hunk unstage
                map("n", "<LocalLeader>hu", function()
                    gs.undo_stage_hunk()
                end, {})
                -- hunk reset
                map("n", "<LocalLeader>hr", function()
                    gs.reset_hunk()
                end, {})
                -- buffer stage
                map("n", "<LocalLeader>bs", function()
                    gs.stage_buffer()
                end, {})
            end,
        })
    end,
}
