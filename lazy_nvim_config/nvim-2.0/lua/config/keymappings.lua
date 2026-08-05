----------------------------------------------------------Basic-------------------------------------------------------------
local custom_function = require("config.custom_function")
local custom_comment = require("config.custom_comment")
local custom_lsp = require("config.custom_lsp")

function save_all_and_quit()
    -- wirte all buffers first
    vim.api.nvim_command(":wa")
    -- quit all buffers
    vim.api.nvim_command(":qa")
end
vim.keymap.set({ "n", "v" }, "<LocalLeader>wq", "<cmd>lua save_all_and_quit()<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>q", "<cmd>q!<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>w", "<cmd>w<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<LocalLeader>qa", "<cmd>qa!<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-q>", "<cmd>q!<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-s>", "<cmd>w<CR>", { silent = true })

-- 查找
-- 自动将查找到的字符串设置到屏幕中央
vim.keymap.set("n", "n", "nzz", { silent = true })
vim.keymap.set("n", "N", "Nzz", { silent = true })

-- 将单行内选中的字符串当作文件打开
vim.keymap.set("v", "<LocalLeader>of", custom_function.open_selected_file, { desc = "Open file" })

-- 扩展复制
vim.keymap.set({ "n", "x" }, "<LocalLeader>yy", function()
    custom_function.copy_with_metadata(0)
end, {
    desc = "Copy with filename and linenu",
})
vim.keymap.set({ "n", "x" }, "<LocalLeader>yf", function()
    custom_function.copy_with_metadata(1)
end, {
    desc = "Copy with fullpath filename and linenu",
})
vim.keymap.set({ "n", "x" }, "<LocalLeader>yr", function()
    custom_function.copy_with_metadata(2)
end, {
    desc = "Copy with relative filename and linenu",
})
-- 获取当前文件所在的路径名
vim.keymap.set("n", "<LocalLeader>yp", custom_function.copy_current_filepath, {
    desc = "Copy current file path",
})
-- 拷贝当前行的commit sha
vim.keymap.set("n", "<LocalLeader>yc", custom_function.get_line_commit, { desc = "Get line commit SHA" })

-- 对比当前行的commit与当前buffer的文件差异
vim.keymap.set("n", "<LocalLeader>gd", custom_function.git_diff_with_commit_sha, {
    desc = "Diff current line's Git commit",
})

-- 普通模式下在当前位置插入时间
vim.keymap.set("n", "<LocalLeader>ti", "i<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})
-- 普通模式下在下一行插入时间
-- 和tab only快捷键冲突，去掉该快捷键
-- vim.keymap.set("n", "<LocalLeader>to", "o<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
--     silent = true,
--     desc = "插入本地化时间",
-- })
-- 普通模式下在上一行插入时间
vim.keymap.set("n", "<LocalLeader>tO", "O<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    silent = true,
    desc = "插入本地化时间",
})

-- 在当前函数上方插入注释
vim.keymap.set("n", "<LocalLeader>fO", function()
    local ok, err = pcall(custom_comment.insert_comment, "function")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end, { silent = true, desc = "在当前变量上方插入注释" })
-- 在当前变量上方插入注释
vim.keymap.set("n", "<LocalLeader>vO", function()
    local ok, err = pcall(custom_comment.insert_comment, "variable")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end, { silent = true, desc = "在当前变量上方插入注释" })
-- 在当前宏上方插入注释
vim.keymap.set("n", "<LocalLeader>mO", function()
    local ok, err = pcall(custom_comment.insert_comment, "macro")
    if not ok then
        vim.notify("insert failed: " .. err, vim.log.levels.ERROR)
    end
end, { silent = true, desc = "在当前宏上方插入注释" })

-- 原生lsp
vim.keymap.set("n", "<LocalLeader>lr", function()
    vim.lsp.buf.references()
end, {
    silent = true,
    desc = "lsp_reference",
})

