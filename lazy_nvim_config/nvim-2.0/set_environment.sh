#!/bin/bash

# 设置该环境变量作用在于解决lualine导致日志爆炸的问题
echo "export NVIM_LOG_FILE=/dev/null" >> ~/.bashrc
# 支持xclip远程复制功能，需要Windows上安装X11 Server，可以采用MobaXterm自带的
echo "export DISPLAY=192.168.100.1:0.0" >> ~/.bashrc
# 设置硅基流动deepseek key
echo "export DEEPSEEK_API_KEY_S=<key>" >> ~/.bashrc
# 设置KIMI KEY
excho "export KIMI_API_KEY=<key>" >> ~/.bashrc
# 设置DashScope的QWEN3 KEY
echo "export QWEN3_CODER_PLUS_2025=<key>" >> ~/.bashrc

