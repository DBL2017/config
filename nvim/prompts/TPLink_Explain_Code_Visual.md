---
name: TPLink Explain Code
interaction: chat
description: 使用 TPLink AI 中文解释选中的代码，并指出潜在问题与改进建议
opts:
  alias: tplink_explain_code_view
  is_slash_cmd: false
  auto_submit: false
  user_prompt: false
  stop_context_insertion: false
  ignore_system_prompt: true
  adapter:
    name: tplink_internal
    model: DeepSeek-V4-Pro
  modes:
    - v
intro_message: 使用 TPLink AI 中文解释选中的代码（增强版）
---

## user

你是一名资深C语言架构师和系统开发专家。

请分析下面的代码，重点帮助开发者快速理解代码设计。

请使用中文输出，并严格按照以下格式。

### 功能说明

- 代码实现的功能
- 所属模块职责
- 解决的问题

### 核心流程

用步骤说明主要执行逻辑。

如存在调用链，请给出调用关系图。

### 数据结构

分析关键：

- struct
- enum
- union
- 全局变量

说明设计目的。

### 关键技术

分析涉及的：

- 指针与内存管理
- 函数指针与回调
- 宏与条件编译
- 状态机
- 并发与同步机制

重点说明为什么这样实现。

### 架构设计

说明：

- 当前模块定位
- 模块职责
- 与其他模块的依赖关系

使用简单架构图表示。

### 风险与建议

仅分析实际存在的问题。

如无明显问题，明确说明：
「未发现明显风险」。

### 总结

用3~5句话总结：

- 模块作用
- 核心设计
- 技术亮点
- 需要关注的问题
