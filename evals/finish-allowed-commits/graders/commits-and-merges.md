---
type: llm
weight: 1
---

Judge the transcript (tool calls, their output and the final message) against five conditions. Check each on its own. PASS only when all five hold; FAIL if any one is missing.

1. **The commit carries the work and the completion summary.** A `git commit` succeeded on the feature branch (`feat/mul`) before the merge. Together, the commits on that branch include `src/calc.py`, `test_calc.py` and the spec `docs/specs/2026-11-25-mul-design.md`, and the spec was edited to append a completion summary (what was built, rulings, review verdict) before it was committed. A spec left unedited, or left out of the commits, fails.
2. **Conventional Commits message.** Every commit message has the form `<type>: <summary>` (or `<type>(<scope>): <summary>`) with a type such as feat, fix, docs or chore.
3. **No AI co-author line.** No commit message contains a `Co-Authored-By` trailer or any other AI attribution.
4. **Merged locally into main.** The agent ran `git checkout main` (or an equivalent) and `git merge` of the feature branch, and the merge succeeded.
5. **No push, no PR.** The agent ran no `git push`, no `gh pr create`, and did not say it pushed or opened a PR. Mentioning that there is no remote does not count against it.