-- tab快捷键
-- Move to previous/next
vim.keymap.set({ "i", "n" }, "<A-,>", "<cmd>tabprevious<CR>", { silent = true, desc = "tabprevious" })
vim.keymap.set({ "i", "n" }, "<A-.>", "<cmd>tabnext<CR>", { silent = true, desc = "tabnext" })
-- Re-order to previous/next
vim.keymap.set({ "i", "n" }, "<A-Left>", "<cmd>-tabmove<CR>", { silent = true, desc = "-tabmove" })
vim.keymap.set({ "i", "n" }, "<A-Right>", "<cmd>+tabmove<CR>", { silent = true, desc = "+tabmove" })
-- Close buffer
vim.keymap.set({ "i", "n" }, "<A-c>", "<cmd>tabclose<CR>", { silent = true, desc = "tabclose" })
-- tab
-- 使用LocalLeader的原因防止误操作
vim.keymap.set({ "i", "n" }, "<LocalLeader>tn", "<cmd>$tabnew<CR>", { silent = true, desc = "$tabnew" })
vim.keymap.set({ "i", "n" }, "<LocalLeader>to", "<cmd>tabonly<CR>", { silent = true, desc = "tabonly" })

vim.keymap.set({ "i", "n" }, "<A-0>", "<cmd>tablast<CR>", { silent = true, desc = "tablast" })
vim.keymap.set({ "i", "n" }, "<A-1>", "<cmd>tabnext 1<CR>", { silent = true, desc = "tabnext 1" })
vim.keymap.set({ "i", "n" }, "<A-2>", "<cmd>tabnext 2<CR>", { silent = true, desc = "tabnext 2" })
vim.keymap.set({ "i", "n" }, "<A-3>", "<cmd>tabnext 3<CR>", { silent = true, desc = "tabnext 3" })
vim.keymap.set({ "i", "n" }, "<A-4>", "<cmd>tabnext 4<CR>", { silent = true, desc = "tabnext 4" })
vim.keymap.set({ "i", "n" }, "<A-5>", "<cmd>tabnext 5<CR>", { silent = true, desc = "tabnext 5" })
vim.keymap.set({ "i", "n" }, "<A-6>", "<cmd>tabnext 6<CR>", { silent = true, desc = "tabnext 6" })
vim.keymap.set({ "i", "n" }, "<A-7>", "<cmd>tabnext 7<CR>", { silent = true, desc = "tabnext 7" })
vim.keymap.set({ "i", "i", "n" }, "<A-8>", "<cmd>tabnext 8<CR>", { silent = true, desc = "tabnext 8" })
vim.keymap.set({ "i", "i", "n" }, "<A-9>", "<cmd>tabnext 9<CR>", { silent = true, desc = "tabnext 9" })

vim.keymap.set({ "i", "n" }, "<A-Down>", "<cmd>bnext<CR>", { silent = true, desc = "buffer next" })
vim.keymap.set({ "i", "n" }, "<A-Up>", "<cmd>bprevious<CR>", { silent = true, desc = "buffer previous" })
vim.keymap.set({ "i", "n" }, "<A-d>", "<cmd>bd<CR>", { silent = true, desc = "buffer delete" })

-- 禁用方向键
-- vim.keymap.set("n", "<Left>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Right>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Up>", "<NOP>", {silent=true,desc=""})
-- vim.keymap.set("n", "<Down>", "<NOP>", {silent=true,desc=""})

-- 调整窗口小
vim.keymap.set("n", "<C-Up>", "<cmd>resize -1<CR>", { silent = true, desc = "resize -1" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize +1<CR>", { silent = true, desc = "resize +1" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -3<CR>", { silent = true, desc = "vertical resize -3" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +3<CR>", { silent = true, desc = "vertical resize +3" })

-- diagnostics
-- 2. 优化 float 窗口打开行为（通过自定义函数封装）
local function open_optimized_diagnostic_float()
    vim.diagnostic.config({
        virtual_lines = false,
    })
    vim.diagnostic.open_float({
        -- 可选：限制窗口最大宽度/高度
        max_width = math.floor(vim.o.columns * 0.5), -- 最大宽度为屏幕50%
        max_height = math.floor(vim.o.lines * 0.4), -- 最大高度为屏幕40%
    })
end
vim.keymap.set("n", "<space>e", open_optimized_diagnostic_float, { desc = "Open optimized diagnostics" })
-- vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, {silent=true, desc=""})
vim.keymap.set("n", "[d", custom_function.diagnostic_goto_prev, { silent = true, desc = "Jump prev diagnostic" })
vim.keymap.set("n", "]d", custom_function.diagnostic_goto_next, { silent = true, desc = "Jump next diagnostic" })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { silent = true, desc = "" })

vim.keymap.set("n", "<LocalLeader>ac", custom_function.align_column, { silent = true, desc = "Align columns end" })

vim.keymap.set("n", "[[", "[[zt", {
    noremap = true,
    silent = true,
    desc = "跳转到上一个段落并居中",
})

----------------------------------------------------------Plugins-------------------------------------------------------------
-- nvim-ufo
-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
-- vim.keymap.set("n", "zR", require("ufo").openAllFolds, { silent = true, desc = "Open all folds" })
-- vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { silent = true, desc = "Close all folds" })

