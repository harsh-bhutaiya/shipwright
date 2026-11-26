# Shipwright

Shipwright is a Claude Code plugin for a team development workflow that works in any project and tech stack. It takes a feature from requirements to a plan, a build and a PR hand-over, and has a structured flow for investigating bugs. Version 0.2.0 adds the full feature flow, bug investigation and a verification loop (see "What's in v0.2").

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
| `wiki_connector` | empty | Name of the MCP connector used when `docs_mode` is `shared-tool` |
| `wiki_location` | empty | Space or folder in that tool |
| `plan_approval` | `review` | `review`: a human approves plans. `auto`: plans are auto-approved unless they touch a risky category, which always stops for a human |
| `pr_line_cap` | empty (no cap) | Maximum non-test lines per PR (branch); a positive integer |
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
- In `local` and `shared-tool` modes the docs folder is git-excluded as well.

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
- A shell alias defined in the same command is not detected (`shopt -s expand_aliases`, then `alias g='git branch'`, then `g new`, on separate lines).
- A symlink to the real index (`ln -s .git/index /tmp/i`, then `GIT_INDEX_FILE=/tmp/i`).
- `--output` passed through shell expansion or `xargs`.
- Dashed `git-*` binaries reached through a PATH override, and `exec -a`.
- Bash writes into the plugin directory (`sed -i` on a hook): only file tools are protected.
- Program-running settings already in the developer's own git config (`diff.external`, `core.pager`): `-c` is blocked, existing config is not.
- Windows: untested. 8.3 short names are not handled, and messages show Git Bash paths (`/c/...`).
- Very large commands (several MB) time out.
- A harmless non-git command with any word after a path ending in `/git`, such as `ls /opt/homebrew/bin/git 2>&1` or `stat /usr/bin/git >/dev/null`, is denied (fails safe).
- Exclude lines written by v0.1 carry no marker, so `exclude` does not remove them. A repo onboarded under v0.1 that switches to `in-repo` must delete `/<docs_dir>/` (default `/docs/`) and `/.shipwright/project.conf` from `.git/info/exclude` by hand.
- Only `git` run through Bash is checked. Claude Code's own worktree tool, `gh` (for example `gh pr checkout`, `gh pr merge`, `gh repo sync`) and MCP git/GitHub tools are not guarded.
- If `run-hook.cmd` finds no bash (Windows without Git Bash), the guard does not run at all (fails open).
- Fail-closed hooks (`onFailure: block`) need Claude Code v2.1.295 or later.
- False positives (the guard errs on the side of denying): `git -c ... diff`, `cat .git/HEAD`, `GIT_PAGER=cat git log`, `$` or `{` in grep patterns, `git branch -av`, `git tag -l`, `git stash list`, `git config <key>` reads, and text such as `echo "git commit"`.

## What's in v0.2

Feature flow:

- `brainstorming` applies the standards ladder (project files, then existing code patterns, then industry standards, flagging poorly managed code) and pushes back on requests that contradict recorded decisions.
- `writing-plans` marks each task `Risky:` (or `Risky: none`), applies the approval rule, adds a Checkpoint per task when commits are not allowed, and carries `## Branch stack` and `## Acceptance checklist` sections after the header, before the tasks.
- `subagent-driven-development` reviews private snapshots (`scripts/snapshot`, with `--lane`, `--apply-lane` and `--cleanup`) instead of commits, and uses a split stop rule: stop for what changes the build or is risky, decide and record the rest.
- `publishing-docs` copies specs, plans and write-ups to the wiki when `docs_mode` is `shared-tool` (one way, local file is the source).
- `finishing-a-development-branch` hands over files and commit messages per branch (one branch unless `pr_line_cap` splits the work into a stack) when commit consent is off, with PR text from `writing-pr-descriptions`.

Bug flow: `investigating-issues` finds the cause before any fix and writes up the finding in `<docs_dir>/investigations/`, describing data by its shape, never real values. It checks observability connectors and the database (through a read-only connector) in the main session, and hands code, logs and reproduction to a read-only `investigator` agent.

Verification loop: `verifying-work` runs the plan's whole acceptance checklist against the real thing, fixes and re-checks, and escalates with evidence after 3 failed attempts on the same problem.

Some forked skills may still tell Claude to commit. The guard blocks those calls unless consent is on, and the session-start guidance tells the agent to leave changes in the working tree and hand over commit messages instead.

## Developing Shipwright

Run the tests:

```bash
bash tests/run-all.sh
```

CI runs these tests on Ubuntu and on macOS's bash 3.2, and runs ShellCheck 0.10.0, on every pull request. It posts the results as a comment on the PR.

Run the behaviour evals (real Claude runs, so they cost money; CI does not run them):

```bash
claude plugin eval . --runs 1 --ablation none --no-publish --trust-plugin --scaffold --allow-tools Bash Edit Write
```

On macOS, install a git that is not Apple's Xcode shim first (`brew install git`): the eval sandbox blocks the shim, so every case that runs git fails without it.

Develop with the Shipwright plugin disabled in this repo. The guard and its self-protection rules trip on Shipwright's own sources.
