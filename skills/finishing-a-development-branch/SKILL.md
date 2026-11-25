---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work
---

# Finishing a Development Branch

## Overview

**Core principle:** Verify tests → Detect environment → Check consent → Hand over or execute → Record and clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify Tests

Run the project's full test suite (`npm test` / `cargo test` / `pytest` / `go test ./...`).

**If tests fail**, report the failures and stop — the menu comes after a green suite:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

**If tests pass:** continue to Step 2.

## Step 2: Detect Environment

```bash
gdir=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
gcommon=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# Capture now, while still inside the workspace — Step 5 changes directory
# before cleanup (Step 6) needs this value
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `gdir == gcommon` (normal repo) | Standard 3 options | No worktree to clean up |
| `gdir != gcommon`, named branch | Standard 3 options | Provenance-based (see Step 6) |
| `gdir != gcommon`, detached HEAD | Reduced 2 options (no merge) | Externally managed — leave in place |

## Step 3: Determine Base Branch

The base branch is whatever this work forked from — usually named in the
plan, the conversation, or the branch's upstream. If it is not already
known, ask: "This branch split from <your best guess> - is that correct?"
Confirm before merging: merging into the wrong base is expensive to undo.

## Step 3a: Check Consent

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get commit_push
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get pr_line_cap
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get ai_coauthor
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get docs_mode
```

**Completion summary.** Written only once the way of finishing is chosen (handover, Option 1 or Option 2), and before acting on it. Never for Option 3 or a discard. Append to the local spec file (`<docs_dir>/specs/...-design.md`; for a bug fix, the investigation write-up): what was built, the rulings (every recorded decision), and the review verdict. Then call `shipwright:publishing-docs` with it (it does nothing outside `shared-tool`). In `in-repo` mode, ship the spec and the plan with the work, new untracked files included:
- Handover: add the spec and the plan to the last branch's `git add` list.
- Option 1: commit the spec edit and the plan on the feature branch before the merge.
- Option 2: include the spec and the plan in the last commit before the push.

**Branch order.** Read the plan's `## Branch stack` section whenever it is there, one line per branch in stack order: `- <branch-name>: tasks <N-M>; based on <base branch>`. A single line names the one planned branch and its base. With `pr_line_cap` set, it is the task-to-branch map (spec §4.3: no file in two branches, each branch passes tests on its own, in stack order); use that order. With no `## Branch stack` section, there is one branch.

**Commit message format.** Detect the project's convention from CLAUDE.md, AGENTS.md, CONTRIBUTING, a commitlint config, `.cursor/rules` or recent `git log`. If none is found, use Conventional Commits. Plan Checkpoint lines already carry messages in this format; reuse them.

**AI co-author line.** `ai_coauthor=yes`: end each commit message with the co-author trailer. `no`: leave it out. `ask`: ask once, then use the answer for every branch.

**PR write-up.** Invoke `shipwright:writing-pr-descriptions` for each branch. Pass it the `shipwright:verifying-work` results (the acceptance checklist results).

### commit_push is not `allowed` (the default): handover

Run nothing that changes git state: no `git add`, `git commit`, `git push`, `git checkout -b`, `gh pr create`. Shipwright's guard denies them and the developer runs them. Skip the Step 4 menu and output, in a fenced block per branch:

