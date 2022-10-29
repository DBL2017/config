# neovim图标使用指南

1. 下载[nerd-fonts字库](https://www.nerdfonts.com/)
~~~sh
git clone --filter=blob:none --sparse git@github.com:ryanoasis/nerd-fonts
cd nerd-fonts
git sparse-checkout add patched-fonts/JetBrainsMono
git sparse-checkout add patched-fonts/FiraCode
~~~

2. 安装字体
~~~sh
./install FiraCode
~~~

3. 设置Terminal字体为`Fira Nerd Code`。
