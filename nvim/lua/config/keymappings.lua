----------------------------------------------------------Basic-------------------------------------------------------------
local custom_function = require("config.custom_function")
local platform = require("config.platform")

vim.keymap.set(
    { "n", "v" },
    "<LocalLeader>q",
    "<cmd>q<CR>",
    { noremap = true, silent = true, desc = "关闭当前窗口" }
)
vim.keymap.set(
    { "n", "v" },
    "<LocalLeader>w",
    "<cmd>w<CR>",
    { noremap = true, silent = true, desc = "保存当前buffer" }
)
vim.keymap.set(
    { "n", "v" },
    "<LocalLeader>qa",
    "<cmd>qa<CR>",
    { noremap = true, silent = true, desc = "退出所有窗口" }
)
-- Normal / Visual 模式直接保存
vim.keymap.set({ "n", "v" }, "<C-s>", "<cmd>w<CR>", {
    noremap = true,
    silent = true,
    desc = "保存修改内容",
})

-- Insert 模式先退出到 Normal 再保存
vim.keymap.set("i", "<C-s>", "<Esc><cmd>w<CR>", {
    noremap = true,
    silent = true,
    desc = "切换为Normal并保存",
})

-- 查找
-- 自动将查找到的字符串设置到屏幕中央
vim.keymap.set("n", "n", "nzz", { noremap = true, silent = true, desc = "查找并自动跳转屏幕中间" })
vim.keymap.set("n", "N", "Nzz", { noremap = true, silent = true, desc = "查找并自动跳转屏幕中间" })

-- 将单行内选中的字符串当作文件打开
vim.keymap.set(
    "v",
    "<LocalLeader>of",
    custom_function.open_selected_file,
    { noremap = true, silent = true, desc = "打开文件" }
)

-- 扩展复制
vim.keymap.set({ "n", "x" }, "<LocalLeader>yy", function()
    custom_function.copy_with_metadata(0)
end, {
    noremap = true,
    silent = true,
    desc = "复制（含文件名和行号）",
})
vim.keymap.set({ "n", "x" }, "<LocalLeader>yf", function()
    custom_function.copy_with_metadata(1)
end, {
    noremap = true,
    silent = true,
    desc = "复制（含完整路径和行号）",
})
vim.keymap.set({ "n", "x" }, "<LocalLeader>yr", function()
    custom_function.copy_with_metadata(2)
end, {
    noremap = true,
    silent = true,
    desc = "复制（含相对项目路径和行号）",
})
-- 获取当前文件所在的路径名
vim.keymap.set("n", "<LocalLeader>yp", custom_function.copy_current_filepath, {
    noremap = true,
    silent = true,
    desc = "仅复制当前文件路径",
})
-- 拷贝当前行的commit sha
vim.keymap.set("n", "<LocalLeader>yc", custom_function.get_line_commit, {
    noremap = true,
    silent = true,
    desc = "获取当前行的提交 SHA",
})

-- 对比当前行的commit与当前buffer的文件差异
vim.keymap.set("n", "<LocalLeader>gd", custom_function.git_diff_with_commit_sha, {
    noremap = true,
    silent = true,
    desc = "对比当前行与git commit的差异",
})

-- 普通模式下在当前位置插入时间
vim.keymap.set("n", "<LocalLeader>ta", "a<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    noremap = true,
    silent = true,
    desc = "追加插入本地化时间",
})
-- 普通模式下在上一行插入时间
vim.keymap.set("n", "<LocalLeader>tO", "O<C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR><ESC>", {
    noremap = true,
    silent = true,
    desc = "在上一行插入本地化时间",
})

-- 在当前函数上方插入注释
vim.keymap.set(
    "n",
    "<LocalLeader>fO",
    "<cmd>NvimComment function<CR>",
    { noremap = true, silent = true, desc = "在当前函数上方插入注释" }
)
-- 在当前变量上方插入注释
vim.keymap.set(
    "n",
    "<LocalLeader>vO",
    "<cmd>NvimComment variable<CR>",
    { noremap = true, silent = true, desc = "在当前变量上方插入注释" }
)
-- 在当前宏上方插入注释
vim.keymap.set(
    "n",
    "<LocalLeader>mO",
    "<cmd>NvimComment macro<CR>",
    { noremap = true, silent = true, desc = "在当前宏上方插入注释" }
)

