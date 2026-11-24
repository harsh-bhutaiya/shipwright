# Upstream

Shipwright is forked from [obra/superpowers](https://github.com/obra/superpowers) v7.0.2 (MIT, copyright in `LICENSE`). Forked 2026-11-24.

## Kept (13 skills)

brainstorming, writing-plans, subagent-driven-development, dispatching-parallel-agents, executing-plans, test-driven-development, verification-before-completion, requesting-code-review, receiving-code-review, systematic-debugging, finishing-a-development-branch, using-git-worktrees, using-superpowers (renamed `using-shipwright`).

## Dropped

- `writing-skills`, `diagnosing-superpowers`: tools for maintaining a plugin, not for project work.
- Non-Claude harness folders (`.codex-plugin`, `.cursor-plugin`, `.devin-plugin`, `.hermes-plugin`, `.kimi-plugin`, `.muse-plugin`, `.antigravity-plugin`, `.opencode`, `.pi`, `.agents`) and the other harnesses' tool references in `using-shipwright`: Shipwright targets Claude Code only.
- `GEMINI.md`, `gemini-extension.json`: Gemini is not supported.
- Upstream tests for dropped parts, and tests that need a live `claude` session or network.

## Local changes

`superpowers:` is now `shipwright:`; the product name is Shipwright; `.superpowers/` is `.shipwright/work/`; `docs/superpowers/` is `docs/shipwright/`. The brainstorming visual companion no longer loads a remote logo or reads a version manifest.

## Picking up upstream fixes

1. Read upstream `RELEASE-NOTES.md` from 7.0.2 onward.
2. Diff each `skills/<name>` against the upstream tag.
3. Port wanted changes by hand, applying the renames above.
4. Update the version and date in this file.
