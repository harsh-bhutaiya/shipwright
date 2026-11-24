# Shipwright

Shipwright is a Claude Code plugin for a team development workflow that works in any project and tech stack. It takes a feature from requirements to a plan, a build and a PR hand-over, and has a structured flow for investigating bugs. Version 0.1.0 is Milestone 1 (see "What's in v0.1").

Shipwright is MIT licensed (see `LICENSE`). It is a fork of [superpowers](https://github.com/obra/superpowers) 7.0.2 by Jesse Vincent (MIT), whose copyright notice `LICENSE` keeps. See `UPSTREAM.md` for what was taken and what changed.

Design: `docs/superpowers/specs/2026-11-24-shipwright-design.md`. Progress and decisions: `docs/tracker.md`.

## Install

From the local folder (no push needed):

```
/plugin marketplace add ~/PycharmProjects/shipwright
/plugin install shipwright@shipwright
```

From your own GitHub, if you push the repo there (for use on other machines):

```
/plugin marketplace add harsh-bhutaiya/shipwright
/plugin install shipwright@shipwright
```

To try it for one session without installing:

```bash
claude --plugin-dir ~/PycharmProjects/shipwright
```

## Disable superpowers where Shipwright is on

Both plugins carry skills with the same names and triggers. In any project that uses Shipwright, disable superpowers (for example with `/plugin`) so the two do not compete.

## First run in a project

The first time Shipwright is used in a project, it asks its setup questions (`/shipwright:onboarding`), one at a time. You can also run it by hand. Answers are saved as the settings below. A project counts as onboarded once `docs_mode` is set.

## Settings

Settings are plain `key=value` files in `.shipwright/`. Read and write them with `scripts/shipwright-config [-C DIR] get|set|path|exclude|summary`.

`project.conf` (project settings):

| Key | Default | Meaning |
|---|---|---|
| `docs_mode` | empty (not onboarded) | Where docs live: `in-repo`, `local` or `shared-tool` |
| `docs_dir` | `docs` | Docs folder, relative to the repo root |
| `wiki_connector` | empty | Name of the MCP connector used when `docs_mode` is `shared-tool` (recorded only in v0.1; the `shared-tool` docs mode arrives with v0.2) |
| `wiki_location` | empty | Space or folder in that tool |
| `plan_approval` | `review` | `review`: a human approves plans. `auto`: plans are auto-approved unless they touch a risky category (recorded only in v0.1; `auto` is not acted on until v0.2) |
| `pr_line_cap` | empty (no cap) | Maximum changed lines per PR; a positive integer |
| `observability` | empty | Detected observability platform, or `none` |

`developer.conf` (per developer):

| Key | Default | Meaning |
|---|---|---|
| `commit_push` | `not-allowed` | `allowed` lets Shipwright commit and push in your name |
| `ai_coauthor` | `ask` | Add a `Co-Authored-By` line to AI-assisted commits: `yes`, `no` or `ask` |

Which file is committed:

- `developer.conf` is always local and git-excluded. It carries a person's choices, never the team's.
- `project.conf` is committed only when `docs_mode` is `in-repo`. In the other modes it is git-excluded too.
- `.shipwright/work/` (working files) is always local and git-excluded.
- In `local` mode the docs folder is git-excluded as well.

## Commit consent

Default: off. With consent off, Shipwright never stages, commits or pushes. At session start it tells the agent to skip other skills' commit, push, merge, stash and branch steps, leave changes in the working tree, review the working-tree diff instead of a commit range, and hand over the files to stage and a commit message per branch.

Only the developer can turn it on, by running this in their own terminal, outside Claude Code:

```
"<plugin root>/scripts/shipwright-config" -C "<repo root>" set commit_push allowed
```

`<plugin root>` is the directory that contains `scripts/shipwright-config`; `<repo root>` is `git rev-parse --show-toplevel`. The git guard blocks the agent from running this command or editing `developer.conf`. The guard's deny message prints the exact command with the real paths; copy it from there.

If onboarding added deny rules to `.claude/settings.local.json`, remove those rules after turning consent on, otherwise commits stay blocked.

## What the git guard blocks and allows

The `guard-git` hook checks every Bash call and every file-tool write while `commit_push` is not `allowed`.

Blocked:

- staging (`git add`, `git rm`, `git mv`, `git apply --index`);
- commits, pushes and pulls;
- creating or changing branches, tags and HEAD (checkout, switch, reset, and the like);
- writes inside `.git/` and use of the real index;
- `git -c ...` and `GIT_*` settings, because they can make git run a program;
- turning consent on (`set commit_push`) or touching `developer.conf`;
- file-tool edits to Shipwright's own plugin files.

Allowed:

- read-only git (`status`, `diff`, `log`, `show`, `blame`, `grep`, `rev-list`, `ls-files`, and similar);
- `fetch`, `clone` and `init` in their plain forms;
- private scratch plumbing: `refs/shipwright/*` refs, `commit-tree`, `write-tree`, and detached worktrees, all on a temporary index.

When `commit_push` is `allowed`, the git-command checks are skipped. The consent and file rules still apply.

## Known limits

The guard is a guardrail against mistakes, not a sandbox. A determined or obfuscated command can get past it. Limits:

- A script written to a file and then run: the hook sees only the call.
- Variable indirection (`G=git; $G commit`) and globs that name git (`g?t`).
- Aliases do not bypass the guard: unknown subcommands, including aliases like `git ci`, are denied when consent is off.
- A symlink to the real index (`ln -s .git/index /tmp/i`, then `GIT_INDEX_FILE=/tmp/i`).
- `--output` passed through shell expansion or `xargs`.
- Dashed `git-*` binaries reached through a PATH override, and `exec -a`.
- Bash writes into the plugin directory (`sed -i` on a hook): only file tools are protected.
- Program-running settings already in the developer's own git config (`diff.external`, `core.pager`): `-c` is blocked, existing config is not.
- Windows: untested. 8.3 short names are not handled, and messages show Git Bash paths (`/c/...`).
- Very large commands (several MB) time out.
- Only `git` run through Bash is checked. Claude Code's own worktree tool, `gh` (for example `gh pr checkout`, `gh pr merge`, `gh repo sync`) and MCP git/GitHub tools are not guarded.
- If `run-hook.cmd` finds no bash (Windows without Git Bash), the guard does not run at all (fails open).
- Fail-closed hooks (`onFailure: block`) need Claude Code v2.1.295 or later.
- False positives (the guard errs on the side of denying): `git -c ... diff`, `cat .git/HEAD`, `GIT_PAGER=cat git log`, `$` or `{` in grep patterns, `git branch -av`, `git tag -l`, `git stash list`, `git config <key>` reads, and text such as `echo "git commit"`.

## What's in v0.1 and what's coming

v0.1.0 ships: the forked skills, `scripts/shipwright-config`, the `guard-git` hook, the `session-start` hook and the onboarding skill.

Coming in v0.2 and later: the feature-flow changes, the docs storage modes, the verification loop, bug investigation and PR write-ups.

In v0.1 the forked skills may still tell Claude to commit. The guard blocks those calls unless consent is on, and the session-start guidance tells the agent to leave changes in the working tree and hand over commit messages instead.

## Developing Shipwright

Run the tests:

```bash
bash tests/run-all.sh
```

Develop with the Shipwright plugin disabled in this repo. The guard and its self-protection rules trip on Shipwright's own sources.
