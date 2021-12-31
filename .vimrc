"行号
set number
"设置编码
set encoding=utf-8
"设置终端编码
set termencoding=utf-8
"设置文件编码
set fileencoding=utf-8
"设置颜色级别
set t_Co=256
"文件自动更新载入
set autoread
"显示匹配的括号
set showmatch

"tab键用空格表示
set expandtab
"设置tab所占字符的大小
set tabstop=4
"设置tab键按下之后的行为，插入的是空格和tab制表符的混合。
"如果tabstop==softtabstop，则插入一个tab制表符；
"如果tabstop>softtabstop，则插入整数个tab制表符和余数个空格。
"如果设置了expandtab，则全部插入空格。
set softtabstop=4

"缩进
"启动自动缩进
set autoindent
"设置缩进宽度
set shiftwidth=4
"折叠
set foldmethod=indent
"总是显示标签栏
set showtabline=2
"缓冲区更新事件
set updatetime=100

"状态栏
"set laststatus=2
"t：文件名；y：文件内容类型；\&ff：文件类型unix/mac/dos；l：行号；c：列号
"set statusline=%t\ %y\ format:\ %{&ff};\ [%l,%c]
"set statusline=%F%m%r%h%w%=\ [ft=%Y]\ %{\"[fenc=\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\"+\":\"\").\"]\"}\ [ff=%{&ff}]\ [asc=%03.3b]\ [hex=%02.2B]\ [pos=%04l,%04v][%p%%]\ [len=%L]

"查找结果高亮
set hlsearch
"增量查找
set incsearch
"取消循环查找
set nowrapscan
"大小写敏感
set noignorecase
"设置不兼容vi
set nocompatible
"返回上次编辑位置
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

"代码
"仅在终端颜色支持时语法高亮
if &t_Co > 1
    syntax enable
endif
"允许用指定语法高亮配色方案替换默认方案
syntax on
"高亮当前行
set cursorline
"高亮当前列
"set cursorcolumn
"highlight CursorLine   cterm=NONE ctermbg=blue ctermfg=red guibg=NONE guifg=NONE
"highlight CursorColumn cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
hi CursorLine term=bold cterm=bold ctermbg=237
"快捷键
nnoremap <Leader>q :q!<CR>
nnoremap <Leader>w :w<CR>
"设置n始终向后
nnoremap <expr> n 'Nn'[v:searchforward]
nnoremap <expr> N 'nN'[v:searchforward]


""插件安装配置
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'preservim/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'rhysd/vim-clang-format'
Plugin 'ycm-core/YouCompleteMe'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'preservim/nerdcommenter'
Plugin 'dense-analysis/ale'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'jiangmiao/auto-pairs'
Plugin 'zivyangll/git-blame.vim'
call vundle#end()
filetype plugin indent on

"NERDTree配置
"设置快捷键
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
"打开vim时打开NERDTree
"autocmd VimEnter * NERDTree | wincmd p
"退出最后一个tab时同时退出NERDTree.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
"设置显示方式
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
"显示行号
let g:NERDTreeShowLineNumbers=1
"窗口大小
let g:NERDTreeWinSize=40
"窗口位置
let g:NERDTreeWinPos = 'left'
"高亮当前行
let g:NERDTreeHighlightCursorline = 1
"色彩显示
let g:NERDChristmasTree = 1
"显示隐藏文件
let g:NERDTreeShowHidden=1
"在tab中打开文件
let g:NERDTreeCustomOpenArgs={'file':{'where': 't'}}
"配置NERDTree结束

"配置nerdtree-git-plugin
let g:NERDTreeGitStatusIndicatorMapCustom = {
            \ 'Modified'  :'✹',
            \ 'Staged'    :'✚',
            \ 'Untracked' :'✭',
            \ 'Renamed'   :'➜',
            \ 'Unmerged'  :'═',
            \ 'Deleted'   :'✖',
            \ 'Dirty'     :'✗',
            \ 'Ignored'   :'☒',
            \ 'Clean'     :'✔︎',
            \ 'Unknown'   :'?',
            \ }
let g:NERDTreeGitStatusUseNerdFonts = 1
"配置nerdtree-git-plugin

"配置vim-clang-format
"格式化快捷键
"normal模式
autocmd FileType c,cpp,objc nnoremap <buffer><Leader>cf :<C-u>ClangFormat<CR>
"view模式
autocmd FileType c,cpp,objc vnoremap <buffer><Leader>cf :ClangFormat<CR>
"启动自动格式化，启动之后在保存文件时会自动格式化
nnoremap <leader>C :ClangFormatAutoToggle<CR>
"插入的行在离开插入模式时格式化
let g:clang_format#auto_formatexpr=1
"自动检测.clang-format文件
let g:clang_format#detect_style_file=1
"配置vim-clang-format

"配置tab快捷键
nnoremap <S-Right> :tabn<CR>
nnoremap <S-Left> :tabp<CR>
nnoremap <C-c-o> :copen<CR>
nnoremap <C-c-c> :cclose<CR>
"配置tab快捷键
"配置快捷键拷贝系统粘贴版
vnoremap <Leader>y "+y

