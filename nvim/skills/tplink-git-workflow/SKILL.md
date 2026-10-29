---
name: tplink-git-workflow
description: >-
  Generate TP-LINK-compliant bilingual commit messages from staged changes
  and, when explicitly requested, commit them through the system Git executable.
  Use this skill whenever the user asks to create a commit message for staged
  work, run the TP-LINK Git workflow, or generate the message and complete the
  commit. Do not use it for unstaged-only changes, general Git explanations,
  or requests to draft a message without committing.
compatibility: Requires the system Git executable and a terminal or command tool.
---

# TP-LINK Git Workflow

Use this workflow only when the user asks to commit staged changes. It is
designed to prevent unrelated working-tree content from leaking into the
commit and to keep commit messages consistent with TP-LINK project conventions.
Use the system `git` executable through the available terminal or command
tool. Do not use a separate Git workflow integration.

## Workflow

### 1. Read only the index

Request the staged diff by running:

```sh
git diff --cached
```

Treat that diff as the only source of facts. Do not read or analyze unstaged
changes, untracked files, repository files, or other command output. Do not
run commands to inspect other files or scan repository state.

If the staged diff is empty, run:

```sh
git status
```

Then return exactly:

```text
chore: no staged changes
```

Stop without creating a message or committing.

If the system Git executable or terminal/command tool is unavailable, or the
staged diff cannot be obtained or understood, explain the blocker and stop.
Never imply that a commit succeeded when it did not.

### 2. Classify the change

Choose exactly one commit category from the staged diff:

- **Bug fix:** fixes an existing defect, abnormal behavior, or regression.
- **Feature:** adds or extends user-visible or system behavior.
- **Device adaptation:** adds or changes device-model-specific configuration,
  directories, or support.

For mixed changes, choose the category that best represents the primary
purpose and describe the other staged details only with that category's
permitted labels. Do not combine templates. If the primary purpose cannot be
determined from the staged diff, ask the user instead of guessing.

### 3. Draft and check the bilingual message

Read `references/commit-message-rules.md` and use only the template for the
selected category. Construct the complete English section first, then its
Chinese equivalent. Translate each fact faithfully: neither section may add
claims absent from the other. Do not show a draft to the user before
committing.

Use only facts supported by the staged diff. Do not invent module or device
names, Bug IDs, requirement references, root causes, test results, or test
scope. When a field is not evidenced by the diff, keep only that field's label
and leave its content empty on the following line, rather than writing a
missing-information placeholder such as `Not specified in staged changes` or
`暂存区未提供`. In particular, do not claim code was
compiled or tested merely because it appears in the diff.

Before committing, verify that:

- English comes first, followed by one blank line and Chinese.
- Both titles begin with the same bracketed module or device identifier
  (for example, `[tplink-code-review]`); never omit the brackets from the
  English title.
- Separate every title/body item with a blank line in both language sections.
- When a body field contains multiple independent facts, format them as a
  numbered list with one item per line (`1.`, `2.`, `3.`, ...), rather than
  concatenating them into one paragraph. This applies especially to
  `[Test Scope]` and `[自测内容]`.
- Keep corresponding English and Chinese numbered items in the same order and
  preserve a one-to-one mapping between them.
- Keep labels for fields without evidenced content, with the label line
  followed by an empty content line; do not emit `Not specified in staged
  changes` or `暂存区未提供`.
- The two sections use the same category and corresponding title identifiers.
- Each section has exactly the title and labels allowed for that category.
- No unused template text, commentary, standalone change list, or other
  category's labels remain.
- Titles are no longer than 65 characters; bug issue-description lines are no
  longer than 70 characters.
- Test-scope content comes only from explicit staged evidence.

### 4. Commit through system Git

If the user requested a commit, run system Git with the exact complete
bilingual message supplied as standard input:

```sh
git commit --file=-
```

Provide the message through the terminal tool's stdin facility. If it has no
stdin support, use a quoted here-document with a unique delimiter that does
not occur in the message, so shell expansion cannot alter the message. Do not
use `-m`, construct a different message, or invoke another Git interface.
Do not alter the message after reviewing it, and do not ask the user to run
the commit manually.

After a successful commit, return the command's execution result. If the
commit command fails, report the failure and do not claim success.

## Scope

This skill applies the commit workflow only. Other supplied coding standards
may help interpret terminology when already present in the staged diff, but
they do not authorize reading unstaged files or adding facts to the message.