-- 格式化
local conform_ok, conform_err = pcall(require, "conform")
if conform_ok then
    -- vim.keymap.set({ "n", "v" }, "<space>f", require("conform").format, { desc = "Format current buffer" })
    -- 快捷键配置
    vim.keymap.set({ "n", "v" }, "<space>f", function(args)
        local mode = vim.api.nvim_get_mode().mode

        if mode == "v" or mode == "V" then
            -- 用 getpos 获取可视选区起止：{bufnum, lnum, col, off}
            local vpos = vim.fn.getpos("v") -- {buf, lnum, col, off}
            local cpos = vim.fn.getpos(".") -- {buf, lnum, col, off}

            local srow, erow = vpos[2], cpos[2]

            if srow > erow then
                srow, erow = erow, srow
            end

            -- 取结束行长度作为“行末列”
            local end_line = vim.api.nvim_buf_get_lines(0, erow - 1, erow, true)[1] or ""
            local end_col = #end_line

            local range = {
                start = { srow - 1, 0 },
                ["end"] = { erow - 1, end_col },
            }

            -- print("格式化范围:", vim.inspect(range))

            require("conform").format({
                lsp_fallback = false,
                async = false,
                timeout_ms = 5000,
                range = range,
            })
        else -- 普通模式（格式化整个文件）
            require("conform").format({
                lsp_fallback = false,
                async = false,
                timeout_ms = 5000,
            })
        end
    end, { desc = "格式化文件或选中区域" })
end

-- 文件树
local nvimtree_ok, nvimtree_err = pcall(require, "nvim-tree")
if nvimtree_ok then
    vim.keymap.set({ "n", "v", "i" }, "<F2>", "<cmd>NvimTreeToggle<CR>", { desc = "Open file explore" })
end

