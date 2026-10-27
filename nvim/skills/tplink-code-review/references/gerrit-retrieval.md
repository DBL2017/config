# 获取 Gerrit diff 与按需上下文

使用 skill 自带脚本，仅依赖 Python 3.8+ 和 HTTPS。change 查询、精确 patch
下载和上下文读取全部通过 Gerrit REST Basic Auth 完成；不调用 SSH、Git 或
本地仓库，不要求 SSH 密钥，也不下载完整 Git 对象库。不提交评论或投票。

## HTTP 认证

在启动 Copilot/skill 的环境中设置 Gerrit HTTP 用户名和 HTTP 密码：

```sh
export GERRIT_AUTH_NAME='your-gerrit-username'
export GERRIT_AUTH_TOKEN='your-gerrit-http-password'
```

使用 Gerrit 提供的 **HTTP Password**，不是账户登录密码、SSH 私钥密码或浏览器
Cookie。不要将密码放到命令行参数、代码、仓库、报告或会话记录中。进程直接从
环境读取两项变量，以 Basic Auth 请求 HTTPS `/a/` REST endpoint；不会把密码、
用户名或 Authorization 头写入日志、manifest 或标准输出。TLS 证书验证保持开启。
环境变量只对子进程有效；在启动工具前配置好，之后打开的新会话才会继承。

变量缺失、空值、非法控制字符、HTTP 401/403/404 均明确失败。401 提示核对变量
和 Gerrit HTTP 权限；403 表示账户无资源权限；404 也可能表示 change 对该账户
不可见。脚本不读取浏览器会话，不从 Git credential helper 取凭据，不回退 SSH、
Git fetch 或工作树。

## 获取指定版本

输出目录必须尚不存在，放在运行时的 session files 下，不要放进被评审仓库。

```sh
python3 <skill-dir>/scripts/fetch_gerrit_patch.py \
  'https://review.example.com/c/team/project/+/12345/3' \
  --output /path/to/session/files/change-12345-ps3

python3 <skill-dir>/scripts/fetch_gerrit_patch.py 12345/3 \
  --web-url https://review.example.com --project team/project \
  --output /path/to/session/files/change-12345-ps3

python3 <skill-dir>/scripts/fetch_gerrit_patch.py \
  I0123456789abcdef0123456789abcdef01234567 \
  --web-url https://review.example.com \
  --output /path/to/session/files/change-by-id
```

支持 change number、`change/patchset`、Change-Id、7–40 位十六进制 SHA 和 Gerrit
change 页面 URL。纯数字按 change 编号解释。传 Gerrit Web URL 时，站点和页面中
的 project 自动解析；否则必须指定 `--web-url`，可用 `--project` 限制查询。
部署在路径前缀下时保留该前缀，例如 `https://review.example.com/gerrit`。
拒绝 HTTP 明文、URL 凭据、查询参数、fragment、路径穿越和非 change 页面 URL。

脚本使用 REST `GET /changes/?q=...&o=ALL_REVISIONS&o=ALL_COMMITS` 查询 change，
然后按精确 SHA 下载 commit、文件列表和格式化 patch。交叉验证 change 编号、
project、Change-Id、patchset 编号、预期 ref、提交 SHA 及父提交 SHA；历史 patchset
绝不替换成 current。merge commit 的 patch 与 files 请求均指定 `parent=1`，
与第一父提交比较；根提交与空树比较。

`--max-bytes` 限制解码后 patch 大小，默认 32 MiB；元数据最多 16 MiB，
HTTP response 也有编码后上限。超限直接报错，不截断、不改走完整仓库下载。
请求超时默认 30 秒，HTTPS connect/handshake timeout 默认 10 秒，
可分别用 `--timeout` 和 `--connect-timeout` 调整。查询对网络、超时、HTTP 429
和 5xx 最多尝试三次，间隔 5 秒；认证、权限、找不到 change 等明确 4xx 不重试。

## 按需读取同版本上下文

先阅读 `patch.diff`，只有判断缺少的函数体、头文件或直接调用方确有必要时，
才下载精确 revision/第一父提交中的相应文件：

```sh
python3 <skill-dir>/scripts/fetch_gerrit_context.py \
  /path/to/session/files/change-12345-ps3/manifest.json \
  path/to/source.c

python3 <skill-dir>/scripts/fetch_gerrit_context.py \
  /path/to/session/files/change-12345-ps3/manifest.json \
  path/to/header.h --side base
```

默认 `--side revision`；`--side base` 使用该 patchset 的第一父提交。删除文件
读取 base，新增文件读取 revision；重命名在 base 使用 `old_path`，在 revision
使用 `path`。根提交没有 base。路径必须是仓库相对路径；绝对路径、空路径段和
`..` 会拒绝。单文件默认最大 16 MiB，可通过 `--max-bytes` 显式调整。

返回 JSON 给出本地缓存路径、来源 revision、文件路径、长度和 SHA-256。内容按
revision/path 哈希缓存，并校验缓存身份及哈希后复用。文本文件按需读取必要行；
二进制文件不要当作文本或执行。源码不自动全部载入上下文。

## 产物与失败诊断

仅成功退出且 `manifest.json` 已写入时才可开始评审。manifest 为 schema version 3，
`repository` 固定为 null；目录包含：

| 路径 | 用途 |
|---|---|
| `manifest.json` | 验证后的 change、patchset、SHA、父提交、文件清单和产物路径 |
| `patch.diff` | 精确 patchset 对第一父提交的 patch |
| `commit.txt` | 选定 revision 的提交说明 |
| `change.json` | Gerrit REST change 元数据 |
| `diagnostics/http-requests.jsonl` | 每请求的 endpoint、阶段、状态、字节数、耗时及错误 |
| `context/` | 明确请求后缓存的同版本文件和 SHA-256 记录 |

诊断日志不保存认证头、凭据或响应源码，文件权限为 0600。失败时 stderr 返回
JSON，包括实际阶段、HTTPS endpoint、HTTP 状态、具体错误及诊断路径；HTTP 超时
标注 `http_timeout`。失败的部分产物不能用于评审；重试请换新的输出目录。
若所需上下文无法获取，报告评审未完成，不以工作树或最新分支替代。

主要阶段：`input_validation`、`artifact_init`、`rest_query`、`rest_metadata`、
`rest_commit`、`rest_files`、`rest_patch`、
`context_fetch`、`context_cache`、`artifact_write`、`diagnostic_write`。
