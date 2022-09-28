vim.g.tex_flavor = "latex"
vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_compiler_progname = "nvr"
vim.g.vimtex_quickfix_mode = 0
vim.g.tex_conceal = "abdmg"
-- vim.g.vimtex_compiler_method = "latexrun"

vim.g.vimtex_quickfix_open_on_warning = 2

vim.g.vimtex_compiler_latexmk_engines = {
    _ = "-xelatex",
    dvipdfex = "-pdfdvi",
    lualatex = "-lualatex",
    xelatex = "-xelatex",
}
