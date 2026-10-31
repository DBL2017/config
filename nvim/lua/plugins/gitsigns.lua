return {
    "lewis6991/gitsigns.nvim",
    event = {
        "BufReadPre",
        "BufNewFile",
    },
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

            diff_opts = {
                internal = true, -- 使用内置 diff（推荐）
                ignore_blank_lines = false,
                ignore_whitespace_change = false, -- ✅ 不忽略空格/空行变化
                ignore_whitespace = false,
                ignore_whitespace_change_at_eol = false,
            },

            on_attach = function(bufnr)
                -- 键位统一定义在 config/keymappings.lua 的 _G.set_gitsign_keymap。
                -- 直接 require 会重复执行 keymappings 的全局副作用，这里只做存在性检查：
                -- 若尚未加载则补一次 require，避免 "attempt to call a nil value
                -- (global 'set_gitsign_keymap')"（本插件在 BufReadPre 触发，
                -- 时序上可能早于 init.lua 里的 require("config.keymappings")）
                if not _G.set_gitsign_keymap then
                    pcall(require, "config.keymappings")
                end
                local set_keymap = _G.set_gitsign_keymap
                if set_keymap then
                    set_keymap(bufnr)
                else
                    vim.notify("config.keymappings 未加载，gitsigns 键位未绑定", vim.log.levels.WARN)
                end
            end,
        })
    end,
}