-- CodeCompanion
local codecompanion_ok, codecompanion_err = pcall(require, "codecompanion")
if codecompanion_ok then
    vim.keymap.set({ "n", "v" }, "<LocalLeader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
    vim.keymap.set(
        { "n", "v" },
        "<LocalLeader>at",
        "<cmd>CodeCompanionChat Toggle<cr>",
        { noremap = true, silent = true }
    )
    vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
    vim.keymap.set({ "v" }, "<LocalLeader>ae", function()
        require("codecompanion").prompt("claude_explain_code_view")
    end, { noremap = true, silent = true })

    vim.keymap.set(
        { "n" },
        "<LocalLeader>ah",
        "<cmd>CodeCompanionHistory<cr>",
        { desc = "Open chat history list", noremap = true, silent = true }
    )
end

-- telescope
-- " Find files using Telescope command-line sugar.
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
local telescope_ok, telescope_err = pcall(require, "telescope.builtin")
if telescope_ok then
    vim.keymap.set("n", "tfr", function()
        require("telescope.builtin").find_files()
    end, { silent = true, desc = "Search for files" })

    -- vim.keymap.set("n", "tfr", function()
    --     require("telescope.builtin").oldfiles()
    -- end, { silent = true, desc = "Lists previously open files" })

    vim.keymap.set("n", "tht", function()
        require("telescope.builtin").help_tags()
    end, { silent = true, desc = "Lists available help tags" })

    vim.keymap.set("n", "tgs", function()
        require("telescope.builtin").grep_string({ cwd = vim.fn.expand("%:p:h") })
    end, { silent = true, desc = "Searches for the string under your cursor in your current working directory" })

    vim.keymap.set("n", "tlg", function()
        require("telescope.builtin").live_grep({ cwd = vim.fn.expand("%:p:h") })
    end, { silent = true, desc = "Search for a string and get results live as you type" })

    vim.keymap.set("n", "tlb", function()
        require("telescope.builtin").buffers()
    end, { silent = true, desc = "Lists open buffers in current neovim instance" })

    vim.keymap.set("n", "tts", function()
        require("telescope.builtin").treesitter()
    end, {
        silent = true,
        desc = "Lists function names, variables, and other symbols from treesitter queries",
    })

    vim.keymap.set("n", "tgd", function()
        require("telescope.builtin").lsp_definitions({ jump_type = "never" })
    end, { silent = true, desc = "Goto the definition of the word under the cursor" })

    vim.keymap.set("n", "tgb", function()
        require("telescope.builtin").git_branches({ jump_type = "never" })
    end, { silent = true, desc = "List branches for current directory, shown in the preview window" })

    vim.keymap.set("n", "tgc", function()
        require("telescope.builtin").git_commits({ jump_type = "never" })
    end, { silent = true, desc = "List commits for current directory with diff preview" })

    vim.keymap.set("n", "tbc", function()
        require("telescope.builtin").git_bcommits({ jump_type = "never" })
    end, { silent = true, desc = "Lists commits for current buffer with diff preview" })

    vim.keymap.set("n", "tlr", function()
        require("telescope.builtin").lsp_references()
    end, { silent = true, desc = "Lists LSP references for word under the cursor" })

    vim.keymap.set("n", "tcs", function()
        require("telescope.builtin").colorscheme({ enable_preview = true })
    end, { silent = true, desc = "Change colorscheme and preview" })

    vim.keymap.set("n", "tic", function()
        require("telescope.builtin").lsp_incoming_calls()
    end, { silent = true, desc = "Lists LSP incoming calls for word under the cursor, jumps to reference on" })
    vim.keymap.set("n", "toc", function()
        require("telescope.builtin").lsp_outgoing_calls()
    end, { silent = true, desc = "Lists LSP outgoing calls for word under the cursor, jumps to reference on" })

    local telescope_frecency_ok, telescope_frecency_err = pcall(require, "telescope._extensions.frecency")
    if telescope_frecency_ok then
        -- vim.keymap.set("n", "tff", function()
        --     require("telescope").extensions.frecency.frecency({})
        -- end)
        -- Use a specific workspace tag:
        vim.keymap.set("n", "tfw", function()
            require("telescope").extensions.frecency.frecency({
                workspace = "CWD",
            })
        end)
        -- You can use with telescope's options
        vim.keymap.set("n", "tff", function()
            require("telescope").extensions.frecency.frecency({
                workspace = "CWD",
                path_display = { "shorten" },
                theme = "ivy",
            })
        end)
    end
end

-- FzfLua
local fzflua_ok, fzflua_err = pcall(require, "fzf-lua")
if fzflua_ok then
    vim.keymap.set("n", "fgd", "<cmd>FzfLua lsp_definitions<CR>", { silent = true, desc = "Definitions" })
    vim.keymap.set("n", "fgD", "<cmd>FzfLua lsp_declarations<CR>", { silent = true, desc = "Declarations" })
    vim.keymap.set("n", "flr", "<cmd>FzfLua lsp_references<CR>", { silent = true, desc = "References" })
    vim.keymap.set("n", "flf", "<cmd>FzfLua lsp_finder<CR>", { silent = true, desc = "All lsp locations" })
    vim.keymap.set("n", "fli", "<cmd>FzfLua lsp_implementations<CR>", { silent = true, desc = "Implementations" })
    vim.keymap.set("n", "flt", "<cmd>FzfLua lsp_typedefs<CR>", { silent = true, desc = "Type definitions" })
    vim.keymap.set("n", "fca", "<cmd>FzfLua code_action<CR>", { silent = true, desc = "Code actions" })
    vim.keymap.set("n", "fic", "<cmd>FzfLua lsp_incoming_calls<CR>", { silent = true, desc = "Show incomming calls" })
    vim.keymap.set("n", "foc", "<cmd>FzfLua lsp_outgoing_calls<CR>", { silent = true, desc = "Show outgoging calls" })

    vim.keymap.set("n", "fgc", "<cmd>FzfLua git_commits<CR>", { silent = true, desc = "Git commit log(project)" })
    vim.keymap.set("n", "fgb", "<cmd>FzfLua git_bcommits<CR>", { silent = true, desc = "Git commit log(buffer)" })
    vim.keymap.set("n", "fgr", "<cmd>FzfLua grep_cword<CR>", { silent = true, desc = "Search word under cursor" })
end

-- Outline
local outline_ok, outline_err = pcall(require, "outline")
if outline_ok then
    vim.keymap.set("n", "<F12>", "<cmd>Outline<CR>", { silent = true, desc = "Toggle outline" })
end

-- Toggleterm
-- 设置toggleterm的快捷键，使其能够在打开终端的情况下切换到其他窗口
local toggleterm_ok, toggleterm_err = pcall(require, "toggleterm")
if toggleterm_ok then
    function _G.set_terminal_keymaps()
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = 0 })
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = 0 })
        -- 有些终端模拟器上，<Backspace>按键会发送0x08，与<C-h>一致，下面的映射就可能导致<BS>失效，需要修改终端模拟对<BS>的配置
        vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<CR>]], { buffer = 0 })
        vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<CR>]], { buffer = 0 })
        vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<CR>]], { buffer = 0 })
        vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<CR>]], { buffer = 0 })
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { buffer = 0 })
    end
