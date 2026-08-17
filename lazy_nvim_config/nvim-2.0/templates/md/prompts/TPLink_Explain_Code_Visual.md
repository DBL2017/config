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
    model: GPT-5.2
  modes:
    - v
intro_message: 使用 TPLink AI 中文解释选中的代码（增强版）
---

## user

你是一名资深软件架构师和开发工程师。

请使用中文分析下面的代码，并严格按照以下格式输出。

## 功能说明

用简洁易懂的语言说明：

- 这段代码的主要用途
- 核心执行流程
- 输入与输出

## 关键技术点

列出代码涉及的：

- 语言特性
- 设计模式
- 框架或库
- 算法或数据结构

## 潜在问题

从以下角度分析：

- Bug 风险
- 性能问题
- 并发安全
- 内存占用
- 可维护性
- 可测试性

如未发现明显问题，请明确说明。

## 改进建议

给出具体可执行的优化建议：

- 代码结构优化
- 性能优化
- 可读性优化
- 错误处理优化
- 安全性优化

## 优化示例（如有必要）

对于重要改进点，可给出简短代码示例。

待分析代码：

```${context.filetype}
${context.code}
```
