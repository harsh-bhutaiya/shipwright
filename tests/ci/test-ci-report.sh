#!/usr/bin/env bash
# Tests for .github/scripts/ci-report.sh, with a fake gh. The result files are
# what a fork PR controls, so most cases feed it hostile input.
REPORT="$(cd "$(dirname "$0")/../.." && pwd)/.github/scripts/ci-report.sh"
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
fails=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "  [PASS] $1"; else echo "  [FAIL] $1: expected '$2' got '$3'"; fails=$((fails+1)); fi
}

SHA=0123456789abcdef0123456789abcdef01234567
mkdir -p "$T/bin"
cat > "$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Fake gh: answers the three calls ci-report.sh makes and records writes.
echo "$*" >> "$GH_LOG"
case "$*" in
    *"/pulls/"*) echo "$MOCK_PR_SHA" ;;
    *"--paginate"*) [ -n "${MOCK_EXISTING:-}" ] && echo "$MOCK_EXISTING" ;;
    *"-X POST"* | *"-X PATCH"*)
        for a in "$@"; do case "$a" in body=@*) cp "${a#body=@}" "$GH_BODY" ;; esac; done ;;
esac
exit 0
EOF
chmod +x "$T/bin/gh"

results() { # results DIR PR: three passing result files
    mkdir -p "$1"; echo "$2" > "$1/pr.txt"
    printf 'check=Tests\nrunner=Ubuntu, bash 5.2\nstatus=pass\ndetails=7/7 test files pass\n' > "$1/tests-ubuntu.txt"
    printf 'check=Tests\nrunner=macOS, bash 3.2\nstatus=pass\ndetails=7/7 test files pass\n' > "$1/tests-macos.txt"
    printf 'check=ShellCheck v0.10.0\nrunner=Ubuntu\nstatus=pass\ndetails=0 findings in 30 files\n' > "$1/shellcheck.txt"
}
run() { # run DIR [extra env...]: runs the report, logs to $T/out
    : > "$T/gh.log"; rm -f "$T/body"
    env PATH="$T/bin:$PATH" GH_LOG="$T/gh.log" GH_BODY="$T/body" GH_TOKEN=x REPO=o/r \
        HEAD_SHA="$SHA" MOCK_PR_SHA="$SHA" RUN_URL=https://example.com/run CONCLUSION=success \
        STARTED=2026-11-25T10:00:00Z UPDATED=2026-11-25T10:01:42Z "${@:2}" \
        bash "$REPORT" "$1" > "$T/out" 2>&1
}
writes() { grep -c -E -- '-X (POST|PATCH)' "$T/gh.log"; }

# All checks pass: one new comment with the marker and three passing rows.
results "$T/ok" 12; run "$T/ok"
check "pass: exits 0" "0" "$?"
check "pass: posts once" "1" "$(grep -c -- '-X POST' "$T/gh.log")"
check "pass: marker on first line" "<!-- shipwright-ci-report -->" "$(head -n 1 "$T/body")"
check "pass: title" "1" "$(grep -c 'Shipwright CI — ✅ All checks passed' "$T/body")"
check "pass: three passing rows" "3" "$(grep -c '| ✅ Pass |' "$T/body")"

# An existing report comment is updated, not duplicated.
run "$T/ok" MOCK_EXISTING=42
check "update: patches comment 42" "1" "$(grep -c -- '-X PATCH repos/o/r/issues/comments/42' "$T/gh.log")"
check "update: no new comment" "0" "$(grep -c -- '-X POST' "$T/gh.log")"

# A PR number that is not digits stops before any API call.
results "$T/badpr" '1;rm -rf x'; run "$T/badpr"
check "bad PR number: exits 0" "0" "$?"
check "bad PR number: no gh calls" "0" "$(grep -c . "$T/gh.log")"

# A run whose commit is not the PR's head (stale or forged) posts nothing.
run "$T/ok" MOCK_PR_SHA=ffffffffffffffffffffffffffffffffffffffff
check "SHA mismatch: no write" "0" "$(writes)"
run "$T/ok" HEAD_SHA='abc;id'
check "bad head SHA: no gh calls" "0" "$(grep -c . "$T/gh.log")"

# Hostile values: no command runs, no extra columns, no mentions or fences.
results "$T/evil" 12
# shellcheck disable=SC2016  # the $(...) must reach the file unexpanded
printf 'status=$(touch %s/pwned)\nrunner=x | y @someone `code`\ndetails=a|b|c @org/team <b>x</b>\n' "$T" > "$T/evil/tests-ubuntu.txt"
run "$T/evil"
check "hostile: nothing executed" "no" "$([ -e "$T/pwned" ] && echo yes || echo no)"
check "hostile: unknown status is No result" "1" "$(grep -c '⚠️ No result' "$T/body")"
check "hostile: no @ mention" "0" "$(grep -c '@' "$T/body")"
check "hostile: every row has 4 columns" "" "$(grep '^| ' "$T/body" | awk -F'|' 'NF != 6')"
check "hostile: no HTML from values" "0" "$(grep -c '<b>' "$T/body")"

# A failing check shows its output in one fenced block the log cannot break out of.
results "$T/fail" 12
printf 'check=Tests\nrunner=macOS, bash 3.2\nstatus=fail\ndetails=1 of 7 test files failed\n' > "$T/fail/tests-macos.txt"
printf 'FAIL tests/x.sh\n```\n</details>\n@someone \001bell\n' > "$T/fail/tests-macos.log"
run "$T/fail"
check "fail: title counts failures" "1" "$(grep -c '❌ 1 of 3 checks failed' "$T/body")"
check "fail: output block present" "1" "$(grep -c '^<details><summary>Tests (macOS, bash 3.2) output</summary>' "$T/body")"
check "fail: only the two fence lines" "2" "$(grep -c '^```' "$T/body")"
check "fail: control characters stripped" "0" "$(LC_ALL=C grep -c "$(printf '\001')" "$T/body")"
check "fail: log text kept" "1" "$(grep -c '^FAIL tests/x.sh$' "$T/body")"

# A cancelled run says so.
run "$T/ok" CONCLUSION=cancelled
check "cancelled: title" "1" "$(grep -c '⚠️ Run cancelled' "$T/body")"

# No results at all (every job died before uploading): nothing to post.
run "$T/none"
check "no results: exits 0" "0" "$?"
check "no results: no gh calls" "0" "$(grep -c . "$T/gh.log")"

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