-- 原生lsp
vim.keymap.set("n", "<LocalLeader>lr", function()
    vim.lsp.buf.references()
end, {
    noremap = true,
    silent = true,
    desc = "LSP 引用",
})

-- tab快捷键
-- Move to previous/next
vim.keymap.set(
    { "i", "n" },
    "<A-Up>",
    "<cmd>tabprevious<CR>",
    { noremap = true, silent = true, desc = "上一个标签页" }
)
vim.keymap.set(
    { "i", "n" },
    "<A-Down>",
    "<cmd>tabnext<CR>",
    { noremap = true, silent = true, desc = "下一个标签页" }
)
-- tab
-- 使用LocalLeader的原因防止误操作
vim.keymap.set(
    { "i", "n" },
    "<LocalLeader>tn",
    "<cmd>$tabnew<CR>",
    { noremap = true, silent = true, desc = "在末尾新建标签页" }
)
vim.keymap.set(
    { "i", "n" },
    "<LocalLeader>to",
    "<cmd>tabonly<CR>",
    { noremap = true, silent = true, desc = "仅保留当前标签页" }
)

vim.keymap.set({ "i", "n" }, "<A-t>", function()
    local input = vim.fn.input("请输入要跳转的 Tab Number: ")

    -- 空输入
    if input == nil or input == "" then
        vim.notify("未输入 Tab Number", vim.log.levels.INFO)
        return
    end

    -- 必须是正整数
    if not input:match("^%d+$") then
        vim.notify(string.format("'%s' 不是合法的 Tab Number", input), vim.log.levels.INFO)
        return
    end

    local tabnr = tonumber(input)

    local tabs = vim.api.nvim_list_tabpages()

    if tabnr < 1 or tabnr > #tabs then
        vim.notify(string.format("Tab %d 不存在，当前共有 %d 个 Tab", tabnr, #tabs), vim.log.levels.INFO)
        return
    end

    vim.api.nvim_set_current_tabpage(tabs[tabnr])
end, {
    noremap = true,
    silent = true,
    desc = "交互式跳转到指定 Tab",
})

-- buffer 快捷键
vim.keymap.set(
    { "i", "n" },
    "<A-.>",
    "<cmd>bnext<CR>",
    { noremap = true, silent = true, desc = "下一个缓冲区" }
)
vim.keymap.set(
    { "i", "n" },
    "<A-,>",
    "<cmd>bprevious<CR>",
    { noremap = true, silent = true, desc = "上一个缓冲区" }
)
vim.keymap.set(
    { "i", "n" },
    "<A-Right>",
    "<cmd>bnext<CR>",
    { noremap = true, silent = true, desc = "下一个缓冲区" }
)
vim.keymap.set(
    { "i", "n" },
    "<A-Left>",
    "<cmd>bprevious<CR>",
    { noremap = true, silent = true, desc = "上一个缓冲区" }
)
-- 解决偶发一次删除多个buffer的现象
vim.keymap.set({ "i", "n" }, "<A-d>", function()
    local current = vim.api.nvim_get_current_buf()
    vim.cmd("bprevious") -- 或 bnext
    vim.cmd("bdelete " .. current)
end, { noremap = true, silent = true, desc = "删除当前缓冲区" })

vim.keymap.set({ "i", "n" }, "<A-b>", function()
    local input = vim.fn.input("请输入要跳转的 Buffer Number: ")

    -- 空输入
    if input == nil or input == "" then
        vim.notify("未输入 Buffer Number", vim.log.levels.INFO)
        return
    end

    -- 非数字
    local bufnr = tonumber(input)
    if not bufnr then
        vim.notify(string.format("'%s' 不是有效的 Buffer Number", input), vim.log.levels.INFO)
        return
    end

    -- Buffer 不存在
    if not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify(string.format("Buffer %d 不存在", bufnr), vim.log.levels.INFO)
        return
    end

    vim.api.nvim_set_current_buf(bufnr)
end, {
    noremap = true,
    silent = true,
    desc = "交互式跳转到指定 Buffer",
})

-- 调整窗口小
vim.keymap.set(
    "n",
    "<C-Up>",
    "<cmd>resize -1<CR>",
    { noremap = true, silent = true, desc = "窗口高度减少大小 -1" }
)
vim.keymap.set(
    "n",
    "<C-Down>",
    "<cmd>resize +1<CR>",
    { noremap = true, silent = true, desc = "窗口高度增加大小 +1" }
)
vim.keymap.set(
    "n",
    "<C-Left>",
    "<cmd>vertical resize -3<CR>",
    { noremap = true, silent = true, desc = "窗口宽度调整 -3" }
)
vim.keymap.set(
    "n",
    "<C-Right>",
    "<cmd>vertical resize +3<CR>",
    { noremap = true, silent = true, desc = "窗口宽度调整 +3" }
)

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
vim.keymap.set(
    "n",
    "<space>e",
    open_optimized_diagnostic_float,
    { noremap = true, silent = true, desc = "打开诊断浮动窗口" }
)
vim.keymap.set(
    "n",
    "[d",
    custom_function.diagnostic_goto_prev,
    { noremap = true, silent = true, desc = "跳转到上一个诊断" }
)
vim.keymap.set(
    "n",
    "]d",
    custom_function.diagnostic_goto_next,
    { noremap = true, silent = true, desc = "跳转到下一个诊断" }
)
vim.keymap.set(
    "n",
    "<space>q",
    vim.diagnostic.setloclist,
    { noremap = true, silent = true, desc = "将诊断加入位置列表" }
)

vim.keymap.set(
    "n",
    "<LocalLeader>ac",
    custom_function.align_column,
    { noremap = true, silent = true, desc = "对齐列（末端对齐）" }
)

vim.keymap.set("n", "[[", "[[zt", {
    noremap = true,
    silent = true,
    desc = "跳转到上一个段落并居中",
})

----------------------------------------------------------Plugins-------------------------------------------------------------
-- nvim-ufo
-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
-- vim.keymap.set("n", "zR", require("ufo").openAllFolds, { noremap=true,silent = true, desc = "展开所有折叠" })
-- vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { noremap=true,silent = true, desc = "关闭所有折叠" })

if platform.is_linux or platform.is_mac then
    -- 格式化
    -- vim.keymap.set({ "n", "v" }, "<space>f", require("conform").format, {noremap=true, silent=true, desc = "格式化当前缓冲区" })
    -- 快捷键配置
    vim.keymap.set({ "n", "v" }, "<space>f", function(args)
        local ok, conform = pcall(require, "conform")
        if not ok then
            vim.notify("conform not installed or enabled", vim.log.levels.WARN)
            return
        end
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

            conform.format({
                lsp_fallback = false,
                -- async: 是否异步执行格式化。
                -- 作用: 控制 conform 是否以异步方式运行格式化程序以避免阻塞 UI。
                -- 取值范围: boolean (true/false)。
                -- 当前取值含义: true -> 异步执行，格式化在后台进行，不会阻塞编辑器交互。
                async = true,
                timeout_ms = 5000,
                range = range,
            })
        else -- 普通模式（格式化整个文件）
            conform.format({
                lsp_fallback = false,
                -- async: 是否异步执行格式化。
                -- 作用: 控制 conform 是否以异步方式运行格式化程序以避免阻塞 UI。
                -- 取值范围: boolean (true/false)。
                -- 当前取值含义: true -> 异步执行，格式化在后台进行，不会阻塞编辑器交互。
                async = true,
                timeout_ms = 5000,
            })
        end
    end, { noremap = true, silent = true, desc = "格式化文件或选中区域" })
end

-- 文件树
vim.keymap.set(
    { "n", "v", "i" },
    "<F2>",
    "<cmd>NvimTreeToggle<CR>",
    { noremap = true, silent = ture, desc = "打开文件树" }
)

if platform.is_linux or platform.is_mac then
    -- CodeCompanion
    vim.keymap.set(
        { "n", "v" },
        "<LocalLeader>aa",
        "<cmd>CodeCompanionActions<CR>",
        { noremap = true, silent = true, desc = "打开 CodeCompanion Actions" }
    )

    vim.keymap.set({ "n" }, "<LocalLeader>ch", "<cmd>CodeCompanionHistory<CR>", {
        desc = "打开聊天历史列表",
        noremap = true,
        silent = true,
    })

    vim.keymap.set({ "n", "v" }, "<LocalLeader>cl", function()
        local ok, cc = pcall(require, "codecompanion")
        if not ok then
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
            return
        end
        cc.cli({ focus = true })
    end, {
        desc = "打开 CodeCompanion CLI",
        -- 这里必须注释，因为在codecompanion cli界面需要将快捷键继续扩展
        -- noremap = true,
        silent = true,
    })

    -- 如果你在 CLI 窗口里，调用 toggle() → 会隐藏 CLI，再次调用会重新显示。
    -- 如果你在 chat 窗口里，调用 toggle() → 同样是隐藏/显示 chat。
    -- 如果你同时有多个交互（chat + CLI），可以用 { 和 } 在它们之间循环切换，而 toggle() 是针对当前交互窗口的开关。
    vim.keymap.set({ "n", "v" }, "<LocalLeader>ct", function()
        local ok, cc = pcall(require, "codecompanion")
        if not ok then
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
        end
        cc.toggle()
    end, {
        desc = "切换当前 CodeCompanion 窗口",
        noremap = true,
        silent = true,
    })

    -- 在当前 buffer 或选区中触发 CodeCompanion 的 CLI 提示，弹出输入框以手动输入自定义提示并与代理交互。
    -- #{this} → 普通模式下是当前 buffer，视觉模式下是选区。
    -- #{terminal} -> 终端输出
    -- 可以用 #{buffer}、#{buffers}、#{diagnostics} 等引用
    vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
        local ok, cc = pcall(require, "codecompanion")
        if not ok then
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
        end
        cc.cli({
            -- 是否打开输入缓冲区, true表示打开
            -- 输入缓冲区 → 支持复杂提示和 slash 命令。
            prompt = true,
            -- 是否切入cli窗口，默认为true表示切入
            focus = false,
            -- 是否自动提交提示， 默认为false
            -- prompt为true时，submit会失效，只有直接传入字符串才会生效
            submit = true,
        })
    end, { noremap = true, silent = true, desc = "向 CLI 代理发送提示" })

    -- 解释这段代码
    -- 在chat解释代码
    vim.keymap.set({ "v" }, "<LocalLeader>ae", function()
        local ok, cc = pcall(require, "codecompanion")
        if ok then
            cc.prompt("tplink_explain_code_view")
        else
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
        end
    end, { noremap = true, silent = true, desc = "通过Chat Prompt解释当前代码" })

    vim.keymap.set({ "n", "v" }, "<LocalLeader>ce", function()
        local ok, cc = pcall(require, "codecompanion")
        if not ok then
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
            return
        end
        cc.cli("#{this} 请解释这段代码", { focus = false, submit = true })
    end, { noremap = true, silent = true, desc = "通过CLI解释当前代码" })

    vim.keymap.set({ "v" }, "<LocalLeader>at", function()
        local ok, cc = pcall(require, "codecompanion")
        if ok then
            cc.prompt("tplink_translate")
        else
            vim.notify("CodeCompanion not installed or enabled", vim.log.levels.WARN)
        end
    end, { noremap = true, silent = true, desc = "通过Chat Prompt翻译当前内容" })
