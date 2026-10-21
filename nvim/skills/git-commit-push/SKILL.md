---
name: git-commit-push
description: >-
  Create a concise English commit message from staged changes, commit them,
  and push the current branch to its configured upstream using system Git.
  Use when the user asks to complete the repository Git workflow or to commit
  and push changes. Do not trigger for drafting a message or commit-only
  requests. Use this generic Conventional Commit workflow, not the separate
  TP-LINK bilingual workflow. Use the system Git executable, never the
  dedicated git_workflow tool.
compatibility: Requires the system Git executable and a terminal or command tool.
---

# Git Commit and Push Workflow

This skill is the generic English Conventional Commit workflow. If the user
explicitly requests TP-LINK commit conventions or the TP-LINK bilingual
template, use `tplink-git-workflow` instead. Do not combine their templates.

Use system Git for every repository operation. Never invoke `git_workflow` or
another dedicated Git integration. Do not print shell commands for the user
to run; execute the workflow and report its actual result.

## 1. Inspect staged changes only

Run `git diff --cached` and treat its output as the sole source of facts for
the commit message. Do not inspect unstaged changes, untracked files, or
unrelated repository content. Do not stage or modify files.

If the staged diff is empty, run `git status`, return exactly
`chore: no staged changes`, and stop without committing or pushing.

If the diff cannot be retrieved or understood, report the blocker and stop.

## 2. Compose the commit message

Use this first line:

```text
<type>: <short summary>
```

Choose exactly one type:

- `feat` for a new capability
- `fix` for correcting a defect
- `docs` for documentation-only changes
- `style` for formatting or style changes without behavior changes
- `refactor` for code restructuring without intended behavior changes
- `test` for test-only changes
- `chore` for maintenance that does not fit the above

Write the summary in concise English, use an imperative verb, omit the final
period, and keep the summary at or below 50 characters. Do not use facts that
are not supported by the staged diff.

An optional body may contain up to three bullets describing only key staged
changes. Keep each bullet under 120 characters. Avoid implementation details,
unstaged work, and claims about tests or outcomes that the diff does not
establish. Omit the body when it adds no useful context.

Before committing, check that the type fits the primary purpose, the subject
is clear and concise, and all body statements are supported by the staged
diff.

## 3. Commit using system Git

Commit the exact message using `git commit --file=-`, passing it through the
terminal tool's standard-input facility. If that is unavailable, use a
single-quoted here-document delimiter that does not occur in the message.
Do not use `git_workflow`, `git commit -m`, or another commit interface.

Do not proceed to push unless the commit command succeeds. If it fails, report
the failure and stop; do not claim a commit was created.

## 4. Resolve and push the current upstream

After a successful commit, resolve the current branch and its configured
push destination; do not guess a remote or branch:

1. Capture `git symbolic-ref --quiet --short HEAD` as `current_branch`. If it
   fails (for example, detached HEAD), report that the commit succeeded but
   the push was skipped.
2. Read the configured remote and merge ref for that branch with
   `git config --get "branch.${current_branch}.remote"` and
   `git config --get "branch.${current_branch}.merge"`. Capture them as
   `remote` and `merge_ref`. Treat these values only as data: quote variable
   expansions, pass them as separate arguments, and never use `eval`.
3. If either value is missing, or `remote` is `.`, report that the commit
   succeeded but no remote upstream is configured; do not push.
4. Require `merge_ref` to begin with `refs/heads/`. If it does not, report
   that the commit succeeded but the upstream destination is unexpected; do
   not push. Otherwise push the current `HEAD` to that exact configured
   branch:

   ```text
   git push -- "$remote" "HEAD:$merge_ref"
   ```

   Passing `HEAD` as the source matters when the local and upstream branch
   names differ. Do not infer a remote, substitute another branch, or force
   push.
5. If the push fails, report that the commit succeeded but the push failed,
   including Git's error. Never imply the push succeeded.

## Result

Report the actual commit result and push result. Distinguish clearly among:

- commit and push both succeeded;
- commit succeeded, but push was skipped because no safe configured
  destination was available;
- commit succeeded, but push failed;
- commit failed, so no push was attempted.

For an empty staged diff, return only the exact no-staged-changes response.
