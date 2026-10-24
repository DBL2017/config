---
name: Git Workflow
interaction: chat
description: 基于暂存区提交并推送
skills:
  - git-commit-push
opts:
  alias: git_commit_push
  is_slash_cmd: false
  auto_submit: true
  user_prompt: false
  stop_context_insertion: true
  ignore_system_prompt: true
  adapter:
    name: siliconflow_deepseek_online
  modes:
    - n
intro_message: 使用系统 Git 生成提交说明、提交并推送
---

## user

按 `git-commit-push` skill 完成提交和推送，并准确报告实际结果。