1. The branch order (name each branch and its base).
2. For each branch: the directory to run it in, the branch-creation line, the `git add` file list (in `in-repo` mode the last branch's list also carries the spec and the plan, see Completion summary), and the commit message in the project's format.
3. The PR title and body from `shipwright:writing-pr-descriptions`.

```
# Branch 1 of N: <branch-name> (base: <base>)
cd <path of the working tree that holds the changes>
git checkout -b <branch-name> <base>  # leave out if already on <branch-name>
git add <path> <path>
git commit -m "<message>"
```

Pasted in order, the blocks build the stack: each branch is created from the one before it, and the files not yet committed carry over.

Then go to Step 7 (clean up). Nothing is merged or discarded here.

### commit_push is `allowed`

Continue to Step 4. In Option 2, commit each branch's files with the message above, push, and open the PR with the write-up as its body, one branch at a time in stack order.

## Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 3 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)

Which option?
```

**Detached HEAD — present exactly these 2 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)

Which option?
```

Present the menu exactly as written — concise, with every option coming
from the list above. Discarding the work happens only in response to your
human partner explicitly asking for it (see "If your human partner asks to
discard the work" below). Wait for their answer; the integration decision
is theirs.

## Step 5: Execute Choice

### Option 1: Merge Locally

First write the completion summary and commit the spec edit on the feature branch (`commit_push=allowed`), so the merge carries it and the worktree is clean. Then:

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>
```

If tests fail on the merged result: stop, leave the worktree and branch in
place, and investigate — nothing has been pushed, so the merge is local
and recoverable.

Once the merged result is green: clean up the worktree (Step 6), then
delete the branch:

```bash
git branch -d <feature-branch>
```

### Option 2: Push and Create PR

Commit first (only when `commit_push=allowed`): `git add` the branch's files (in `in-repo` mode the last branch also gets the spec and the plan, see Completion summary), commit with the project-format message. Then:

```bash
git push -u origin <feature-branch>
# From a detached HEAD, name the new branch on the remote:
# git push origin HEAD:refs/heads/<new-branch>
```

Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL to your human partner.

Keep the worktree — your human partner iterates on PR feedback there.

### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

### If your human partner asks to discard the work

This path exists only as a response to an explicit request to throw the
work away. Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. When it arrives:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then clean up the worktree (Step 6) and force-delete the branch:

```bash
git branch -D <feature-branch>
```

## Step 6: Cleanup Workspace

**Runs for Option 1 and confirmed discards.** Options 2 and 3 always
preserve the worktree. Both callers have already changed directory to the
main repo root — worktree removal must run from outside the worktree —
and use the `gdir`/`gcommon`/`WORKTREE_PATH` values captured in
Step 2, from before that directory change.

**If `gdir == gcommon`:** Normal repo, no worktree to clean up. Done.

**If `WORKTREE_PATH` is under `.worktrees/` or `worktrees/`:** Shipwright
created this worktree — we own cleanup:

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**If removal is refused** (`contains modified or untracked files`): the
worktree holds files that exist nowhere else — uncommitted plans, notes,
or scratch work. Never `--force` on your own initiative. Show your human
partner what is at stake and ask:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree removal refused — these files were never committed:

<file list>

1. Commit them to <branch> before cleanup
2. Move them into <main repo root>
3. Delete them (unrecoverable)

Which?
```

Carry out the choice, then remove the worktree.

**Otherwise:** The host environment owns this workspace — leave it in
place. If your platform provides a workspace-exit tool, use it.

## Step 7: Clean Up (only when the work is finished)

Runs after the handover, Option 1 or Option 2. It does **not** run for Option 3 (keep as-is) or a discard: the ledger and review packages are the resume state for "I'll handle it later".

1. **Plan file.** Kept beside the spec only when `docs_mode=in-repo`; otherwise it is working material and goes with the cleanup.
2. **Scratch git.** Run `bash "${CLAUDE_PLUGIN_ROOT}/skills/subagent-driven-development/scripts/snapshot" --cleanup`.
3. **Clear `.shipwright/work/`** (ledger, review packages, scratch notes), keeping `published.conf`:

```bash
if [ -d .shipwright/work ]; then find .shipwright/work -depth -mindepth 1 ! -name published.conf -delete; fi
```

`-depth` removes nested files before their directories. Directories that still hold `published.conf` stay (the delete of a non-empty directory fails harmlessly). Clearing scratch is not a git operation and runs in both consent cases.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| Discard (explicit request only) | - | - | - | yes (force) |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to integrate. A green run only proves the tree it ran on. |
| "They obviously want it merged" | Integration is your human partner's decision. Present the menu and wait. |
| "They seem done with this feature — I'll offer to discard it" | The menu is complete as written. Discard happens only when your human partner asks for it in so many words. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees under `.worktrees/` or `worktrees/`. Everything else belongs to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | The refusal means files exist only in that worktree. `--force` destroys them permanently. Show your human partner and ask. |
| "The merged-result failure is probably flaky" | A failing merged result stops everything. Branch and worktree stay put while you investigate. |
| "The base branch is obviously main" | Confirm the fork point or ask. Merging into the wrong base is expensive to undo. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request. |
