---
name: Git Workflow
interaction: chat
description: 生成 Commit Message，并使用系统 Git 完成提交和推送
skills:
  - git-commit-push
opts:
  alias: git_commit_push
  is_slash_cmd: false
  auto_submit: true
  user_prompt: false
  stop_context_insertion: false
  ignore_system_prompt: true
  is_workflow: true
  adapter:
    name: siliconflow_deepseek_online
  modes:
    - n
intro_message: 使用系统 Git 生成提交说明、提交并推送
---

## system

严格按照 `git-commit-push` skill 执行完整流程。完成后准确报告提交和推送结果。

## user

严格按照流程完成 Git 提交和推送

```yaml opts
auto_submit: true
```
