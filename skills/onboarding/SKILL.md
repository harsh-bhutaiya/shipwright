---
name: onboarding
description: Use when this is the first use of Shipwright in a project, or when the session-start context says the project is not onboarded (docs_mode is empty).
---

# Onboarding

The first time Shipwright works in a project, you record how this project and this developer want to work. The answers go in Shipwright's settings files, so nobody is asked twice.

**One question per message.** Each question comes with a one-line why. Never batch questions. Wait for the answer, record it, then ask the next.

Settings CLI (use it for every read and write):

```
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" set <key> <value>
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get <key>
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" exclude
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" summary
```

Project keys: `docs_mode`, `docs_dir`, `wiki_connector`, `wiki_location`, `plan_approval`, `pr_line_cap`, `observability`. Developer keys: `commit_push`, `ai_coauthor`.

## 0. Already onboarded?

Run `get docs_mode` first. `docs_mode` is written last (see step 9), so non-empty means onboarding finished. If it is non-empty, the project is already onboarded: show `summary`, ask once what the developer wants to change, and change only that. Do not run steps 1-11 and do not overwrite settings. Otherwise continue.

Say first, in one sentence, that this is a one-time setup and why: so Shipwright follows this project's rules instead of guessing. Then go through the steps in order.

## 1. Docs storage mode

Why: it decides whether specs and plans touch the repo, and some clients forbid docs in their repo.

Ask where docs should live:

1. **In repo:** committed and versioned with the code. For technical teams that want docs reviewed alongside code.
2. **Local only:** git-excluded. For client repos that forbid docs.
3. **Shared doc tool:** decisions live in a wiki, so they are shared without touching the repo.

Working files (progress notes, data-bearing investigation notes) stay local in every mode. The developer can change the choice at any time.

In local mode, if `docs/` is already tracked by git, choose a different `docs_dir`, or accept that the docs stay visible to git.

Remember the answer, but do not write `docs_mode` yet: it is written last, in step 9, so an interrupted onboarding leaves it empty and the project still counts as not onboarded.

## 2. Shared doc tool only

Skip this step unless the answer was `shared-tool`.

Why: Shipwright brings no connector of its own. It uses one you already have.

List the MCP connectors visible in this session. It needs four operations from the connector: search, read, create and update a page. Ask which one to use and which space or folder, in one question per message. Record `set wiki_connector <name>` and `set wiki_location <space or folder>` now.

If there is no suitable connector, say so and offer mode 1 or 2 instead; remember the new docs mode for step 9.

## 3. Plan approval

Why: it decides whether you review each plan before building.

Ask: `review` (default; a human approves every plan) or `auto`. Risky work is never auto-approved: even in `auto`, a plan with any risky task stops for a human, and Shipwright says which tasks are risky and why. Risky means:

1. database schema changes, data migrations or backfills
2. deleting or overwriting data or files outside the feature
3. authentication, authorisation, permissions, secrets or security settings
4. money: payments, billing, pricing
5. a change to a public API or contract that other systems call
6. infrastructure, deployment or CI configuration
7. adding or upgrading dependencies
8. anything irreversible or touching production
9. a plan that touches the project's recorded "do not change" areas, if the project lists any

Record it: `set plan_approval review|auto`.

## 4. Commit and push consent

Why: a commit carries the developer's name, so only the developer can say yes.

Explain: this switch belongs to the developer, not the project. The default is off.

- **Off (default):** Shipwright never runs `git add`, `git commit` or `git push` on your branches. When the work is done it hands over the branch order, for each branch the files to stage and a commit message in the project's format, and the PR title and description.
- **On:** Shipwright commits on the planned branch in your name, using your git identity, and may push. One switch covers commit and push.

**Never run `set commit_push` yourself.** A hook blocks it, and consent can only come from the developer. If they want it on, tell them to run this in their own terminal, outside Claude Code (fill in the real paths; the plugin root is the directory containing `scripts/shipwright-config`, the repo root is `git rev-parse --show-toplevel`):

```
"<resolved plugin root>/scripts/shipwright-config" -C "<repo root>" set commit_push allowed
```

If step 10 added deny rules to `.claude/settings.local.json`, tell them to remove those rules after turning consent on, otherwise commits stay blocked. Once they say they ran it, confirm with `get commit_push`. If they keep the default, `get commit_push` returns `not-allowed`; nothing to write.

## 5. AI co-author line

Why: some projects want a `Co-Authored-By` line on AI-assisted commits, others forbid it.

First look for the project's convention: its commit guidelines (`CONTRIBUTING`, `CLAUDE.md`, rules files) and recent `git log` messages. If a convention exists, follow it and say what you found; record `set ai_coauthor yes` or `no`. If none exists, ask once: yes, no, or ask each time. Record the answer (`yes|no|ask`).

## 6. PR line cap (optional)

Why: a cap keeps changes reviewable; many teams have none.

Ask whether there is a maximum number of changed lines per PR. A number sets `set pr_line_cap <n>`. No cap: leave it empty.

## 7. Observability

Detect; do not ask unless nothing is found. Platforms differ by project and none gets priority.

1. Look at the connectors installed in this session, and at the project: dependencies and SDK imports for tracing, errors or metrics, config files and docs.
2. Found something: say which platform and where, and record its name with `set observability <name>`. No question is needed.
3. Found nothing: ask whether the project has observability and how to reach it (links, exports or read-only API access). If there is none, `set observability none`.

Observability access is read-only, always.

## 8. Coding standards

Detect; do not ask. The order is:

1. If coding standards are defined in any file in the project, follow them.
2. Otherwise follow the project's existing code patterns.
3. If the code is not well managed, so there is no consistent pattern to follow, flag that to the developer once, with evidence (files and examples), and follow industry standards: the language's or framework's official style guide, plus any linters or formatters already configured in the repo.

A written standard wins over existing code for new code; flag a mismatch and do not rewrite existing code unless asked. Flag once, now, not on every task. Nothing is written to settings for this step.

## 9. Write docs_mode, then exclude

Order matters. Run `set docs_mode <answer from step 1>` now, last of all the answers, then `"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" exclude`, because `exclude` reads `docs_mode`. Writing `docs_mode` last means an interrupted onboarding is retried next session.

## 10. Deny rules (only if commit_push is not allowed)

Check `get commit_push`. If it is `not-allowed`, offer, as a question of its own with a one-line why (a permission rule blocks the commands even if an instruction is forgotten), to add these deny rules to `.claude/settings.local.json`: `Bash(git commit *)`, `Bash(git push *)`, `Bash(git add *)`.

Write the file only after the developer says yes. If the file exists, read it and merge: keep every existing key and rule, add the three entries to `permissions.deny` without duplicates. Then make sure `.claude/settings.local.json` is git-excluded: check with `git check-ignore .claude/settings.local.json` (exit 1 means not ignored yet, so add the exclusion; it is not an error); if it is not ignored, add it to the repo's `info/exclude` (under `git rev-parse --git-common-dir`, so it works in worktrees), or tell the developer. Outside a git repo, skip the check and say so in one line. If they say no to the deny rules, skip all of this.

## 11. Summary

Run `"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" summary` and show its output. Then carry on with the developer's original request, starting with the skill that applies to it.

## Rules

- You never run `git add`, `git commit` or `git push`, and never create branches, during onboarding.
- One question per message. No batching, even when answers seem obvious.
- Do not assume a language, framework, tracker or vendor: read them from the project.
