#!/usr/bin/env python3
"""Render confirmed module findings only after validating the session record."""

import argparse
import json
import os
from pathlib import Path
import sys
import tempfile

from validate_review_record import (
    RecordError, SEVERITIES, load_record, require, text, validate,
)


def render(record, issues, partial=False):
    summary = validate(record, issues, "progress" if partial else "integration")
    findings = sorted((issue for issue in issues.values() if issue["status"] == "confirmed"),
                      key=lambda issue: (SEVERITIES.index(issue["severity"]), issue["id"]))
    if partial:
        require(text(record["progress"].get("interruption")),
                "Partial report requires an observed interruption reason")
        lines = ["评审状态：未完成（阶段结果）",
                 "当前结论：" + ("需要修改" if findings else "尚不能判定"),
                 "中断原因：" + record["progress"]["interruption"]]
    else:
        lines = ["评审状态：已完成", "结论：" + ("需要修改" if findings else "通过")]
    mapping = {}
    axes = ("Standards", "Spec") if record["source"].get("spec_available") else (None,)
    require(record["source"].get("spec_available") or
            all(issue["axis"] != "Spec" for issue in findings),
            "Spec finding without a specification source")
    for axis in axes:
        if axis:
            lines += ["", "## " + ("Standards（规范符合性）" if axis == "Standards"
                                   else "Spec（需求符合性）")]
        group = [issue for issue in findings if axis is None or issue["axis"] == axis]
        if not group:
            lines.append("未发现明确问题。" if axis else
                         ("未发现明确的功能、安全、稳定性或规范问题。" if not partial
                          else "尚无已确认问题。"))
        for issue in group:
            mapping[issue["id"]] = f"finding-{len(mapping) + 1}"
            lines += ["", f"- [{issue['severity']}] {issue['location']}：{issue['summary']}",
                      "原因：" + issue["cause"], "建议：" + issue["recommendation"],
                      "规则：" + issue["rule"]]
    record["report_map"] = mapping
    if not partial:
        validate(record, issues, "final")
    unresolved = [trace["id"] for trace in record["traces"]
                  if trace["status"] in ("pending", "blocked")]
    excluded = [item["path"] + ": " + item["reason"]
                for item in record["inventory"]["files"] if item["status"] == "excluded"]
    lines += ["", f"评审范围：发现 {record['inventory']['discovered']} 个实现文件，"
              f"纳入 {summary['total']} 个，排除 {record['inventory']['excluded']} 个；"
              f"已逐文件初审 {summary['completed']}/{summary['total']} 个实现文件；"
              f"跨文件追踪 {len(record['traces']) - len(unresolved)}/{len(record['traces'])}；"
              f"已登记共享状态组闭环 {summary['state_completed']}/{summary['state_total']}；"
              + ("排除：" + "；".join(excluded) if excluded else "无排除文件。")]
    if record.get("limitations"):
        lines[-1] += " 限制：" + "；".join(record["limitations"])
    if partial:
        pending = summary["remaining_files"] + unresolved + summary["remaining_state_groups"] + [
            key for key, issue in issues.items() if issue["status"] in ("pending", "blocked")]
        lines.append("待续范围：" + ("、".join(pending) or "见记录中的阻塞项"))
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("record", type=Path)
    parser.add_argument("--partial", action="store_true")
    args = parser.parse_args()
    temporary = None
    try:
        path, record, issues = load_record(args.record)
        report = render(record, issues, args.partial)
        # Only the session record is updated; the reviewed repository is untouched.
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                         delete=False) as handle:
            temporary = Path(handle.name)
            json.dump(record, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
        _, saved, saved_issues = load_record(path)
        validate(saved, saved_issues, "progress" if args.partial else "final")
        report += f"续接记录：{path}；下一项检查：{record['progress']['next_step']}\n" \
            if args.partial else f"会话记录：{path}\n"
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f"Report generation refused: {error}", file=sys.stderr)
        return 1
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    print(report, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
