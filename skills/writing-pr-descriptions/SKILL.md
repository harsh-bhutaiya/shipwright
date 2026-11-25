---
name: writing-pr-descriptions
description: Use when finishing a branch and a pull request title and body are needed, whether or not Shipwright is allowed to open the PR.
---

# Writing PR Descriptions

Produce a title and a body for one branch. Read the branch's diff, the spec, the plan and the `shipwright:verifying-work` results; do not write from memory.

**Title:** one line, in the project's commit-message format (Conventional Commits if none is detected), imperative, at most 72 characters.

**Body**, in this order:

1. **What changed and why.** Two to five sentences: the behavior now, and the reason it was wanted.
2. **Decisions and trade-offs.** Each decision with what it costs if wrong, linking the spec section, for example `[spec §2.3](<docs_dir>/specs/<file>#...)`. Include the rulings recorded during the work.
3. **Acceptance checklist results.** Copy the plan's `## Acceptance checklist` lines for the cases this branch covers, ticked with the result the verifying-work run produced. A case that failed or was not run stays unticked with the reason. Never tick from memory.
4. **Risks.** Collect the tasks marked `Risky:` (anything other than `Risky: none`) with their categories, and what to watch after merge. Write `None flagged` only if every task says `Risky: none`.
5. **How to test.** Exact commands and manual steps a reviewer can run.

In a branch stack, say which branch this one is based on and what the next branch adds. Add the AI co-author trailer to commits only as `ai_coauthor` says; never put "Generated with" lines in the PR body unless the developer asks.

Output the title and body in a fenced block so the developer can paste it. With `commit_push=allowed`, the finishing skill passes them to the forge CLI.