end

-- telescope
-- " Find files using Telescope command-line sugar.
-- live-grep 依赖于外部工具ripgrep， sudo apt install ripgrep
vim.keymap.set("n", "tfr", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.find_files()
end, { noremap = true, silent = true, desc = "搜索文件" })

vim.keymap.set("n", "tht", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.help_tags()
end, { noremap = true, silent = true, desc = "列出可用的帮助标签" })

vim.keymap.set("n", "tgs", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.grep_string({ cwd = vim.fn.expand("%:p:h") })
end, {
    noremap = true,
    silent = true,
    desc = "在当前工作目录中搜索光标下的字符串",
})

vim.keymap.set("n", "tlg", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.live_grep({ cwd = vim.fn.expand("%:p:h") })
end, { noremap = true, silent = true, desc = "实时搜索字符串并显示结果" })

vim.keymap.set("n", "tlb", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.buffers()
end, { noremap = true, silent = true, desc = "列出当前 Neovim 实例中的打开缓冲区" })

vim.keymap.set("n", "tts", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.treesitter()
end, {
    noremap = true,
    silent = true,
    desc = "列出来自 treesitter 查询的函数名、变量和其他符号",
})

vim.keymap.set("n", "tgd", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.lsp_definitions({ jump_type = "never" })
end, { noremap = true, silent = true, desc = "跳转到光标下单词的定义" })

