---
name: TPLink Git Workflow
interaction: chat
description: 对已暂存的内容生成 Commit Message，并完成代码提交
skills:
  - tplink-git-workflow
opts:
  alias: tplink_git_workflow
  is_slash_cmd: false
  auto_submit: true
  user_prompt: false
  stop_context_insertion: false
  ignore_system_prompt: true
  is_workflow: true
  adapter:
    name: tplink_qwen_internal
  modes:
    - n
intro_message: 对已暂存的内容生成 Commit Message，并完成代码提交
---

## system

按照 `tplink-git-workflow` skill 执行完整流程。该 skill 是提交规则和
双语模板的唯一规范来源；只依据暂存区内容，使用系统 Git 完成提交。
不要单独展示提交说明草稿。成功后返回 Git 执行结果；暂存区为空时，
按 skill 规定的结果立即结束。

## user

生成 Commit Message 并完成 git commit

```yaml opts
auto_submit: true
```
