#!/usr/bin/env bash
# Tests for hooks/session-start, run through hooks/run-hook.cmd as hooks.json does.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/hooks/run-hook.cmd"
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
fails=0
check() { # name condition-rc
    if [ "$2" -eq 0 ]; then echo "  [PASS] $1"; else echo "  [FAIL] $1"; fails=$((fails+1)); fi
}
has() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
NOT_ONBOARDED="This project is not onboarded yet. Before planning work here, run the shipwright:onboarding skill."

REPO="$T/repo"; git init -q "$REPO"
run() { # stdin-json -> hook output
    printf '%s' "$1" | CLAUDE_PLUGIN_ROOT="$ROOT" "$HOOK" session-start
}

out=$(run "{\"cwd\":\"$REPO\"}"); rc=$?
check "exits 0" "$rc"
has "$out" '"hookEventName": "SessionStart"' ; check "nested SessionStart shape" $?
has "$out" '"additionalContext"' ; check "has additionalContext" $?
has "$out" 'Shipwright settings for this project:' ; check "settings line present" $?
has "$out" 'commit_push=not-allowed' ; check "default commit_push shown" $?
has "$out" "$NOT_ONBOARDED" ; check "fresh repo: not-onboarded line" $?
has "$out" '## The Rule' ; check "skill text injected" $?
has "$out" "Commit consent is off for this developer. Skip other skills' steps that commit, push, merge, stash or create or switch branches" ; check "consent off: guidance injected" $?
has "$out" "A Shipwright denial is final: do not retry it in another form." ; check "consent off: guidance ends with denial rule" $?
[ "${#out}" -lt 10000 ]
# shellcheck disable=SC2319  # check takes the condition's status on purpose
check "output under 10000 chars (${#out})" $?

bash "$ROOT/scripts/shipwright-config" -C "$REPO" set docs_mode local >/dev/null
out=$(run "{\"cwd\":\"$REPO\"}")
has "$out" 'docs_mode=local' ; check "onboarded: docs_mode shown" $?
! has "$out" "$NOT_ONBOARDED" ; check "onboarded: not-onboarded line omitted" $?

out=$(printf '' | CLAUDE_PROJECT_DIR="$REPO" CLAUDE_PLUGIN_ROOT="$ROOT" "$HOOK" session-start)
has "$out" 'docs_mode=local' ; check "falls back to CLAUDE_PROJECT_DIR" $?

out=$(run "{\"cwd\":\"$T/nowhere\"}")
has "$out" '## The Rule' ; check "bad cwd: still injects skill" $?
has "$out" 'Shipwright settings for this project: unavailable' ; check "bad cwd: settings unavailable" $?

out=$(printf '{"cwd":"%s"}' "$REPO" | env -i PATH="" CLAUDE_PLUGIN_ROOT="$ROOT" "$BASH" "$ROOT/hooks/session-start")
has "$out" 'docs_mode=local' ; check "empty PATH still works" $?

AL="$T/al"; git init -q "$AL"; bash "$ROOT/scripts/shipwright-config" -C "$AL" set commit_push allowed >/dev/null
out=$(run "{\"cwd\":\"$AL\"}")
! has "$out" "Commit consent is off" ; check "consent allowed: no guidance" $?
git -C "$AL" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i
git -C "$AL" worktree add -q --detach "$T/alwt"
out=$(run "{\"cwd\":\"$T/alwt\"}")
has "$out" 'commit_push=allowed' ; check "linked worktree reads main checkout settings" $?

if [ "$fails" -eq 0 ]; then echo "STATUS: PASSED"; else echo "STATUS: FAILED ($fails)"; exit 1; fi
