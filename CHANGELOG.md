# Changelog

## 0.1.0 — 2026-11-25

Milestone 1.

- Forked skills: superpowers 7.0.2 skills adapted to `shipwright:` references (see `UPSTREAM.md`).
- `scripts/shipwright-config`: reads and writes the project and developer settings.
- `hooks/guard-git`: PreToolUse hook that blocks staging, commits, pushes and branch changes unless the developer turns consent on.
- `hooks/session-start`: injects the using-shipwright skill and a one-line settings summary.
- `skills/onboarding`: asks the setup questions one at a time and saves the answers.

Known limits: see "Known limits" in `README.md`.
