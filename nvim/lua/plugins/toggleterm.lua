return {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = {
        "ToggleTerm",
        "TermExec",
    },
    config = function()
        require("toggleterm").setup({
            -- size can be a number or function which is passed the current terminal
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,
            close_on_exit = true,
            open_mapping = [[<c-\>]],
            -- 打开新终端后自动进入插入模式
            start_in_insert = true,
            -- 在当前buffer的下方打开新终端
            direction = "float",
            -- shell = "/bin/bash",
            hide_numbers = false,
            float_opts = {
                border = "curved",
            },
            on_open = function(term)
                -- 键位统一定义在 config/keymappings.lua 的 _G.set_terminal_keymaps。
                -- 直接 require 会重复执行 keymappings 的全局副作用，这里只做存在性检查：
                -- 若尚未加载则补一次 require，避免 "attempt to call a nil value
                -- (global 'set_terminal_keymaps')"
                if not _G.set_terminal_keymaps then
                    pcall(require, "config.keymappings")
                end
                local set_keymaps = _G.set_terminal_keymaps
                if set_keymaps then
                    -- 传入 term.bufnr：原先的 buffer = 0 在浮动终端的 on_open 触发点
                    -- 不保证当前 buffer 就是终端本体
                    set_keymaps(term.bufnr)
                else
                    vim.notify("config.keymappings 未加载，terminal 键位未绑定", vim.log.levels.WARN)
                end
            end,
        })

        -- local Terminal = require("toggleterm.terminal").Terminal
        -- local lazygit = Terminal:new({
        -- 	cmd = "lazygit",
        -- 	dir = "git_dir",
        -- 	direction = "float",
        -- 	float_opts = {
        -- 		border = "double",
        -- 	},
        -- 	-- function to run on opening the terminal
        -- 	on_open = function(term)
        -- 		vim.cmd("startinsert!")
        -- 		vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        -- 	end,
        -- 	-- function to run on closing the terminal
        -- 	on_close = function(term) vim.cmd("startinsert!") end,
        -- })

        -- function _lazygit_toggle() lazygit:toggle() end

        -- vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
    end,
}
