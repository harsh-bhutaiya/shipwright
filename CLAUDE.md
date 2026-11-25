# CLAUDE.md

This repo is a Claude Code plugin (`shipwright`) and its own team marketplace.

## Status

v0.2.1 is the latest release. v0.2.0 built Tasks 6-13 of `docs/superpowers/plans/2026-11-24-shipwright.md`, and v0.1.0 shipped earlier. Design: `docs/superpowers/specs/2026-11-24-shipwright-design.md`. Track decisions, open questions and progress in `docs/tracker.md` and update it whenever any of these change.

## Layout

- `.claude-plugin/plugin.json`: the plugin manifest.
- `.claude-plugin/marketplace.json`: the team marketplace; lists this plugin with `"source": "./"`.
- `skills/<name>/SKILL.md`: one skill per folder, with frontmatter `name` and `description`. The description says when to use it.
- `agents/<name>.md`: subagents, with frontmatter `name`, `description`, `tools`, `model`.
- `hooks/hooks.json`: hooks.

## Working on it

```bash
claude plugin validate .            # check manifests, skills, agents
claude --plugin-dir .               # load the plugin for one session without installing
claude plugin details shipwright   # component inventory and token cost (after install)
```

Develop with the Shipwright plugin disabled in this repo (its guard blocks edits to its own files and to `developer.conf` mentions).

The plugin must stay tech-stack agnostic. No skill may assume a language, framework, test runner, tracker or cloud. Read those from the target project.

## Conventions

- Claude does not run `git add`, `git commit`, `git push` or create branches here. The developer does. Suggest commit messages instead.
- Commit message format: `<category>: <summary>` (feat, fix, refactor, perf, docs, test, chore), then bullets in the past tense.