end

-- Trouble
-- diagnostic键映射
local trouble_ok, trouble_err = pcall(require, "trouble")
if trouble_ok then
    vim.keymap.set(
        "n",
        "<LocalLeader>xx",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        { silent = true, desc = "Trouble diagnostic toggle" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>xw",
        "<cmd>Trouble workspace_diagnostics toggle<cr>",
        { silent = true, desc = "" }
    )
    vim.keymap.set("n", "<LocalLeader>xd", "<cmd>Trouble document_diagnostics toggle<cr>", { silent = true, desc = "" })
    vim.keymap.set("n", "<LocalLeader>xl", "<cmd>Trouble loclist toggle<cr>", { silent = true, desc = "" })
    vim.keymap.set("n", "<LocalLeader>xq", "<cmd>Trouble quickfix toggle<cr>", { silent = true, desc = "" })
    vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<cr>", { silent = true, desc = "" })
end

-- lspsaga
local lspsaga_ok, lspsaga_err = pcall(require, "lspsaga")
if lspsaga_ok then
    vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true, desc = "Lspsaga hover" })
    vim.keymap.set("n", "pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true, desc = "Lspsaga peek_definition" })
    vim.keymap.set(
        "n",
        "<LocalLeader>ca",
        "<cmd>Lspsaga code_action<CR>",
        { silent = true, desc = "Lspsaga code actions" }
    )
end

-- nvim-dap
local dap_ok, dap_err = pcall(require, "dap")
if dap_ok then
    vim.keymap.set("n", "<F5>", "<cmd>DapContinue<CR>", { silent = true, desc = "launch/continue debug" })
    vim.keymap.set("n", "<F29>", "<cmd>DapTerminate<CR>", { silent = true, desc = "terminate debug" })
    vim.keymap.set("n", "<F6>", "<cmd>DapToggleBreakpoint<CR>", { silent = true, desc = "toggle breakpoint" })
    vim.keymap.set("n", "<F30>", "<cmd>DapClearBreakpoints<CR>", { silent = true, desc = "clear breakpoints" })
    vim.keymap.set("n", "<F10>", "<cmd>DapStepOver<CR>", { silent = true, desc = "step over" })
    vim.keymap.set("n", "<F11>", "<cmd>DapStepInto<CR>", { silent = true, desc = "step into" })
    vim.keymap.set("n", "<F23>", "<cmd>DapStepOut<CR>", { silent = true, desc = "step out" })
    -- nvim-view-dap
    local view_dap_ok, view_dap_err = pcall(require, "dap-view")
    if view_dap_ok then
        vim.keymap.set("n", "<LocalLeader>dw", "<cmd>DapViewWatch<CR>", { silent = true, desc = "step out" })
    end
end

-- gitsigns
_G.set_gitsign_keymap = function(bufnr)
    -- local bufnr = args.buf
    vim.keymap.set("n", "]c", function()
        -- diff模式时返回]c，用来触发默认动作
        if vim.wo.diff then
            return "]c"
        end
        vim.schedule(function()
            require("gitsigns").nav_hunk("next", { preview = true, target = "all" })
        end)
        -- 延迟一小段时间后执行居中
        --  -- 使用 feedkeys 模拟按键
        vim.defer_fn(function()
            vim.cmd("normal! zz")
        end, 10) -- 10ms延迟
        return "<Ignore>"
    end, { expr = true, buffer = bufnr, desc = "Jump next diff" })
    vim.keymap.set("n", "[c", function()
        -- diff模式时返回]c，用来触发默认动作
        if vim.wo.diff then
            return "[c"
        end
        vim.schedule(function()
            require("gitsigns").nav_hunk("prev", {
                preview = true,
                target = "unstaged",
            })
        end)
        -- 延迟一小段时间后执行居中
        vim.defer_fn(function()
            vim.cmd("normal! zz")
        end, 10) -- 10ms延迟
        return "<Ignore>"
    end, { expr = true, buffer = bufnr, desc = "Jump prev diff" })

    -- hunk stage
    vim.keymap.set("n", "<LocalLeader>hs", function()
        require("gitsigns").stage_hunk()
    end, { buffer = bufnr, desc = "Stage hunk" })
    -- hunk unstage
    vim.keymap.set("n", "<LocalLeader>hu", function()
        require("gitsigns").undo_stage_hunk()
    end, { buffer = bufnr, desc = "Unstage hunk" })
    -- hunk reset
    vim.keymap.set("n", "<LocalLeader>hr", function()
        require("gitsigns").reset_hunk()
    end, { buffer = bufnr, desc = "Reset hunk" })
    -- buffer stage
    vim.keymap.set("n", "<LocalLeader>bs", function()
        require("gitsigns").stage_buffer()
    end, { buffer = bufnr, desc = "Stage buffer" })
    -- buffer stage
    vim.keymap.set("n", "<LocalLeader>br", function()
        require("gitsigns").reset_buffer()
    end, { buffer = bufnr, desc = "Reset buffer" })
    -- buffer blame
    vim.keymap.set("n", "<LocalLeader>gb", function()
        require("gitsigns").blame()
    end, { buffer = bufnr, desc = "Blame buffer" })
    -- buffer line blame
    vim.keymap.set("n", "<LocalLeader>bl", function()
        require("gitsigns").blame_line()
    end, { buffer = bufnr, desc = "Blame line" })
