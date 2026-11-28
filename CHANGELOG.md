# Changelog

## 0.3.0 — 2026-11-28

- `skills/ai-engineering`: a head skill for projects that call LLMs. It names the `ai-*` skill for each step and task, and holds their shared rules and the rule marks (`[security]`, `[reliability]`, `[practice]`).
- 16 `ai-*` topic skills: architecture decisions, LLM calls, tool use, agents, context management, RAG, prompt engineering, evaluation, testing, observability, cost and latency, prompt injection, security and privacy, guardrails, model lifecycle and UX. Each has Rules, Ask the developer, Checks and Related skills.
- `skills/using-shipwright`: points to `shipwright:ai-engineering` in projects that call LLMs.
- `tests/skills/test-ai-skills.sh`: checks the 17 AI skills' frontmatter, descriptions, sections, rule marks, cross-references and length, with a self-test against fixtures.
- Evals `ai-new-call-gets-timeout`, `ai-written-choice-wins`, `ai-tool-result-size-asked` and `ai-skills-quiet-elsewhere`.
- `skills/investigating-issues`: always dispatches the read-only `shipwright:investigator` for code, logs and reproduction, even in a small repo. An eval showed it skipped the agent on small repos 4 times out of 6.
- Evals `plan-auto-proceeds` (an auto-approved plan with no risky task starts the build on its own), `investigate-dispatches-investigator` (the bug flow dispatches the investigator) and `finish-allowed-commits` (with commit consent on, finishing commits the work and the spec summary, merges locally and does not push).

## 0.2.1 — 2026-11-25

- `scripts/shipwright-config exclude`: each marker now names the line it manages. A marker whose line was hand-deleted is dropped without taking the developer's next line with it, and v0.2.0's markers are rewritten in the new form.
- `scripts/shipwright-config exclude`: rewriting `.git/info/exclude` keeps its permissions.
- `skills/finishing-a-development-branch`: the handover creates branches with `git checkout -b`.

## 0.2.0 — 2026-11-25

- `skills/publishing-docs`: one-way publish of specs, plans and write-ups to the wiki when `docs_mode` is `shared-tool`.
- `skills/brainstorming`: the coding standards ladder and pushback on decisions that contradict recorded ones.
- `skills/writing-plans`: `Risky:` lines, the approval rule, Checkpoints, `## Branch stack` and `## Acceptance checklist`.
- `skills/subagent-driven-development`: snapshot-based reviews (`scripts/snapshot` with `--lane`, `--apply-lane`, `--cleanup`) and the split stop rule.
- `skills/verifying-work`: runs the acceptance checklist, fixes and re-checks, escalates after 3 failed attempts.
- `skills/finishing-a-development-branch`: hands over files and commit messages when commit consent is off.
- `skills/writing-pr-descriptions`: PR title and body from the diff, spec, plan and verification results.
- `skills/investigating-issues` and `agents/investigator.md`: read-only bug investigation before any fix.
- `docs_mode=shared-tool` and `plan_approval=auto` now take effect.
- `scripts/shipwright-config`: `shared-tool` mode now git-excludes `docs_dir`, as `local` does.
- `scripts/shipwright-config exclude`: writes a marker comment above each line it adds and manages only the lines under its markers. It drops one when the docs mode no longer needs it, or when `docs_dir` changes or gains tracked files.

## 0.1.0 — 2026-11-25

Milestone 1.

- Forked skills: superpowers 7.0.2 skills adapted to `shipwright:` references (see `UPSTREAM.md`).
- `scripts/shipwright-config`: reads and writes the project and developer settings.
- `hooks/guard-git`: PreToolUse hook that blocks staging, commits, pushes and branch changes unless the developer turns consent on.
- `hooks/session-start`: injects the using-shipwright skill and a one-line settings summary.
- `skills/onboarding`: asks the setup questions one at a time and saves the answers.

Known limits: see "Known limits" in `README.md`.
