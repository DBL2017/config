# Commit Message Rules

Use exactly one section per language: English first, then Chinese after one
blank line. Put a blank line between every title, label, and field value in
each section. Both titles must start with the same bracketed module or device
identifier, such as `[tplink-code-review]`; retain the square brackets in the
English title as well as the Chinese title. All labels must correspond to the
same selected category. Do not add Conventional Commit prefixes such as
`feat:` or `fix:`.

The labels below are literal: preserve spelling, capitalization, and square
brackets. Do not include template explanations or labels from other
categories.

## Bug fix

English title:

```text
[Module] Fix Bug BUG_ID: Description
```

English body, with these labels and this order only:

```text
[Issue Description]
<Describe the problem>

[Root Cause]
<Explain the root cause>

[Solution]
<Describe the fix>

[Test Scope]
<List evidenced test cases, or leave empty when unevidenced>
```

Chinese title and body:

```text
[Module] Fix Bug BUG_ID: 描述

[问题描述]
<描述问题现象>

[问题原因]
<说明问题根源>

[解决方案]
<描述修复方案>

[自测内容]
<列出暂存区明确提供的测试要点>
```

The module name and Bug ID must match across titles. Keep the module name
unchanged in Chinese; never replace it with `[模块名]`. If the staged diff
does not provide a Bug ID, omit the `Fix Bug BUG_ID:` part of the title and
keep the module identifier and description. Do not guess an ID and do not
write a missing-information marker.
Keep both titles within 65 characters; if the module name and description
cannot fit, shorten the description rather than exceeding the limit.

Bug issue-description lines must not exceed 70 characters. Keep every body
label even when the staged diff does not establish its content; in that case
output the label with an empty value (no text on the following line). Never
write `Not specified in staged changes`, `暂存区未提供`, or any other
placeholder. Do not state an inferred root cause as fact.

Allowed labels only:

- English: `Issue Description`, `Root Cause`, `Solution`, `Test Scope`
- Chinese: `问题描述`, `问题原因`, `解决方案`, `自测内容`

## Device adaptation

English title:

```text
[Device Model] Description
```

English body:

```text
[Model Adaptation]
<Describe the device-specific adaptation, or leave empty when unevidenced>

[Test Scope]
<List evidenced test cases>
```

Chinese title and body:

```text
[Device Model] 描述

[机型适配]
<描述机型适配内容>

[自测内容]
<列出暂存区明确提供的测试要点>
```

Keep the device model identical in both titles; do not use `[机型名]` as a
placeholder. If the staged diff does not identify the device model, do not
invent one; leave the bracketed model identifier empty and keep the
description.
For missing adaptation or test details, keep the label and leave its content
empty.
Keep both titles within 65 characters.

Allowed labels only:

- English: `Model Adaptation`, `Test Scope`
- Chinese: `机型适配`, `自测内容`

## Feature

English title:

```text
[Module] Description
```

English body:

```text
[Requirement]
<Describe the requirement, including Ref: TLXXXX when applicable, or leave
empty when unevidenced>

[Test Scope]
<List evidenced test cases>
```

Chinese title and body:

```text
[Module] 描述

[需求]
<描述需求；仅在暂存区提供时包含 Ref: TLXXXX>

[自测内容]
<列出暂存区明确提供的测试要点>
```

Keep the module name identical in both titles; do not use `[模块名]` as a
placeholder. Include a `Ref: TLXXXX` reference only when it appears in the
staged diff. If requirement details or test scope are not evidenced, keep the
label and leave its content empty.

Allowed labels only:

- English: `Requirement`, `Test Scope`
- Chinese: `需求`, `自测内容`

## Final consistency check

- Each title is at most 65 characters.
- English and Chinese titles identify the same module or device, category,
  and Bug ID where applicable.
- The English and Chinese sections contain only their category's allowed
  labels, in the order shown above.
- No test, requirement, root-cause, or device detail is inferred from code
  behavior unless that fact is explicitly present in the staged diff.
- Missing information is not filled with generic statements such as
  “verified the changes” or “tested the implementation.”
- Unevidenced fields keep their label with empty content; no placeholder text
  appears anywhere in the message.