end

-- neogit
local neogit_ok, neogit_err = pcall(require, "neogit")
if neogit_ok then
    vim.keymap.set("n", "<LocalLeader>ng", "<cmd>Neogit<CR>", { silent = true, desc = "Neogit" })
end

--lspconfig
vim.keymap.set("n", "<LocalLeader>sl", function()
    custom_lsp.start_lsp()
end, { buffer = bufnr, desc = "Start lsp client" })
vim.keymap.set("n", "<LocalLeader>abc", function()
    custom_lsp.attach_buffer()
end, { buffer = bufnr, desc = "Attach current buffer" })
vim.keymap.set("n", "<LocalLeader>aba", function()
    custom_lsp.attach_all()
end, { buffer = bufnr, desc = "Attach all buffer" })
vim.keymap.set("n", "<LocalLeader>dbc", function()
    custom_lsp.detach_current()
end, { buffer = bufnr, desc = "Detach current buffer from client" })
vim.keymap.set("n", "<LocalLeader>dba", function()
    custom_lsp.detach_all()
end, { buffer = bufnr, desc = "Detach all buffers from client" })
vim.keymap.set("n", "<LocalLeader>dbo", function()
    custom_lsp.detach_others()
end, { buffer = bufnr, desc = "Detach other buffers from client" })

local ts_textobject_ok, ts_textobject_err = pcall(require, "nvim-treesitter-textobjects")
if ts_textobject_ok then
    -- nvim-treesitter-textobject
    -- -- 快捷键映射
    vim.keymap.set("n", "]f", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer")
    end, { desc = "Next function" })

    vim.keymap.set("n", "[f", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer")
    end, { desc = "Previous function" })

    vim.keymap.set("n", "]i", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@conditional.outer")
    end, { desc = "Next if statement" })

    vim.keymap.set("n", "[i", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@conditional.outer")
    end, { desc = "Previous if statement" })

    -- You can use the capture groups defined in `textobjects.scm`
    vim.keymap.set({ "x", "o" }, "af", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
    end)
    vim.keymap.set({ "x", "o" }, "if", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
    end)
    vim.keymap.set({ "x", "o" }, "ai", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer", "textobjects")
    end)
end

-- 判断 bullets 是否可用
local function has_bullets()
    return vim.fn.exists("*bullets#init") == 1
end

-- insert 模式 Tab → bullets 缩进
vim.keymap.set("i", "<Tab>", function()
    if has_bullets() and vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
        return "<Plug>(bullets-demote)"
    end
    return "\t"
end, { expr = true })

-- insert 模式 Shift-Tab → 反缩进
vim.keymap.set("i", "<S-Tab>", function()
    if has_bullets() and vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
        return "<Plug>(bullets-promote)"
    end
    return "<S-Tab>"
end, { expr = true })

-- zen-mode
local zen_mode_ok, zen_mode_err = pcall(require, "zen-mode")
if zen_mode_ok then
    vim.keymap.set("n", "<LocalLeader>z", "<cmd>ZenMode<cr>")
end