vim.keymap.set("n", "tgb", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.git_branches({ jump_type = "never" })
end, {
    noremap = true,
    silent = true,
    desc = "列出当前目录的分支（在预览窗口显示）",
})

vim.keymap.set("n", "tgc", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.git_commits({ jump_type = "never" })
end, { noremap = true, silent = true, desc = "列出当前目录的提交（带差异预览）" })

vim.keymap.set("n", "tbc", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.git_bcommits({ jump_type = "never" })
end, { noremap = true, silent = true, desc = "列出当前缓冲区的提交（带差异预览）" })

vim.keymap.set("n", "tlr", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.lsp_references()
end, { noremap = true, silent = true, desc = "列出光标下单词的 LSP 引用" })

vim.keymap.set("n", "tcs", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.colorscheme({ enable_preview = true })
end, { noremap = true, silent = true, desc = "更改配色并预览" })

vim.keymap.set("n", "tic", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.lsp_incoming_calls()
end, {
    noremap = true,
    silent = true,
    desc = "列出光标下单词的 LSP 传入调用，跳转到引用处",
})
vim.keymap.set("n", "toc", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.lsp_outgoing_calls()
end, {
    noremap = true,
    silent = true,
    desc = "列出光标下单词的 LSP 传出调用，跳转到引用处",
})

