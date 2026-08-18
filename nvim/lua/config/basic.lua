-- 行号
vim.wo.number = true
-- vim.wo.relativenumber = true

-- 字符编码 终端显示编码
-- vim.g.encoding = "UTF-8"
-- 文件编码
-- vim.o.fileencoding = "UTF-8"
vim.o.fileencodings = "ucs-bom,utf-8,gb2312,gb18080,gbk"

-- 切换工作目录
-- vim.g.autchdir = true

-- 自动加载外部修改
vim.g.autoread = true

-- 自动跳转到匹配的括号
vim.g.showmatch = false

-- tab转空格
vim.bo.expandtab = true

-- tab占位符的宽度，不修改键入tab时的行为，可用来格式化对齐
vim.o.tabstop = 8

-- 键入tab时插入的空格数
vim.o.softtabstop = 4
vim.bo.softtabstop = 4
-- 由于tabstop==4，即tab占用4个字符长度；softtabstop==4，因此键入tab时插入4个空格。
-- 如果expandtab==true, tabstop==8 and softtabstop==4，那么第一次键入tab会插入4个空格，第二次键入tab继续插入4个空格。
-- 如果expandtab==false, tabstop==8 and softtabstop==4，那么第一次键入tab会插入4个空格，第二次键入tab会替换之前空格为tab键（8）。
-- 上面这些仅在行内生效，行首会被当作缩进处理，受限于shiftwidth的配置
-- 在行首键入tab时会受到shiftwidth的影响
-- 缩进时的空格数量
vim.o.shiftwidth = 4

-- 自动缩进
vim.bo.autoindent = true
vim.bo.smartindent = true

-- updatetime: 插件和诊断触发相关的延迟时间（毫秒）。
-- 作用: 控制 CursorHold、lint、gitsigns 等基于时间的事件触发间隔，影响响应频率与资源消耗。
-- 取值范围: 正整数（单位毫秒），典型值 100-1000。
-- 当前取值含义: 300 -> 相比更低值减少事件触发频率，有助于降低 CPU 使用，同时保持较为及时的事件响应。
vim.g.updatetime = 300

-- 查找结果高亮
vim.g.hlsearch = true
-- 增量查找
vim.g.incsearch = true
-- 循环查找
vim.o.wrapscan = false

-- quitfix命令打开新buffer时的行为
vim.o.switchbuf = "newtab"

-- 高亮当前行列
vim.wo.cursorline = true
vim.o.cursorcolumn = true

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
vim.opt.clipboard = "unnamed,unnamedplus"
-- 和OSC52类似，不过是通过xclip和X11 Server(由MobaXterm提供)进行交互，
-- neovim将复制的内容传递给xclip（系统剪贴板工具），
-- xclip传递给宿主机的X11 Server，宿主机的X11 Server再写入宿主机的剪贴板
-- 但由于windows terminal不支持x11 server，因此采用mobaxterm的x11 server，需要在~/.bashrc中配置export DISPLAY=192.168.100.1:0.0
-- vim.g.clipboard = {
--     name = "xclip",
--     copy = { ["+"] = "xclip -selection clipboard", ["*"] = "xclip -selection primary" },
--     paste = { ["+"] = "xclip -selection clipboard -o", ["*"] = "xclip -selection primary -o" },
-- }
-- vim.g.clipboard_timeout = 3000 -- 将超时时间从 10 秒改为 3 秒
-- vim.g.clipboard = "osc52" -- 这种方式不生效
-- 启用OSC 52，此时neovim可以与支持OSC52的远程终端进行通信，通信原理如下
-- 1. neovim复制后会将内容转换为OSC52格式，发送给本地的伪终端
-- 2. 伪终端通过SSH Server与宿主机的SSH Client通信
-- 3. 宿主机的本地终端软件支持OSC52时会解析数据，并写入系统剪贴板
-- vim.g.clipboard = {
--     name = "OSC 52",
--     copy = {
--         ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
--         ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
--     },
--     paste = {
--         ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
--         ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
--     },
-- }

-- termguicolors: 启用 24-bit 颜色支持（True color）。
-- 作用: 允许 Neovim 使用终端的真彩色，确保主题和高亮按预期显示。
-- 取值范围: boolean (true/false)，依赖于终端是否支持 true color。
-- 当前取值含义: true -> 启用真实颜色渲染，若终端支持会获得更好的配色效果。
vim.opt.termguicolors = true

------------------------------- 自定义折叠功能-----------------------------------------------------------------------------
vim.opt.foldmethod = "manual"
-- -- 展开1级
vim.wo.foldlevel = 1
-- -- 或者自定义函数
function _G.custom_foldtext()
    local virtual_txt = ("%s 󰁂 %d "):format(vim.fn.getline(vim.v.foldstart), vim.v.foldend - vim.v.foldstart + 1)
    return virtual_txt
    -- return string.format("syna %s (%d lines)", vim.fn.getline(vim.v.foldstart), vim.v.foldend - vim.v.foldstart + 1)
