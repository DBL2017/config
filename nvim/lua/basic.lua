-- 行号
vim.wo.number = true
--[[ vim.wo.relativenumber = true ]]

-- 字符编码 终端显示编码
vim.g.encoding = "UTF-8"
-- 文件编码
vim.o.fileencoding = "UTF-8"

-- 切换工作目录
-- vim.g.autchdir = true

-- 自动加载外部修改
vim.g.autoread = true

-- 自动跳转到匹配的括号
vim.g.showmatch = false

-- tab转空格
vim.bo.expandtab = true

-- tab占位符的宽度，不修改键入tab时的行为，可用来格式化对齐
vim.o.tabstop = 4

-- 键入tab时插入的空格数
vim.o.softtabstop = 4
vim.bo.softtabstop = 4
-- 由于tabstop==4，即tab占用4个字符长度；softtabstop==4，因此键入tab时插入4个空格。
-- 如果tabstop==8, softtabstop==4，则键入tab时会插入8个空格。
-- 如果expandtab==false, tabstop==8 and softtabstop==4，那么第一次键入tab会插入4个空格，第二次键入tab会替换之前空格为tab键（8）。

-- 自动缩进
vim.bo.autoindent = true
vim.bo.smartindent = true

-- 缩进时的空格数量
vim.o.shiftwidth = 4

-- 总是显示标签栏
vim.g.showtabline = 2

-- 缓冲区更新时间
vim.g.updatetime = 100

-- 查找结果高亮
vim.g.hlsearch = true
-- 增量查找
vim.g.incsearch = true
-- 循环查找
vim.o.wrapscan = false

-- quitfix命令打开新buffer时的行为
vim.o.switchbuf = "newtab"

-- 高亮当前行
vim.wo.cursorline = true

-- 显示左侧图标指示列
vim.wo.signcolumn = "yes"

-- 显示命令
vim.o.showcmd = true

-- 命令行高
vim.o.cmdheight = 1

-- 设置 timeoutlen 为等待键盘快捷键连击时间500毫秒，可根据需要设置
-- 遇到问题详见：https://github.com/nshen/learn-neovim-lua/issues/1
vim.o.timeoutlen = 500

-- split window 从下边和右边出现
vim.o.splitbelow = true
vim.o.splitright = false

-- 自动补全不自动选中
vim.g.completeopt = "menu,menuone,noselect,noinsert"

-- 样式
-- vim.o.termguicolors = true
-- vim.opt.termguicolors = true

-- 补全增强
vim.o.wildmenu = true

-- Dont' pass messages to |ins-completin menu|
vim.o.shortmess = vim.o.shortmess .. "c"

-- 补全最多显示10行
vim.o.pumheight = 10

-- 使用增强状态栏插件后不再需要 vim 的模式提示
vim.o.showmode = false

-- 配置剪切板
vim.opt.clipboard = "unnamedplus"

-- 启用高亮
vim.opt.termguicolors = true

-- 开启 Folding
vim.wo.foldmethod = "expr"
-- 默认全部折叠
vim.wo.foldlevel = 0

-- 禁用mouse
vim.opt.mouse = ""
vim.go.mouse = ""

-- 增添此项原因是为了解决在不选择提示的情况，nvim-cmp会将第一条选项插入到当前位置
vim.opt.completeopt = "menu,menuone,noselect,noinsert"
-- neovim 对sql文件处理有问题 https://github.com/neovim/neovim/issues/14433
vim.g.omni_sql_default_compl_type = "syntax"

vim.g.backspace = "indent, eol, start"

vim.o.exrc = true

-- 设置swap文件位置
vim.go.directory = "./.swap"
