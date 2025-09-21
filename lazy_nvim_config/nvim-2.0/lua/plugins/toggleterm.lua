return {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
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
