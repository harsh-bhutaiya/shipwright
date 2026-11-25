#!/usr/bin/env bash
# Tests for scripts/snapshot and review-package over snapshot refs. Every repo
# is a mktemp -d repo; nothing touches the plugin repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDD_SCRIPTS="$(cd "$SCRIPT_DIR/../.." && pwd)/skills/subagent-driven-development/scripts"

FAILURES=0
TEST_ROOT=""
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
check() { # name, command...
    local name=$1; shift
    if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}
cleanup() { [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"; return 0; }

devstate() { # developer-visible git state, must never change
    git -C "$1" log --oneline; git -C "$1" stash list
    git -C "$1" diff --cached; git -C "$1" status --porcelain
}

main() {
    echo "=== Test: snapshot and review-package snapshots ==="
    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT
    local repo snap="$SDD_SCRIPTS/snapshot"
    mkdir "$TEST_ROOT/repo" && repo="$(cd "$TEST_ROOT/repo" && pwd -P)"
    git init -q -b main "$repo"
    git -C "$repo" config user.email t@example.com
    git -C "$repo" config user.name t
    printf 'one\n' > "$repo/tracked.txt"
    printf 'gone\n' > "$repo/doomed.txt"
    printf 'ignored.log\n' > "$repo/.gitignore"
    git -C "$repo" add . && git -C "$repo" commit -q -m init
    printf '# Plan\n' > "$repo/plan.md"
    mkdir -p "$repo/.shipwright/work/sdd/x"
    echo scratch > "$repo/.shipwright/work/sdd/x/ledger"

    printf 'two\n' >> "$repo/tracked.txt"
    rm "$repo/doomed.txt"
    printf 'new\n' > "$repo/with space.txt"
    printf 'x\n' > "$repo/ignored.log"
    git -C "$repo" add with\ space.txt
    printf 'staged-then-edited\n' >> "$repo/with space.txt"
    local before; before="$(devstate "$repo")"

    # --- snapshot ---
    local out
    out="$(bash "$snap" -C "$repo" a)" || true
    if [[ "$out" == "refs/shipwright/a" ]]; then pass "snapshot prints the ref"; else fail "snapshot prints the ref"; fi
    check "ref exists" git -C "$repo" rev-parse --verify --quiet refs/shipwright/a
    # git diff <commit> ignores untracked files, so only plan.md (untracked, in the snapshot) may differ.
    check "snapshot matches the dirty tree (tracked diff empty)" test "$(git -C "$repo" diff --name-only refs/shipwright/a)" = plan.md
    check "snapshot omits .shipwright/" test -z "$(git -C "$repo" ls-tree -r --name-only refs/shipwright/a | grep '^\.shipwright/' || true)"
    check "snapshot omits ignored files" test -z "$(git -C "$repo" ls-tree -r --name-only refs/shipwright/a | grep 'ignored.log' || true)"
    check "snapshot records deletions" test -z "$(git -C "$repo" ls-tree -r --name-only refs/shipwright/a | grep doomed || true)"
    check "snapshot parent is HEAD" test "$(git -C "$repo" rev-parse refs/shipwright/a^)" = "$(git -C "$repo" rev-parse HEAD)"
    check "developer state unchanged after snapshot" test "$before" = "$(devstate "$repo")"

    local rc=0
    bash "$snap" -C "$repo" 'bad label' >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 2 ]]; then pass "bad label exits 2"; else fail "bad label exits 2"; fi

    # --- review-package over snapshots ---
    printf 'three\n' >> "$repo/tracked.txt"
    printf 'brand new\n' > "$repo/fresh.txt"
    bash "$snap" -C "$repo" b >/dev/null
    local pkg="$TEST_ROOT/pkg.diff"
    (cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md refs/shipwright/a refs/shipwright/b "$pkg") >/dev/null || true
    check "package holds the a->b change" grep -q '^+three' "$pkg"
    check "package excludes changes already in a" test -z "$(grep '^+two' "$pkg" || true)"
    check "untracked file appears in a->b diff" test -n "$(git -C "$repo" diff refs/shipwright/a refs/shipwright/b --name-only | grep fresh.txt || true)"
    check "untracked file appears in package" grep -q 'fresh.txt' "$pkg"
    (cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md refs/shipwright/a refs/shipwright/b) >/dev/null || true
    check "default outfile lands in the plan workspace" ls "$repo"/.shipwright/work/sdd/plan/review-*.diff
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md refs/shipwright/b refs/shipwright/b "$pkg") >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 3 ]]; then pass "identical snapshots exit 3"; else fail "identical snapshots exit 3"; fi

    # --- lanes ---
    local lane
    lane="$(bash "$snap" -C "$repo" --lane l1 refs/shipwright/b)" || true
    check "lane is under .shipwright/work/lanes" test "$lane" = "$repo/.shipwright/work/lanes/l1"
    check "lane holds the snapshot state" grep -q three "$lane/tracked.txt"
    printf 'lane edit\n' >> "$lane/tracked.txt"
    bash "$snap" -C "$lane" l1done >/dev/null
    git -C "$repo" diff refs/shipwright/b refs/shipwright/l1done | git -C "$repo" apply
    check "lane patch applies to the main tree" grep -q 'lane edit' "$repo/tracked.txt"

    # --- task-done with a snapshot BASE ---
    local ep="$SCRIPT_DIR/../../skills/executing-plans/scripts/task-done" tdout
    bash "$snap" -C "$repo" tb >/dev/null
    printf "more\n" >> "$repo/fresh.txt"
    tdout="$(cd "$repo" && bash "$ep" plan.md 1 refs/shipwright/tb -- true)" || true
    check "task-done closes a snapshot BASE with a task-1-done snapshot" git -C "$repo" rev-parse --verify --quiet refs/shipwright/task-1-done
    check "task-done ledger line spans the snapshots" test -n "$(grep -F "$(git -C "$repo" rev-parse --short=7 refs/shipwright/tb)..$(git -C "$repo" rev-parse --short=7 refs/shipwright/task-1-done)" <<<"$tdout" || true)"

    # --- apply-lane: the guard sees one bash command, so it must pass the guard ---
    local cmd="bash $snap -C $repo --apply-lane refs/shipwright/b refs/shipwright/l1done"
    check "guard allows the apply-lane command with commit_push unset" test -z "$(printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$repo" "$cmd" | "$SCRIPT_DIR/../../hooks/run-hook.cmd" guard-git)"
    printf "base\n" > "$repo/bin.dat"; bash "$snap" -C "$repo" ab >/dev/null
    bash "$snap" -C "$repo" --lane l2 refs/shipwright/ab >/dev/null; printf "\001\002lane\n" > "$repo/.shipwright/work/lanes/l2/bin2.dat"
    bash "$snap" -C "$repo/.shipwright/work/lanes/l2" l2done >/dev/null
    bash "$snap" -C "$repo" --apply-lane refs/shipwright/ab refs/shipwright/l2done
    check "apply-lane brings a binary lane file into the main tree" test -f "$repo/bin2.dat"

    # --- staged-only changes ---
    printf "staged\n" > "$repo/staged-new.txt"; git -C "$repo" add staged-new.txt
    git -C "$repo" rm -q -f tracked.txt
    local ibefore; ibefore="$(cksum < "$repo/.git/index")"
    bash "$snap" -C "$repo" st >/dev/null
    check "staged-new file is in the snapshot" git -C "$repo" cat-file -e refs/shipwright/st:staged-new.txt
    check "staged-deleted file is not in the snapshot" test -z "$(git -C "$repo" ls-tree -r --name-only refs/shipwright/st | grep tracked.txt || true)"
    check "real index is byte-identical after snapshot" test "$ibefore" = "$(cksum < "$repo/.git/index")"

    # --- cleanup ---
    bash "$snap" -C "$repo" --cleanup >/dev/null || true
    check "cleanup empties refs/shipwright" test -z "$(git -C "$repo" for-each-ref refs/shipwright)"
    check "cleanup removes the lane worktree" test ! -e "$lane"
    check "cleanup leaves no scratch worktree registered" test "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" = 1
    check "cleanup keeps log and stash untouched" test -z "$(git -C "$repo" stash list)"
    check "cleanup is idempotent" bash "$snap" -C "$repo" --cleanup

    # --- cleanup with a space in the repo path ---
    local sp; sp="$(mkdir "$TEST_ROOT/My Projects" && cd "$TEST_ROOT/My Projects" && pwd -P)"
    git init -q -b main "$sp/r" && git -C "$sp/r" -c user.email=t@e -c user.name=t commit -q --allow-empty -m i
    bash "$snap" -C "$sp/r" x >/dev/null; bash "$snap" -C "$sp/r" --lane w >/dev/null
    bash "$snap" -C "$sp/r" --cleanup >/dev/null || true
    check "cleanup works in a repo path with spaces" test ! -e "$sp/r/.shipwright/work/lanes/w" -a -z "$(git -C "$sp/r" for-each-ref refs/shipwright)"

    echo
    if [[ "$FAILURES" -eq 0 ]]; then echo "ALL PASS"; else echo "$FAILURES FAILED"; exit 1; fi
}
main "$@"
