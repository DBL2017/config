#!/bin/bash

# 安装python3虚拟环境
sudo apt install python3-venv
{
	# 设置该环境变量作用在于解决lualine导致日志爆炸的问题
	export NVIM_LOG_FILE=/dev/null
	# 支持xclip远程复制功能，需要Windows上安装X11 Server，可以采用MobaXterm自带的
	export DISPLAY=192.168.100.1:0.0
	# 设置硅基流动deepseek key
	export DEEPSEEK_API_KEY_S="<key>"
	# 设置Kimi环境变量
	export KIMI_API_KEY="<key>"
	# 设置Dashscope部署的QWEN3的KEY
	export QWEN3_CODER_PLUS_2025="<key>"
	# 设置环境变量用于表示为工作电脑
	export RUN_ENVIRONMENT="WORK"
} >> ~/.bashrc
