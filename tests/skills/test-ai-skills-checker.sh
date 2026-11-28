#!/usr/bin/env bash
# Tests for tests/skills/test-ai-skills.sh, run against fixture skills.
CHK="$(cd "$(dirname "$0")" && pwd)/test-ai-skills.sh"
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
fails=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "  [PASS] $1"; else echo "  [FAIL] $1: expected '$2' got '$3'"; fails=$((fails+1)); fi
}
TOPICS="ai-architecture-decisions ai-llm-calls ai-tool-use ai-agents ai-context-management ai-rag ai-prompt-engineering ai-evaluation ai-testing ai-observability ai-cost-latency ai-prompt-injection ai-security-privacy ai-guardrails ai-model-lifecycle ai-ux"

topic_md() { # name [variant]
    local desc="Use in a project that calls LLMs, when adding or reviewing a model call."
    case "$2" in
        baddesc) desc="Use when adding a model call." ;;
        longdesc) desc="Use in a project that calls LLMs, when $(printf 'x%.0s' $(seq 1 1000))" ;;
    esac
    local name="$1"; [ "$2" = badname ] && name="ai-other"
    printf -- '---\nname: %s\ndescription: %s\n---\n\n# Title\n\nWhat it covers.\n\n' "$name" "$desc"
    # shellcheck disable=SC2016  # literal backticks in the fixture text
    [ "$2" = nohead ] || printf -- '**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already\nloaded.\n\n'
    if [ "$2" = order ]; then printf -- '## Checks\n- Is it checked?\n\n'; fi
    printf -- '## Rules\n- [reliability] Set a timeout.\n  - a nested line needs no mark\n- [practice] Keep prompts in files.\n'
    case "$2" in
        unmarked) printf -- '- A rule with no mark.\n' ;;
        twomarks) printf -- '- [security] [practice] A rule with two marks.\n' ;;
    esac
    printf -- '\n## Ask the developer\n- Which provider?\n\n'
    [ "$2" = order ] || printf -- '## Checks\n- Is there a timeout?\n\n'
    printf -- '## Related skills\n- shipwright:ai-engineering\n'
    [ "$2" = badref ] && printf -- '- shipwright:ai-rags\n'
    [ "$2" = long ] && seq 1 300
    return 0
}
head_md() { # [variant]
    printf -- '---\nname: ai-engineering\ndescription: Use in a project that calls LLMs, before designing or reviewing code that calls a model.\n---\n\n# AI engineering\n\nMarks: [security], [reliability], [practice].\n\n'
    for t in $TOPICS; do
        [ "$1" = headmissing ] && [ "$t" = ai-ux ] && continue
        printf -- '- shipwright:%s\n' "$t"
    done
}
make_root() { # dir [skill variant]  (variant applies to that one skill)
    local d="$1" t
    mkdir -p "$d/skills/ai-engineering" "$d/skills/using-shipwright"
    if [ "$2" = ai-engineering ]; then head_md "$3"; else head_md; fi > "$d/skills/ai-engineering/SKILL.md"
    for t in $TOPICS; do
        mkdir -p "$d/skills/$t"
        if [ "$2" = "$t" ]; then topic_md "$t" "$3"; else topic_md "$t"; fi > "$d/skills/$t/SKILL.md"
    done
    # shellcheck disable=SC2016  # literal backticks in the fixture text
    if [ "$2" = nodisco ]; then printf -- '# using\n'; else printf -- '# using\n- `shipwright:ai-engineering` names the skills.\n'; fi \
        > "$d/skills/using-shipwright/SKILL.md"
}
run() { # root [skill...] -> exit code
    local r="$1"; shift
    AI_SKILLS_ROOT="$r" bash "$CHK" "$@" >/dev/null 2>&1; echo $?
}

make_root "$T/good"
check "good topic passes"        0 "$(run "$T/good" ai-llm-calls)"
check "good head passes"         0 "$(run "$T/good" ai-engineering)"
check "good full run passes"     0 "$(run "$T/good")"
for v in unmarked twomarks badref baddesc longdesc nohead order long badname; do
    make_root "$T/$v" ai-llm-calls "$v"
    check "$v fails"             1 "$(run "$T/$v" ai-llm-calls)"
done
make_root "$T/headmissing" ai-engineering headmissing
check "head missing a topic"     1 "$(run "$T/headmissing" ai-engineering)"
make_root "$T/nodisco" nodisco
check "no discovery line fails"  1 "$(run "$T/nodisco")"
rm -rf "$T/good/skills/ai-ux"
check "missing topic fails"      1 "$(run "$T/good")"

exit $((fails > 0))
