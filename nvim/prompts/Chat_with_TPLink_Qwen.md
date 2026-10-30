---
name: Chat with TPLink Qwen
interaction: chat
description: 仅打开TPLink Qwen Chat
tools:
  - run_command
  - read_file
  - edit_file
  - delete_file
  - create_file
  - grep_search
  - file_search
  - get_changed_files
opts:
  alias: tplink_qwen_chat
  approval_mode: yolo
  adapter:
    name: tplink_qwen_internal
  modes:
    - n
    - v
intro_message: 使用TPLink Qwen适配器打开Chat
---

## user