end
vim.opt.foldtext = "v:lua.custom_foldtext()"
-- 折叠标记栏宽度
vim.opt.foldcolumn = "0"
-- 是否启用折叠功能
vim.opt.foldenable = true

----------------------------------nvim-ufo插件折叠配置-----------------------------------------------------------------------
-- 设置折叠方法为手动
-- 可取值为manual、indent（缩进）、expr（）、marker（标记）、syntax（基于语法折叠）、diff（折叠未改变的文本）等
-- vim.opt.foldmethod = "manual"
-- 为了规避save buffer之后会重新折叠的问题，这是由使用tresitter折叠导致的问题 https://github.com/kevinhwang91/nvim-ufo/issues/30
-- 折叠等级，执行zM之后的折叠等级
-- vim.opt.foldlevel = 99
-- 指定第一次打开buf时的折叠等级，0表示所有折叠关闭，99表示不关闭任何折叠
-- vim.opt.foldlevelstart = -1
-- 折叠标记栏宽度
-- vim.opt.foldcolumn = "0"
-- 是否启用折叠功能
-- vim.opt.foldenable = true

-- 禁用mouse
vim.opt.mouse = ""
vim.go.mouse = ""

-- 增添此项原因是为了解决在不选择提示的情况，nvim-cmp会将第一条选项插入到当前位置
vim.opt.completeopt = "menu,menuone,noselect,noinsert"
-- neovim 对sql文件处理有问题 https://github.com/neovim/neovim/issues/14433
vim.g.omni_sql_default_compl_type = "syntax"

vim.g.backspace = "indent, eol, start"

-- exrc: 是否允许在工作目录中执行项目特定的 vimrc 文件（如 .nvimrc / .exrc）。
-- 作用: 若启用，Neovim 会在打开文件时执行当前目录下的配置文件，可能改变运行时配置。
-- 取值范围: boolean (true/false)。
-- 当前取值含义: 禁用（注释掉） -> 为安全考虑关闭，避免不受信任项目中的配置造成命令执行风险或环境污染。
-- vim.o.exrc = true  -- disabled for security: avoid executing project-local rc files

-- swapfile: 是否启用交换文件（swap），用于恢复崩溃时的缓冲区内容。
-- 作用: 当编辑器意外退出时，swap 文件可用于恢复未保存的更改。
-- 取值范围: boolean (true/false)。
-- 当前取值含义: true -> 启用 swapfile，配合专用目录可防止在工作目录生成临时文件。
vim.go.swapfile = true
-- autoread: 是否自动在外部修改文件时重新加载缓冲区。
-- 作用: 提高与其他工具/编辑器协作时的同步性。
-- 取值范围: boolean (true/false)。
-- 当前取值含义: true -> 当文件在外部被修改时自动重新加载。
vim.opt.autoread = true
-- swap/undo 存放目录（使用 stdpath('state') 避免污染当前工作目录）
-- 作用: 指定 swap 和 undo 文件的存放位置。
-- 取值范围: 文件路径字符串。
-- 当前取值含义: 使用 stdpath('state') 下的 swap/ 和 undo/ 子目录。
vim.go.directory = vim.fn.stdpath("state") .. "/swap//"
-- undofile: 是否启用持久 undo（撤销历史保存到磁盘）。
-- 作用: 允许跨会话保留撤销历史。
-- 取值范围: boolean (true/false)。
-- 当前取值含义: true -> 启用持久 undo，撤销历史写入 undodir 指定的目录。
vim.opt.undofile = true
-- undodir: 持久 undo 文件的存放目录。
-- 作用: 保存 undo 文件以便会话间恢复撤销历史。
-- 取值范围: 文件路径字符串。
-- 当前取值含义: 使用 stdpath('state') 下的 undo/ 子目录。
vim.go.undodir = vim.fn.stdpath("state") .. "/undo//"

-- 该值指定tab line是否被显示，2表示总是显示
vim.go.showtabline = 2

-- diff
-- filler：显示填充行，以两个窗口文本位置同步
-- iwhiteeol：忽略尾部空白
-- internal：使用内部比较器
-- closeoff：当tab中仅剩一个启用了diff的窗口时自动关闭diff模式，相当于执行:diffoff
-- iblank：忽略空白行的修改
-- vertical：diff使用竖直分屏
vim.go.diffopt = "internal,iwhiteeol,filler,closeoff,vertical,iblank"

vim.g.winborder = "rounded"

-- 设置显示非可见字符
vim.opt.list = true
vim.opt.listchars = {
    tab = "▸ ",
    trail = "·",
    space = "·",
    nbsp = "␣",
    extends = "❯",
    precedes = "❮",
    eol = "↴",
}
