# TP-LINK 代码评审 Skill

按 TP-LINK 嵌入式 Linux/C 规范进行代码评审，关注正确性、稳定性、安全性和可执行的缺陷建议。评审代码只读，不修改代码，也不提交 Gerrit 评论或投票。

## 依赖与必须配置

- Gerrit 评审需要 Python 3.8+、HTTPS 访问及下方 HTTP 凭据；不使用 SSH。
- 本地 Git diff 或 commit 评审需要 Git。
- 评审 Gerrit 前，先登录 [Gerrit HTTP Credentials](https://gerrit.hn.tp-link.com/settings/#HTTPCredentials) 页面生成 HTTP Token。

使用页面显示的 HTTP 用户名和生成的 HTTP TOKEN，在启动 Copilot 的环境中设置：

```sh
export GERRIT_AUTH_NAME='你的 HTTP 用户名'
export GERRIT_AUTH_TOKEN='你的 HTTP TOKEN'
```

设置变量后再启动 Copilot；如果 Copilot 已运行，需重启以继承新环境。不要将 Token 提交到仓库或写入日志。

## 使用方式

在 Copilot 中说明评审目标和范围：

```text
请按 TP-LINK 规范评审模块 config/network。
请评审 src/net/wifi.c 当前实现。
请按 TP-LINK 规范评审 commit <commit-id>。
请按 TP-LINK 规范评审 Gerrit patchset：
https://gerrit.example.com/c/team/project/+/12345/3
```

也可以直接粘贴 diff 或指定代码片段。模块评审检查当前实现；文件/代码评审检查指定内容及必要上下文；commit 和 Gerrit 评审只检查指定版本引入的变更。

未指定目标但要求评审当前仓库变更时，只检查**已暂存**的 diff。未暂存的修改不会自动纳入，请先 `git add`。Gerrit URL 建议包含 patchset 编号；Skill 先获取 diff，仅在需要时读取同版本上下文。

Gerrit 返回 **401** 时检查 Token 和启动环境；**403** 通常表示账号无访问权限；**404** 可能表示 change 不存在或账号不可见。获取失败时不会评审不完整的产物。

详细 Gerrit 获取说明见 [`references/gerrit-retrieval.md`](references/gerrit-retrieval.md)。