vim.keymap.set("n", "tff", function()
    local ok, _ = pcall(require, "telescope._extensions.frecency")
    if not ok then
        vim.notify("telescope-frecency not installed or enabled", vim.log.levels.WARN)
        return
    end

    local ok, telescope = pcall(require, "telescope")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end
    telescope.extensions.frecency.frecency({
        workspace = "CWD",
        path_display = { "shorten" },
        theme = "ivy",
    })
end, { noremap = true, silent = true, desc = "frecency 搜索（短路径，ivy 主题）" })
vim.keymap.set("n", "tfw", function()
    local ok, _ = pcall(require, "telescope._extensions.frecency")
    if not ok then
        vim.notify("telescope-frecency not installed or enabled", vim.log.levels.WARN)
        return
    end

    local ok, telescope = pcall(require, "telescope")
    if not ok then
        vim.notify("telescope not installed or enabled", vim.log.levels.WARN)
        return
    end

    telescope.extensions.frecency.frecency({
        workspace = "CWD",
    })
end, { noremap = true, silent = true, desc = "frecency 搜索（工作区）" })

if platform.is_linux or platform.is_mac then
    -- FzfLua
    vim.keymap.set("n", "fgd", "<cmd>FzfLua lsp_definitions<CR>", { noremap = true, silent = true, desc = "定义" })
    vim.keymap.set("n", "fgD", "<cmd>FzfLua lsp_declarations<CR>", { noremap = true, silent = true, desc = "声明" })
    vim.keymap.set("n", "flr", "<cmd>FzfLua lsp_references<CR>", { noremap = true, silent = true, desc = "引用" })
    vim.keymap.set(
        "n",
        "flf",
        "<cmd>FzfLua lsp_finder<CR>",
        { noremap = true, silent = true, desc = "所有 LSP 位置" }
    )
    vim.keymap.set(
        "n",
        "fli",
        "<cmd>FzfLua lsp_implementations<CR>",
        { noremap = true, silent = true, desc = "实现" }
    )
    vim.keymap.set("n", "flt", "<cmd>FzfLua lsp_typedefs<CR>", { noremap = true, silent = true, desc = "类型定义" })
    vim.keymap.set("n", "fca", "<cmd>FzfLua code_action<CR>", { noremap = true, silent = true, desc = "代码操作" })
    vim.keymap.set(
        "n",
        "fic",
        "<cmd>FzfLua lsp_incoming_calls<CR>",
        { noremap = true, silent = true, desc = "显示传入调用" }
    )
    vim.keymap.set(
        "n",
        "foc",
        "<cmd>FzfLua lsp_outgoing_calls<CR>",
        { noremap = true, silent = true, desc = "显示传出调用" }
    )

    vim.keymap.set(
        "n",
        "fgc",
        "<cmd>FzfLua git_commits<CR>",
        { noremap = true, silent = true, desc = "Git 提交日志（项目）" }
    )
    vim.keymap.set(
        "n",
        "fgb",
        "<cmd>FzfLua git_bcommits<CR>",
        { noremap = true, silent = true, desc = "Git 提交日志（缓冲区）" }
    )
    vim.keymap.set(
        "n",
        "fgr",
        "<cmd>FzfLua grep_cword<CR>",
        { noremap = true, silent = true, desc = "搜索光标下的单词" }
    )

    -- Outline
    vim.keymap.set("n", "<F12>", "<cmd>Outline<CR>", { noremap = true, silent = true, desc = "切换大纲" })

    -- Toggleterm
    -- 设置toggleterm的快捷键，使其能够在打开终端的情况下切换到其他窗口
    function _G.set_terminal_keymaps()
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], { noremap = true, silent = true, buffer = 0 })
        -- 有些终端模拟器上，<Backspace>按键会发送0x08，与<C-h>一致，下面的映射就可能导致<BS>失效，需要修改终端模拟对<BS>的配置
        vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<CR>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<CR>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<CR>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<CR>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { noremap = true, silent = true, buffer = 0 })
        vim.keymap.set("t", "<C-q>", function()
            local job_id = vim.b.terminal_job_id
            if job_id then
                vim.fn.jobstop(job_id)
            end
            vim.api.nvim_buf_delete(0, { force = true })
        end, { noremap = true, silent = true, buffer = 0 })
    end

    -- Trouble
    -- diagnostic键映射
    vim.keymap.set(
        "n",
        "<LocalLeader>xx",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        { noremap = true, silent = true, desc = "切换 Trouble 诊断" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>xw",
        "<cmd>Trouble workspace_diagnostics toggle<cr>",
        { noremap = true, silent = true, desc = "切换工作区诊断" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>xd",
        "<cmd>Trouble document_diagnostics toggle<cr>",
        { noremap = true, silent = true, desc = "切换文档诊断" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>xl",
        "<cmd>Trouble loclist toggle<cr>",
        { noremap = true, silent = true, desc = "切换位置列表诊断" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>xq",
        "<cmd>Trouble quickfix toggle<cr>",
        { noremap = true, silent = true, desc = "切换 quickfix 诊断" }
    )
    vim.keymap.set(
        "n",
        "gR",
        "<cmd>Trouble lsp_references toggle<cr>",
        { noremap = true, silent = true, desc = "切换 Trouble 中的 LSP 引用" }
    )

    -- lspsaga
    vim.keymap.set(
        "n",
        "K",
        "<cmd>Lspsaga hover_doc<CR>",
        { noremap = true, silent = true, desc = "Lspsaga 查看文档" }
    )
    vim.keymap.set(
        "n",
        "pd",
        "<cmd>Lspsaga peek_definition<CR>",
        { noremap = true, silent = true, desc = "Lspsaga 查看定义" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>ca",
        "<cmd>Lspsaga code_action<CR>",
        { noremap = true, silent = true, desc = "Lspsaga 代码扩展" }
    )

    -- nvim-dap
    vim.keymap.set("n", "<F5>", "<cmd>DapContinue<CR>", { noremap = true, silent = true, desc = "启动/继续调试" })
    vim.keymap.set("n", "<C-F5>", "<cmd>DapTerminate<CR>", { noremap = true, silent = true, desc = "终止调试" })
    vim.keymap.set(
        "n",
        "<F6>",
        "<cmd>DapToggleBreakpoint<CR>",
        { noremap = true, silent = true, desc = "切换断点" }
    )
    vim.keymap.set(
        "n",
        "<C-F6>",
        "<cmd>DapClearBreakpoints<CR>",
        { noremap = true, silent = true, desc = "清除断点" }
    )
    vim.keymap.set("n", "<F10>", "<cmd>DapStepOver<CR>", { noremap = true, silent = true, desc = "单步跳过" })
    vim.keymap.set("n", "<F11>", "<cmd>DapStepInto<CR>", { noremap = true, silent = true, desc = "单步进入" })
    vim.keymap.set("n", "<S-F11>", "<cmd>DapStepOut<CR>", { noremap = true, silent = true, desc = "单步跳出" })
    -- nvim-view-dap
    vim.keymap.set(
        "n",
        "<LocalLeader>dw",
        "<cmd>DapViewWatch<CR>",
        { noremap = true, silent = true, desc = "单步跳出" }
    )
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
    end, { noremap = true, silent = true, expr = true, buffer = bufnr, desc = "跳到下一个差异" })
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
    end, { noremap = true, silent = true, expr = true, buffer = bufnr, desc = "跳到上一个差异" })

    -- hunk stage
    vim.keymap.set("n", "<LocalLeader>hs", function()
        require("gitsigns").stage_hunk()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "暂存补丁块" })
    -- hunk unstage
    vim.keymap.set("n", "<LocalLeader>hu", function()
        require("gitsigns").undo_stage_hunk()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "取消暂存补丁块" })
    -- hunk reset
    vim.keymap.set("n", "<LocalLeader>hr", function()
        require("gitsigns").reset_hunk()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "重置补丁块" })
    -- buffer stage
    vim.keymap.set("n", "<LocalLeader>bs", function()
        require("gitsigns").stage_buffer()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "暂存缓冲区" })
    -- buffer stage
    vim.keymap.set("n", "<LocalLeader>br", function()
        require("gitsigns").reset_buffer()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "重置缓冲区" })
    -- buffer blame
    vim.keymap.set("n", "<LocalLeader>gb", function()
        require("gitsigns").blame()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "查看缓冲区 Blame" })
    -- buffer line blame
    vim.keymap.set("n", "<LocalLeader>bl", function()
        require("gitsigns").blame_line()
    end, { noremap = true, silent = true, buffer = bufnr, desc = "查看当前行的 Blame" })
