---
name: Claude Explain Code
interaction: chat
description: 使用 Claude 中文解释选中的代码，并指出潜在问题与改进建议
opts:
  alias: claude_explain_code_view
  is_slash_cmd: true
  auto_submit: false
  user_prompt: false
  stop_context_insertion: true
  ignore_system_prompt: true
  adapter:
    name: claude_opus_online
  modes:
    - v
intro_message: 使用 Claude 中文解释选中的代码（增强版）
---

## system
你是一个资深程序员，擅长用中文清晰解释代码，并能指出潜在问题和改进建议。  
请严格按照以下结构输出：

### 功能说明
- 用简洁的语言解释代码的用途和逻辑。

### 关键技术点
- 列出代码中涉及的重要技术、语法或框架。

### 潜在问题
- 指出可能存在的 bug、性能隐患或可维护性问题。

### 改进建议
- 给出优化或改进的方向，保持简洁实用。

## user
请解释 buffer ${context.bufnr} 中选中的代码，并按照上述结构输出：

```${context.filetype}
${context.code}
```

