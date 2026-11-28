#!/usr/bin/env bash
# Structure checks for the ai-* skills: frontmatter, descriptions, sections, rule marks, cross-references, length.
# Usage: bash tests/skills/test-ai-skills.sh [skill-name ...]   (no names: all 17 skills plus the discovery line)
ROOT="${AI_SKILLS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
S="$ROOT/skills"
HEAD=ai-engineering
TOPICS="ai-architecture-decisions ai-llm-calls ai-tool-use ai-agents ai-context-management ai-rag ai-prompt-engineering ai-evaluation ai-testing ai-observability ai-cost-latency ai-prompt-injection ai-security-privacy ai-guardrails ai-model-lifecycle ai-ux"
# shellcheck disable=SC2016  # literal backticks in the skill text, not an expansion
HEAD_LINE='**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering`'
fails=0

result() { # skill check detail-if-failed ("" means pass)
    if [ -z "$3" ]; then echo "  [PASS] $1: $2"; else echo "  [FAIL] $1: $2: $3"; fails=$((fails+1)); fi
}
field() { sed -n "2,/^---\$/s/^$2: //p" "$1" | head -n 1; }
desc_problem() { # file prefix
    local d; d="$(field "$1" description)"
    case "$d" in "$2"*) ;; *) echo "does not start with '$2'"; return;; esac
    [ "${#d}" -le 1024 ] || echo "${#d} characters, over 1024"
}
common() { # skill file target-lines; returns 1 if the file is missing
    local skill="$1" f="$2" n missing
    if [ ! -f "$f" ]; then result "$skill" "T1 exists" "no $f"; return 1; fi
    result "$skill" "T1 exists" ""
    result "$skill" "T2 name" "$([ "$(field "$f" name)" = "$skill" ] || echo "frontmatter name is '$(field "$f" name)'")"
    missing=$(grep -o 'shipwright:ai-[a-z-]*' "$f" | sed 's/-*$//' | sort -u | while IFS= read -r ref; do
        [ -f "$S/${ref#shipwright:}/SKILL.md" ] || printf ' %s' "${ref#shipwright:}"
    done)
    result "$skill" "T7 references resolve" "${missing:+no skill for:$missing}"
    n=$(wc -l < "$f"); n=$((n))
    result "$skill" "T8 length" "$([ "$n" -le 300 ] || echo "$n lines, over 300")"
    [ "$n" -le "$3" ] || echo "  [NOTE] $skill: $n lines, over the $3-line target"
    return 0
}
check_topic() { # skill
    local skill="$1" f="$S/$1/SKILL.md" order bad
    common "$skill" "$f" 200 || return
    result "$skill" "T3 description" "$(desc_problem "$f" 'Use in a project that calls LLMs, when')"
    result "$skill" "T4 head skill line" "$(grep -qF "$HEAD_LINE" "$f" || echo "missing: $HEAD_LINE")"
    order=$(grep -x -E '## (Rules|Ask the developer|Checks|Related skills)' "$f" | tr '\n' '|')
    result "$skill" "T5 sections" "$([ "$order" = '## Rules|## Ask the developer|## Checks|## Related skills|' ] || echo "found '$order'")"
    bad=$(awk '/^## Rules$/ {r=1; next} /^## / {r=0} r && /^- / {
            l=$0; c=gsub(/\[(security|reliability|practice)\]/, "", l); if (c != 1) print NR": "$0 }' "$f")
    result "$skill" "T6 rule marks" "${bad:+lines without exactly one mark: $bad}"
}
check_head() {
    local f="$S/$HEAD/SKILL.md" t missing="" m nomark=""
    common "$HEAD" "$f" 150 || return
    result "$HEAD" "H3 description" "$(desc_problem "$f" 'Use in a project that calls LLMs')"
    for t in $TOPICS; do grep -qE "shipwright:$t([^a-z-]|\$)" "$f" || missing="$missing $t"; done
    result "$HEAD" "H4 names every topic" "${missing:+not named:$missing}"
    for m in '[security]' '[reliability]' '[practice]'; do grep -qF "$m" "$f" || nomark="$nomark $m"; done
    result "$HEAD" "H5 rule marks" "${nomark:+not defined:$nomark}"
}

if [ $# -eq 0 ]; then
    # shellcheck disable=SC2086  # split TOPICS into one argument per skill
    set -- "$HEAD" $TOPICS
    result using-shipwright "D1 discovery line" "$(grep -qF 'shipwright:ai-engineering' "$S/using-shipwright/SKILL.md" 2>/dev/null || echo "no shipwright:ai-engineering line")"
fi
for skill in "$@"; do
    if [ "$skill" = "$HEAD" ]; then check_head; else check_topic "$skill"; fi
done
exit $((fails > 0))