end

-- neogit
vim.keymap.set("n", "<LocalLeader>ng", "<cmd>Neogit<CR>", { noremap = true, silent = true, desc = "Neogit" })

--lspconfig
if platform.is_linux or platform.is_mac then
    vim.keymap.set(
        "n",
        "<LocalLeader>abc",
        "<cmd>LspAttachBuffer<CR>",
        { noremap = true, silent = true, buffer = bufnr, desc = "附加当前缓冲区" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>aba",
        "<cmd>LspAttachAll<CR>",
        { noremap = true, silent = true, buffer = bufnr, desc = "附加所有缓冲区" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>dbc",
        "<cmd>LspDetachBuffer<CR>",
        { noremap = true, silent = true, buffer = bufnr, desc = "分离当前缓冲区" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>dba",
        "<cmd>LspDetachAll<CR>",
        { noremap = true, silent = true, buffer = bufnr, desc = "分离所有缓冲区" }
    )
    vim.keymap.set(
        "n",
        "<LocalLeader>dbo",
        "<cmd>LspDetachOthers<CR>",
        { noremap = true, silent = true, buffer = bufnr, desc = "分离其他缓冲区" }
    )
end

-- nvim-treesitter-textobject
-- -- 快捷键映射
vim.keymap.set("n", "]f", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.goto_next_start("@function.outer")
end, { noremap = true, silent = true, desc = "下一个 function" })

vim.keymap.set("n", "[f", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.goto_previous_start("@function.outer")
end, { noremap = true, silent = true, desc = "上一个 function" })

vim.keymap.set("n", "]i", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.goto_next_start("@conditional.outer")
end, { noremap = true, silent = true, desc = "下一个 if 语句" })

vim.keymap.set("n", "[i", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.goto_previous_start("@conditional.outer")
end, { noremap = true, silent = true, desc = "上一个 if 语句" })

-- You can use the capture groups defined in `textobjects.scm`
vim.keymap.set({ "x", "o" }, "af", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.select")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.select_textobject("@function.outer", "textobjects")
end, { noremap = true, silent = true, desc = "选择整个函数" })
vim.keymap.set({ "x", "o" }, "if", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.select")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.select_textobject("@function.inner", "textobjects")
end, { noremap = true, silent = true, desc = "选择函数内部" })
vim.keymap.set({ "x", "o" }, "ai", function()
    local ok, treesitter = pcall(require, "nvim-treesitter-textobjects.select")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not installed or enabled", vim.log.levels.WARN)
        return
    end
    treesitter.select_textobject("@conditional.outer", "textobjects")
end, { noremap = true, silent = true, desc = "选择整个条件语句" })

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
end, { noremap = true, silent = true, expr = true })

-- insert 模式 Shift-Tab → 反缩进
vim.keymap.set("i", "<S-Tab>", function()
    if has_bullets() and vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
        return "<Plug>(bullets-promote)"
    end
    return "<S-Tab>"
end, { noremap = true, silent = true, expr = true })

-- zen-mode
vim.keymap.set("n", "<LocalLeader>z", "<cmd>ZenMode<cr>", { noremap = true, silent = true, desc = "专注模式" })

vim.keymap.set("n", "]t", function()
    local ok, todo = pcall(require, "todo-comments")
    if not ok then
        vim.notify("todo-comments not installed or enabled", vim.log.levels.WARN)
        return
    end
    todo.jump_next()
end, { noremap = true, silent = true, desc = "跳转到下一个 TODO 注释" })

-- todo-comments
vim.keymap.set("n", "[t", function()
    local ok, todo = pcall(require, "todo-comments")
    if not ok then
        vim.notify("todo-comments not installed or enabled", vim.log.levels.WARN)
        return
    end
    todo.jump_prev()
end, { noremap = true, silent = true, desc = "跳转到上一个 TODO 注释" })

-- gerrit
vim.keymap.set("n", "<LocalLeader>gr", function()
    local change = vim.fn.input("Change: ")
    if change ~= "" then
        vim.cmd("Gerrit " .. change)
    end
end, { noremap = true, silent = true, desc = "Gerrit" })
vim.keymap.set(
    "n",
    "<LocalLeader>grd",
    "<cmd>Gerrit dashboard<CR>",
    { noremap = true, silent = true, desc = "Gerrit 仪表板" }
)
vim.keymap.set("n", "<LocalLeader>grf", function()
    local change = vim.fn.input("Change: ")
    if change ~= "" then
        vim.cmd("Gerrit diff " .. change)
    end
end, { noremap = true, silent = true, desc = "查看 Gerrit 差异" })

-- which-key
vim.keymap.set("n", "<LocalLeader>?", "<cmd>WhichKey<CR>", { noremap = true, silent = true, desc = "查看快捷键" })
