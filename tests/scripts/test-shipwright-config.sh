#!/usr/bin/env bash
# Tests for scripts/shipwright-config
CFG="$(cd "$(dirname "$0")/../.." && pwd)/scripts/shipwright-config"
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
fails=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "  [PASS] $1"; else echo "  [FAIL] $1: expected '$2' got '$3'"; fails=$((fails+1)); fi
}
repo() { local d="$T/$1"; mkdir -p "$d"; git init -q "$d"; echo "$d"; }

R=$(repo a)
check "default commit_push" "not-allowed" "$("$CFG" -C "$R" get commit_push)"
check "default docs_dir" "docs" "$("$CFG" -C "$R" get docs_dir)"
"$CFG" -C "$R" set plan_approval auto
check "set/get plan_approval" "auto" "$("$CFG" -C "$R" get plan_approval)"
"$CFG" -C "$R" set plan_approval review
check "set rewrites, no dupes" "1" "$(grep -c '^plan_approval=' "$R/.shipwright/project.conf")"
"$CFG" -C "$R" set plan_approval maybe 2>/dev/null; check "bad value exit 2" "2" "$?"
"$CFG" -C "$R" get nope 2>/dev/null; check "unknown key exit 2" "2" "$?"
"$CFG" -C "$R" set pr_line_cap abc 2>/dev/null; check "non-integer cap exit 2" "2" "$?"

printf 'commit_push = allowed\r\nai_coauthor=no\r\n' > "$R/.shipwright/developer.conf"
check "CRLF and spaces" "allowed" "$("$CFG" -C "$R" get commit_push)"
check "CRLF second key" "no" "$("$CFG" -C "$R" get ai_coauthor)"
printf 'commit_push=not-allowed\ncommit_push=allowed\n' > "$R/.shipwright/developer.conf"
check "last wins" "allowed" "$("$CFG" -C "$R" get commit_push)"

"$CFG" -C "$R" exclude; "$CFG" -C "$R" exclude
X="$R/.git/info/exclude"
check "exclude developer once" "1" "$(grep -cxF '/.shipwright/developer.conf' "$X")"
check "exclude work once" "1" "$(grep -cxF '/.shipwright/work/' "$X")"
check "exclude project (not onboarded)" "1" "$(grep -cxF '/.shipwright/project.conf' "$X")"

R2=$(repo b); "$CFG" -C "$R2" set docs_mode in-repo; "$CFG" -C "$R2" exclude
check "in-repo: no project.conf line" "0" "$(grep -cxF '/.shipwright/project.conf' "$R2/.git/info/exclude")"
R3=$(repo c); "$CFG" -C "$R3" set docs_mode local; "$CFG" -C "$R3" set docs_dir notes; "$CFG" -C "$R3" exclude
check "local: docs dir excluded" "1" "$(grep -cxF '/notes/' "$R3/.git/info/exclude")"

mkdir "$T/plain"
check "path work outside git" "$T/plain/.shipwright/work" "$("$CFG" -C "$T/plain" path work)"
"$CFG" -C "$T/plain" exclude; check "exclude outside git is no-op" "0" "$?"
check "path project" "$R/.shipwright/project.conf" "$("$CFG" -C "$R" path project)"

check "summary" "docs_mode=; docs_dir=docs; wiki_connector=; wiki_location=; plan_approval=review; pr_line_cap=; observability=; commit_push=allowed; ai_coauthor=ask" "$("$CFG" -C "$R" summary)"

# worktree: exclude must land in the common dir
R4=$(repo d); git -C "$R4" -c user.name=t -c user.email=t@t commit -q --allow-empty -m i
git -C "$R4" worktree add -q --detach "$T/wt" 2>/dev/null
"$CFG" -C "$T/wt" exclude
git -C "$T/wt" check-ignore -q .shipwright/developer.conf; check "worktree: developer.conf ignored" "0" "$?"
git -C "$T/wt" check-ignore -q .shipwright/work/x; check "worktree: work ignored" "0" "$?"

# exclude file without trailing newline
R5=$(repo e); mkdir -p "$R5/.git/info"; printf "foo\nbar" > "$R5/.git/info/exclude"
"$CFG" -C "$R5" exclude; X5="$R5/.git/info/exclude"
check "no-newline: foo kept" "1" "$(grep -cxF foo "$X5")"
check "no-newline: bar kept" "1" "$(grep -cxF bar "$X5")"
check "no-newline: work intact" "1" "$(grep -cxF "/.shipwright/work/" "$X5")"
check "no-newline: developer intact" "1" "$(grep -cxF "/.shipwright/developer.conf" "$X5")"

# failed write must not touch the original conf; preserved "-n" line survives
R6=$(repo f); "$CFG" -C "$R6" set plan_approval auto; printf -- "-n\n" >> "$R6/.shipwright/project.conf"
"$CFG" -C "$R6" set docs_dir x; check "dash-n line preserved" "1" "$(grep -cxF -- -n "$R6/.shipwright/project.conf")"
cp "$R6/.shipwright/project.conf" "$T/before"; chmod a-w "$R6/.shipwright"
"$CFG" -C "$R6" set plan_approval review 2>/dev/null; rc=$?
chmod u+w "$R6/.shipwright"
check "unwritable dir: set non-zero" "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)"
cmp -s "$T/before" "$R6/.shipwright/project.conf"; check "unwritable dir: conf unchanged" "0" "$?"