"配置vim airline
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
"启用源码变化显示
let g:airline#extensions#hunks#enabled=1
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#branch#empty_message = '····'
let g:airline#extensions#branch#displayed_head_limit = 10
let g:airline#extensions#ale#enabled = 1
" 支持 powerline 字体
let g:airline_powerline_fonts = 1
let g:airline_theme='powerlineish'  " murmur配色不错

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_left_sep = '▶'
let g:airline_left_alt_sep = '❯'
let g:airline_right_sep = '◀'
let g:airline_right_alt_sep = '❮'
function! AirlineInit()
let g:airline_section_a=airline#section#create(['mode',' ','branch'])
let g:airline_section_b=airline#section#create_left(['ffenc','hunks','file'])
let g:airline_section_c=airline#section#create(['filetype'])
let g:airline_section_x=airline#section#create(['%p%%'])
let g:airline_section_y=airline#section#create(['0x%B'])
let g:airline_section_z=airline#section#create_right(['L:%l','C:%c'])
endfunction
autocmd User AirlineAfterInit call AirlineInit()
"配置vim airline

"配置vim- nerdcommenter注释插件
"Create default mappings
let g:NERDCreateDefaultMappings = 1
"Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
"Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
"Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
"Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
"Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '//','right': '' } }
"Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
"Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
"Enable NERDCommenterToggle to check all selected lines is commented or not 
let g:NERDToggleCheckAllLines = 1
"配置vim- nerdcommenter注释插件

"YouCompleteMe
nnoremap <leader>jd :YcmCompleter GoTo<CR>
"启用加载.ycm_extra_conf.py提示
let g:ycm_confirm_extra_conf=0
"在注释输入中也能补全
let g:ycm_complete_in_comments = 1
"在字符串输入中也能补全
let g:ycm_complete_in_strings = 1
"开启 YCM 基于标签引擎
let g:ycm_collect_identifiers_from_tags_files=1
"注释和字符串中的文字也会被收入补全
let g:ycm_collect_identifiers_from_comments_and_strings = 1
"启用语法提示，比如C语言
let g:ycm_seed_identifiers_with_syntax=1
"语言关键字补全, 不过python关键字都很短，所以，需要的自己打开
let g:ycm_collect_identifiers_from_tags_files = 1
"禁止缓存，每次重新生成匹配项
let g:ycm_cache_omnifunc = 1
"基于语义补全
let g:ycm_key_invoke_completion = '<c-z>'
let g:ycm_semantic_triggers =  {
            \ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
            \ 'cs,lua,javascript': ['re!\w{2}'],
            \ }
"文件白名单，其中的文件会被分析
let g:ycm_filetype_whitelist = {
            \ "c":1,
            \ "cpp":1, 
            \ "objc":1,
            \ "sh":1,
            \ "zsh":1,
            \ "zimbu":1,
            \ }
"添加preview到completeopt中
let g:ycm_add_preview_to_completeopt=1
"设置预览窗口， popup或者preview
set completeopt=preview
"设置为-1表示使用预览窗口展示信息
let g:ycm_max_num_candidates_to_detail =-1
"完成补全后关闭预览窗口
let g:ycm_autoclose_preview_window_after_completion = 1
"离开插入模式关闭预览窗口
let g:ycm_autoclose_preview_window_after_insertion = 1
"手动打开或关闭弹出窗口
nmap <leader>D <plug>(YCMHover)
"在弹出窗口显示文档
let g:ycm_auto_hover='CursorHold'
"弹出窗口语法高亮
augroup MyYCMCustom
    autocmd!
    autocmd FileType c,cpp let b:ycm_hover = {
                \ 'command': 'GetDoc',
                \ 'syntax': &filetype
                \ }
augroup END
"从第2个键入字符就开始罗列匹配项
let g:ycm_min_num_of_chars_for_completion=2
"配置文件
let g:ycm_global_ycm_extra_conf='~/.vim/bundle/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'
"禁用语法检查
let g:ycm_show_diagnostics_ui = 0
"禁用语法检查符号
let g:ycm_enable_diagnostic_signs=0
"禁用语法检查高亮
let g:ycm_enable_diagnostic_higihtling=0
"禁用回显语法检查文本
let g:ycm_echo_current_diagnostic = 0
"YouCompleteMe

"配置ale
"标志列始终打开
let g:ale_sign_column_always = 1
"自定义图标
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
"显示Linter名称,出错或警告等相关信息
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
"<Leader>s触发/关闭语法检查
nmap <Leader>s :ALEToggle<CR>
"<Leader>d查看错误或警告的详细信息
nmap <Leader>d :ALEDetail<CR>
"普通模式下，sp前往上一个错误或警告，sn前往下一个错误或警告
nmap sp <Plug>(ale_previous_wrap)
nmap sn <Plug>(ale_next_wrap)
"使用clang对c和c++进行语法检查，对python使用pylint进行语法检查
let g:ale_linters = {
    \   'c++': ['clang'],
    \   'c': ['clang'],
    \   'python': ['pylint'],
    \}

"配置gitgutter
"启用gitgutter
let g:gitgutter_enabled = 1
"适配背景色，0禁用，1启用
let g:gitgutter_set_sign_backgrounds = 0
"设置符号颜色
highlight GitGutterAdd    guifg=#009900 ctermfg=2
highlight GitGutterChange guifg=#bbbb00 ctermfg=3
highlight GitGutterDelete guifg=#ff2222 ctermfg=1
"变化行号高亮
let g:gitgutter_highlight_linenrs = 1
"配置gitgutter
nnoremap <Leader>s :<C-u>call gitblame#echo()<CR>
"显示已输入命令，需要放在最后一行才会生效
set showcmd
