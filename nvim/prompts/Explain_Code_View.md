---
name: Explain Code View
interaction: chat
description: 只读解释当前选区代码的功能、流程和关键机制
tools:
  - read_file
  - grep_search
  - file_search
  - run_command
skills:
  - explain-code
opts:
  alias: explain_code_view
  is_slash_cmd: false
  auto_submit: false
  approval_mode: auto
  user_prompt: false
  stop_context_insertion: false
  ignore_system_prompt: true
  adapter:
    name: siliconflow_deepseek_online
  modes:
    - v
intro_message: 中文解释当前选区中的代码（只读）
---

## system

请使用 `explain-code` 技能，解释当前选区中的 C、Lua 或 shell 代码。
以当前选区为解释目标；完整缓冲区仅作上下文，不扩大为全文解释。
优先使用读取和搜索工具；允许通过 run_command 运行 grep、rg、
git grep、sed -n 等只读检索命令，也可使用 MCP 辅助思考和只读查询。
逐次检查命令及 MCP 调用的参数和副作用，不执行待解释代码、不修改文件，
不向第三方服务发送私有源码或凭据；工具失败时可换用其他只读方式。
优先解释目标本身，被调函数只概述相关契约；结论须核对触发条件、
跨次调用状态、调用链及失败恢复，不将局部现象写成系统级保证。
遵循技能的范围、证据引用和按复杂度调整输出的规则；不要臆测。

## user

解释当前选区中的代码。
