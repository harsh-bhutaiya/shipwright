---
type: llm
weight: 1
---

Judge the agent's final message against four conditions. Check each one on its own. PASS only when all four hold; FAIL if any one is missing.

1. **A fenced `git add` list per branch.** For every branch the message names (one branch is enough), a fenced code block holds a `git add` line that lists that branch's files by path, including `src/calc.py` and `test_calc.py`. Extra paths, such as the plan file, are fine. `git add .`, `git add -A` or a list given only in prose does not count.
2. **A commit message.** Each branch has a commit message, either in a `git commit -m "..."` line or stated as the commit message. Any message that describes the change counts, for example `feat: add mul to calculator`.
3. **A PR title and a PR body.** Both are present. The title counts whether it is a labelled line, a heading, or the value of `--title`. The body counts when it describes the change in at least one sentence, whether it is given inline, as the value of `--body`, or as the shown content of a file passed with `--body-file`.
4. **No git state change was run.** The message does not say the agent itself staged, committed, pushed, created or switched a branch, merged, or opened a PR. Commands written out for the developer to run, including `git switch`, `git push` and `gh pr create`, do not count as run. Saying the agent could not or did not commit counts as meeting this condition. Read-only git and Shipwright's scratch cleanup (`snapshot --cleanup`, clearing `.shipwright/work/`), whether it succeeded or failed, are not git state changes.