# linked worktree reads the main checkout's settings
RW=$(repo w); git -C "$RW" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i
git -C "$RW" worktree add -q --detach "$T/wtmain"
mkdir -p "$RW/.shipwright"; printf 'commit_push=allowed\n' > "$RW/.shipwright/developer.conf"; printf 'plan_approval=auto\n' > "$RW/.shipwright/project.conf"
check "worktree: get" "allowed" "$("$CFG" -C "$T/wtmain" get commit_push)"
check "worktree: summary" "1" "$("$CFG" -C "$T/wtmain" summary | grep -c 'commit_push=allowed')"
check "worktree: path developer" "$RW/.shipwright/developer.conf" "$("$CFG" -C "$T/wtmain" path developer)"

# local-mode exclude skips a docs_dir with tracked files
RT=$(repo t); "$CFG" -C "$RT" set docs_mode local; mkdir "$RT/docs"; echo x > "$RT/docs/a.md"
git -C "$RT" add docs/a.md
err=$("$CFG" -C "$RT" exclude 2>&1 >/dev/null)
check "tracked docs: not excluded" "0" "$(grep -cxF '/docs/' "$RT/.git/info/exclude")"
check "tracked docs: stderr" "shipwright-config: not excluding docs/ because it has tracked files; Shipwright's docs will be visible to git there" "$err"
RU=$(repo u); "$CFG" -C "$RU" set docs_mode local; mkdir "$RU/docs"; echo x > "$RU/docs/a.md"
"$CFG" -C "$RU" exclude
check "untracked docs: excluded" "1" "$(grep -cxF '/docs/' "$RU/.git/info/exclude")"
for bad in . /abs; do
    RV=$(repo v); "$CFG" -C "$RV" set docs_mode local; "$CFG" -C "$RV" set docs_dir "$bad"; "$CFG" -C "$RV" exclude
    check "docs_dir '$bad': no docs line" "0" "$(grep -c 'docs\|^/\./\|^//' "$RV/.git/info/exclude")"
    check "docs_dir '$bad': no root-wide line" "0" "$(grep -cxF -e '/' -e '/./' "$RV/.git/info/exclude")"
    rm -rf "$RV"
done

# shared-tool keeps the local master docs out of git too, with the same tracked-files guard
RS=$(repo s); "$CFG" -C "$RS" set docs_mode shared-tool; mkdir "$RS/docs"; echo x > "$RS/docs/a.md"
"$CFG" -C "$RS" exclude
check "shared-tool: untracked docs excluded" "1" "$(grep -cxF '/docs/' "$RS/.git/info/exclude")"
RST=$(repo st); "$CFG" -C "$RST" set docs_mode shared-tool; mkdir "$RST/docs"; echo x > "$RST/docs/a.md"
git -C "$RST" add docs/a.md
err=$("$CFG" -C "$RST" exclude 2>&1 >/dev/null)
check "shared-tool: tracked docs not excluded" "0" "$(grep -cxF '/docs/' "$RST/.git/info/exclude")"
check "shared-tool: tracked docs stderr" "shipwright-config: not excluding docs/ because it has tracked files; Shipwright's docs will be visible to git there" "$err"

# exclude drops its own lines that the current mode no longer needs, and only its own
RM=$(repo m); X="$RM/.git/info/exclude"; mkdir -p "$RM/.git/info"; printf '/mine/\n' >> "$X"
"$CFG" -C "$RM" set docs_mode shared-tool; "$CFG" -C "$RM" exclude
printf '/build/\n/.shipwright/work/\n' >> "$X"
"$CFG" -C "$RM" set docs_mode in-repo; "$CFG" -C "$RM" exclude
git -C "$RM" check-ignore -q docs/specs/x.md; check "shared-tool -> in-repo: docs no longer ignored" "1" "$?"
git -C "$RM" check-ignore -q .shipwright/project.conf; check "shared-tool -> in-repo: project.conf no longer ignored" "1" "$?"
check "mode switch: developer lines kept" "/mine/ /build/" "$(grep -xF -e /mine/ -e /build/ "$X" | tr '\n' ' ' | sed 's/ $//')"
check "mode switch: developer's copy of a Shipwright line kept" "2" "$(grep -cxF '/.shipwright/work/' "$X")"
git -C "$RM" check-ignore -q .shipwright/developer.conf; check "mode switch: developer.conf still ignored" "0" "$?"
"$CFG" -C "$RM" set docs_mode local; "$CFG" -C "$RM" set docs_dir notes; "$CFG" -C "$RM" exclude
"$CFG" -C "$RM" set docs_dir notes2; "$CFG" -C "$RM" exclude
check "docs_dir change: old docs line dropped" "0" "$(grep -cxF '/notes/' "$X")"
check "docs_dir change: new docs line added" "1" "$(grep -cxF '/notes2/' "$X")"

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
