#!/usr/bin/env bash
# Builds the CI summary comment from a CI run's result files and posts it on
# the PR, updating the same comment on every push.
# Usage: ci-report.sh RESULT_DIR
# Env: GH_TOKEN REPO HEAD_SHA RUN_URL CONCLUSION STARTED UPDATED
#
# The result files come from an untrusted run (a fork PR can edit ci.yml), so
# nothing in them is sourced or evaluated: the PR number must be digits and
# match the run's commit, statuses are whitelisted, text is filtered and capped.
set -euo pipefail

dir=${1:-ci-result}
marker='<!-- shipwright-ci-report -->'
max_log=6000

field() { # field FILE KEY: the first KEY= value in FILE, or nothing
    { grep -m1 "^$2=" "$1" 2>/dev/null || true; } | cut -d= -f2-
}

plain() { # a short, table-safe value: letters, digits and a little punctuation
    printf '%s' "$1" | tr -cd 'A-Za-z0-9 .,:()/+-' | cut -c1-80
}

case "${HEAD_SHA:-}" in
    '' | *[!0-9a-f]*) echo "ci-report: no valid head SHA; nothing to post"; exit 0 ;;
esac

pr=$({ head -c 20 "$dir/pr.txt" 2>/dev/null || true; } | tr -d '[:space:]')
case "$pr" in
    '' | *[!0-9]*) echo "ci-report: no valid PR number in the results; nothing to post"; exit 0 ;;
esac

pr_sha=$(gh api "repos/$REPO/pulls/$pr" --jq .head.sha)
if [ "$pr_sha" != "$HEAD_SHA" ]; then
    echo "ci-report: PR #$pr is at $pr_sha but this run tested $HEAD_SHA; skipping"
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
rows="$work/rows" logs="$work/logs" body="$work/body"
: > "$rows"; : > "$logs"
failed=0 missing=0

check() { # check KEY NAME DEFAULT_RUNNER: one table row, plus output if it failed
    local f="$dir/$1.txt" status icon runner details
    status=$(field "$f" status)
    case "$status" in
        pass) icon='✅ Pass' ;;
        fail) icon='❌ Fail'; failed=$((failed + 1)) ;;
        *) icon='⚠️ No result'; missing=$((missing + 1)) ;;
    esac
    runner=$(plain "$(field "$f" runner)")
    details=$(plain "$(field "$f" details)")
    printf '| %s | %s | %s | %s |\n' "$2" "${runner:-$3}" "$icon" "${details:--}" >> "$rows"
    if [ "$status" = fail ] && [ -s "$dir/$1.log" ]; then
        {
            printf '<details><summary>%s (%s) output</summary>\n\n```text\n' "$2" "${runner:-$3}"
            # Backticks would close the fence, and control characters garble it.
            head -c "$max_log" "$dir/$1.log" | tr '`' "'" | tr -d '\000-\010\013\014\016-\037'
            printf '\n```\n\n</details>\n\n'
        } >> "$logs"
    fi
}

check tests-ubuntu Tests Ubuntu
check tests-macos Tests macOS
check shellcheck ShellCheck Ubuntu

if [ "${CONCLUSION:-}" = cancelled ]; then
    title='⚠️ Run cancelled'
elif [ "$failed" -gt 0 ]; then
    title="❌ $failed of 3 checks failed"
elif [ "$missing" -gt 0 ]; then
    title='⚠️ Some checks reported no result'
else
    title='✅ All checks passed'
fi

duration=-
if start=$(date -u -d "${STARTED:-}" +%s 2>/dev/null) && end=$(date -u -d "${UPDATED:-}" +%s 2>/dev/null); then
    s=$((end - start))
    duration="$((s / 60))m $((s % 60))s"
fi

{
    echo "$marker"
    echo "## 🚢 Shipwright CI — $title"
    echo
    echo '| Check | Runner | Result | Details |'
    echo '|---|---|---|---|'
    cat "$rows"
    echo
    cat "$logs"
    # shellcheck disable=SC2016  # the backticks are Markdown code marks, not command substitution
    printf '<sub>Commit `%s` · Run time %s · [View run](%s) · Updated %s UTC</sub>\n' \
        "${HEAD_SHA:0:7}" "$duration" "${RUN_URL:-}" "$(date -u '+%Y-%m-%d %H:%M')"
} > "$body"

# `|| true`: head closing the pipe early must not fail the step under pipefail.
existing=$({ gh api --paginate "repos/$REPO/issues/$pr/comments" \
    --jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | startswith(\"$marker\"))) | .id" || true; } | head -n 1)
if [ -n "$existing" ]; then
    gh api -X PATCH "repos/$REPO/issues/comments/$existing" -F "body=@$body" > /dev/null
    echo "ci-report: updated comment $existing on PR #$pr"
else
    gh api -X POST "repos/$REPO/issues/$pr/comments" -F "body=@$body" > /dev/null
    echo "ci-report: posted a comment on PR #$pr"
fi
