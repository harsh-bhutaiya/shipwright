#!/usr/bin/env bash
# Tests for hooks/guard-git, run through hooks/run-hook.cmd as hooks.json does.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/hooks/run-hook.cmd"
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
fails=0
decision() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"; }
CONSENT=$(decision "Shipwright: .shipwright/developer.conf holds the developer's own consent and can only be changed by the developer.")
SELF=$(decision "Shipwright: the plugin's own files cannot be changed from inside a session.")

REPO="$T/repo"; git init -q "$REPO"
OK="$T/allowed repo"; git init -q "$OK"; bash "$ROOT/scripts/shipwright-config" -C "$OK" set commit_push allowed
PLAIN="$T/plain"; mkdir "$PLAIN"
mkdir "$REPO/sub"
deny_for() { # repo root -> the commit/push deny decision
    decision "Shipwright blocked this git command: it changes the developer's visible git state (staging, commits, pushes, branches, HEAD, .git), and commit consent is off. Do not retry it in another form. Leave changes in the working tree and hand over the files to stage and a commit message instead. Only the developer can allow it, by running this in their own terminal (outside Claude Code): \\\"$ROOT/scripts/shipwright-config\\\" -C \\\"$1\\\" set commit_push allowed"
}
DENY=$(deny_for "$REPO")

result() { # name expected-output actual-output rc
    if [ "$4" -eq 0 ] && [ "$2" = "$3" ]; then echo "  [PASS] ${1//$'\n'/\\n}"
    else echo "  [FAIL] $1: rc=$4 out='$3'"; fails=$((fails+1)); fi
}
esc() { local s=${1//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; printf '%s' "${s//$'\n'/\\n}"; }
raw() { # name expected stdin
    local out rc; out=$(printf '%s' "$3" | "$HOOK" guard-git); rc=$?
    result "$1" "$2" "$out" "$rc"
}
t() { # deny|consent|allow command [cwd [repo root]]
    local cwd=${3:-$REPO} want=
    case $1 in deny) want=$(deny_for "${4:-$cwd}");; consent) want=$CONSENT;; esac
    raw "$1: $2" "$want" "{\"session_id\":\"s\",\"cwd\":\"$(esc "$cwd")\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$(esc "$2")\",\"description\":\"d\"}}"
}
ft() { # deny|self|allow tool path-key path [cwd]: a file-editing tool call
    local want=; case $1 in deny) want=$CONSENT;; self) want=$SELF;; esac
    raw "$1: $2 $4" "$want" "{\"session_id\":\"s\",\"cwd\":\"$(esc "${5:-$REPO}")\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"$2\",\"tool_input\":{\"$3\":\"$(esc "$4")\",\"content\":\"commit_push=allowed\\n\"}}"
}

echo "guard-git: brief cases"
t deny  'git commit -m x'
t deny  'cd sub && git commit -m x'
t deny  'bash -c "git commit -m x"'
t deny  'git -C ../repo push origin main'
t deny  'FOO=1 git push'
t deny  'git add .'
t deny  'git checkout -b feat/x'
t allow 'git branch'
t allow 'git status && git diff'
t allow 'GIT_INDEX_FILE=/tmp/i git update-index --add --remove f' # brief row; R11 needs --add --remove
t deny  'git update-index --add f'
t allow 'git update-ref refs/shipwright/t1 abc'
t allow 'git worktree add --detach ../w HEAD'
t allow 'ls -la'
t allow 'git commit -m x' "$OK"
t allow 'git check-ignore -q .claude/settings.local.json'
git -C "$OK" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i; git -C "$OK" worktree add -q --detach "$T/okwt"
t allow 'git commit -m x' "$T/okwt"
t deny  'git commit -m x' "$PLAIN"
raw "empty stdin: no output" "" ""

echo "guard-git: controller cases"
t deny  'git -c user.name=x commit -m y'
t deny  '(git commit -m x)'
t deny  'git commit -am x'
t deny  'echo hi; git push'
t allow 'git log --oneline | head'
t allow 'grep -rn "commit" .'
# Known false positive: the whole-string check fails safe on quoted prose.
t deny  'echo "git commit later"'
# Only the whole-string check sees a git call behind an unknown wrapper.
t deny  'timeout 60 git push'

echo "guard-git: rest of the deny table"
for c in 'git tag v1' 'git merge main' 'git rebase main' 'git cherry-pick abc' 'git revert abc' \
         'git reset --hard' 'git checkout -B x' 'git switch -c x' 'git switch -C x' 'git switch --create x' \
         'git branch feat/x' 'git branch -d x' 'git branch -D x' 'git branch -m a b' \
         'git worktree add -b x ../w' 'git worktree add -B x ../w' 'git stash' 'git stash list' \
         'git read-tree HEAD'; do
    t deny "$c"
done

echo "guard-git: rest of the allow table"
for c in 'git status' 'git diff HEAD' 'git log -3' 'git show HEAD' 'git rev-parse HEAD' 'git ls-files' \
         'git blame f' 'git branch -a' 'git branch --list' 'git branch -vv' 'git commit-tree abc -p HEAD -m x' \
         'git write-tree' 'GIT_INDEX_FILE=/tmp/i git read-tree HEAD' 'git worktree remove ../w' \
         'git worktree list' 'git apply p.diff' 'git --no-pager log'; do
    t allow "$c"
done

echo "guard-git: parsing and extra cases"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git pull' 'git am p.mbox' 'git rm f' 'git mv a b' 'git update-ref refs/heads/main abc' \
         'git worktree add ../w' $'git status\ngit tag v1' 'echo `git tag v1`' 'echo $(git tag v1)' \
         'if true; then git checkout -b x; fi' '/usr/bin/git push' 'git  push' 'sh -c '"'"'git tag v1'"'"''; do
    t deny "$c"
done
t allow 'git update-ref -d refs/shipwright/t1'
t allow 'git log --grep="fix commit"'
t deny  'git --no-pager tag v1'
raw "non-JSON stdin: no output" "" "hello"
raw "no command key: no output" "" '{"tool_input":{}}'
raw "spaced JSON: deny" "$DENY" "{ \"cwd\" : \"$REPO\", \"tool_input\" : { \"command\" : \"git push\" } }"
raw "\"command\" as an earlier value is skipped" "$DENY" \
    "{\"cwd\":\"$REPO\",\"tool_input\":{\"description\":\"command\",\"command\":\"git push\"}}"
t deny  'echo a\\; git tag v1'
t deny  'echo a\\\"; git tag v1'
# The text after an escaped backslash is literal: "\n" here is not a newline.
t allow 'echo a\ngit tag v1'
raw "escaped backslash ends the value, later keys unread" "" \
    "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"echo a\\\\\",\"description\":\"git tag v1\"}}"
raw "tab escape separates words" "$DENY" "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"git\\ttag v1\"}}"
raw "unicode escape does not derail parsing" "$DENY" "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"echo \\u001b; git tag v1\"}}"

echo "guard-git: consent stays with the developer (R1)"
t consent 'scripts/shipwright-config set commit_push allowed'
t consent '"/opt/sw/scripts/shipwright-config" -C .  set   commit_push allowed'
t consent 'bash ../sw/scripts/shipwright-config set "commit_push" not-allowed'
t allow 'scripts/shipwright-config set plan_approval auto'
t allow 'scripts/shipwright-config get commit_push'
t consent 'scripts/shipwright-config set commit_push not-allowed' "$OK"
ft deny  Write file_path "$REPO/.shipwright/developer.conf"
ft deny  Write file_path "$OK/.shipwright/developer.conf" "$OK"
ft deny  Edit file_path "$REPO/.shipwright/developer.conf"
ft deny  MultiEdit file_path "$REPO/.shipwright/developer.conf"
ft deny  NotebookEdit notebook_path "$REPO/.shipwright/developer.conf"
ft deny  Write file_path 'C:\repo\.shipwright\developer.conf'
ft allow Write file_path "$REPO/.shipwright/project.conf"
ft allow Edit file_path "$REPO/src/main.c"

echo "guard-git: visible branch state (R2)"
for c in 'git checkout main' 'git switch dev' 'git restore file.txt' 'git checkout -- f' 'git restore --staged f'; do
    t deny "$c"
done

echo "guard-git: Bash never names the consent file (R4)"
t consent 'echo commit_push=allowed > .shipwright/developer.conf'
# Known false positive, fails safe: reads go through shipwright-config get or the Read tool.
t consent 'cat .shipwright/developer.conf'
t consent 'cat .shipwright/DEVELOPER.CONF'
t consent 'printf "commit_push=allowed\n" >> .shipwright/developer.conf' "$OK"

echo "guard-git: consent file under any spelling (R5)"
ft deny  Write file_path "$REPO/.shipwright/./developer.conf"
ft deny  Write file_path "$REPO/.Shipwright/Developer.conf"
ft deny  Write file_path /tmp/x/developer.conf
ft deny  Write file_path "$REPO/notes/developer.conf"
ft deny  Write file_path developer.conf
ft allow Write file_path "$REPO/docs/developer-guide.md"

echo "guard-git: the deny names both resolved paths (R6)"
t deny 'git push' "$REPO/sub" "$REPO"
t deny 'git push' "$PLAIN"

echo "guard-git: quoted options and continuations (review I1)"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git -C "/tmp/r" commit -m x' 'git -c user.name="Claude Bot" commit -m x' \
         'git --git-dir="$d/.git" --work-tree="$d" add -A' 'git -C "$PWD" checkout main' \
         'git -C "$d" reset --hard' 'git -C "$d" stash' 'git -C "$d" tag v1' \
         "git -C '/tmp/my repo' push origin main" "git -C '/tmp/my repo' reset --hard" \
         $'git -C /tmp/x \\\ncommit -m x' $'git \\\nreset --hard' $'git --no-pager \\\npush' \
         'git -C $(pwd) commit -m x' 'git -C a\ b commit -m x' 'git -C "$d" branch new' \
         'git -C "$d" worktree add ../w' '"git" commit -m x' "'git' push"; do
    t deny "$c"
done

echo "guard-git: wrappers with options (review I2)"
for c in 'timeout 60 git pull' 'timeout 60 git reset --hard' 'nice git rebase main' 'time -p git stash' \
         'env -i git tag v1' 'sudo -u me git reset --hard' 'command -p git checkout main' \
         '>/dev/null git reset --hard' '2>&1 git stash' 'eval git reset --hard' 'xargs git tag v1' \
         'timeout 5 git branch new' 'nice -n 5 git worktree add ../w' 'xargs -n1 git branch -D'; do
    t deny "$c"
done
t allow 'which git'
t allow 'brew upgrade git && git status'

echo "guard-git: consent path without the file name (review I3, R8)"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
t consent 'printf "commit_push=allowed\n" > "$(scripts/shipwright-config path developer)"'
t consent $'scripts/shipwright-config \\\n set commit_push allowed'
t consent 'scripts/shipwright-config -C ../B set commit_push allowed' "$OK"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
t consent 'cat "$(scripts/shipwright-config path developer)"' "$OK"
t consent 'cat .shipwright/develop""er.conf'
t consent 'scripts/shipwright-config "set" "commit_push" allowed'
t allow 'scripts/shipwright-config path work'
t allow 'scripts/shipwright-config path project'

echo "guard-git: staging, destructive and ref plumbing (R7)"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git apply --cached p.diff' 'git apply --index p.diff' 'git apply -3 p.diff' 'git clean -fd' 'git clean -n' \
         'git fetch origin main:main' "git fetch origin '+refs/heads/*:refs/heads/*'" \
         'git symbolic-ref HEAD refs/heads/x' 'git symbolic-ref --short HEAD' \
         'GIT_INDEX_FILE=.git/index git update-index --add f' 'GIT_INDEX_FILE=$(git rev-parse --git-dir)/index git read-tree HEAD' \
         'GIT_INDEX_FILE=/r/.git/worktrees/w/index git read-tree HEAD' 'GIT_INDEX_FILE= git read-tree HEAD'; do
    t deny "$c"
done
t allow 'git fetch origin'
t allow 'GIT_INDEX_FILE=/tmp/tmp.Ab12Cd git read-tree HEAD'
t allow 'git commit -m x' "$OK"
# Allowed before round 2, denied by the R11 allowlist:
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git fetch git@github.com:a/b.git' 'git fetch https://example.com/a/b main' \
         'GIT_INDEX_FILE="$t" git update-index --add f' 'git apply --check p.diff'; do
    t deny "$c"
done

echo "guard-git: the plugin's own files (R9)"
FP="$T/fake plugin"; mkdir -p "$FP/hooks" "$FP/scripts"
cp "$ROOT/hooks/run-hook.cmd" "$ROOT/hooks/guard-git" "$FP/hooks/"; cp "$ROOT/scripts/shipwright-config" "$FP/scripts/"
HOOK="$FP/hooks/run-hook.cmd"
ft self  Write file_path "$FP/hooks/guard-git"
ft self  Edit file_path "$FP/scripts/shipwright-config"
ft self  NotebookEdit notebook_path "$FP/docs/n.ipynb"
ft allow Edit file_path "$ROOT/hooks/guard-git"
ft allow Write file_path "$T/fake plugin2/x"
ft deny  Write file_path "$FP/.shipwright/developer.conf"
# Reached through a symlink: both the link spelling and the real path are the plugin.
ln -s "$FP" "$T/link plugin"; HOOK="$T/link plugin/hooks/run-hook.cmd"
ft self  Write file_path "$T/link plugin/hooks/guard-git"
ft self  Write file_path "$FP/hooks/guard-git"
HOOK="$ROOT/hooks/run-hook.cmd"

echo "guard-git: control characters in paths (R10)"
TABR="$T/tab"$'\t'"repo"; git init -q "$TABR"
t deny 'git push' "$TABR" '<repo root>'

echo "guard-git: review round 2 probes"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git update-ref -m "a refs/shipwright/x" refs/heads/main HEAD~1' 'git worktree add "../a -d b/w"' \
         $'echo git \\\\\ngit branch new' 'GIT_WORK_TREE=/srv/git git branch new' \
         'GIT_WORK_TREE=/srv/git git worktree add -b x ../w' 'GIT_WORK_TREE=/srv/git git update-ref refs/heads/main HEAD~1' \
         'git apply --cach p' 'git apply --ind p' 'git apply --3w p' 'git apply -v3 p' 'git apply -N p' \
         'git apply --intent-to-add p' 'git 2>&1 commit -m x' 'git >/dev/null push' \
         'git --attr-source HEAD commit -m x' 'git -C $(dirname $(pwd)) commit -m x'; do
    t deny "$c"
done
# A long backslash run before a quote (finding 6) stays fast; it was quadratic.
# Built already JSON-escaped (40000 backslashes are 80000 here): esc's ${//} is quadratic too.
# shellcheck disable=SC1003  # tr reads '\\' as one backslash
bs=$(printf '%80000s' '' | tr ' ' '\\'); s=$SECONDS
raw "deny: echo + 40000 backslashes + \"; git push" "$DENY" "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"echo $bs\\\"; git push\"}}"
if [ $((SECONDS - s)) -le 2 ]; then echo "  [PASS] 40 KB backslash run within 2 s"; else echo "  [FAIL] 40 KB backslash run took $((SECONDS - s)) s"; fails=$((fails+1)); fi
# An odd run continues the line, an even run is a literal backslash.
t deny  $'echo x \\\ngit -C /r tag v1'
t allow $'git status \\\\\necho done'
t deny  $'git log \\\\\ngit branch new' # over-joining would hide the branch inside git log's arguments
# NAME=value is never the git word, so no deny for an assignment ending in /git.
t allow 'make DESTDIR=/opt/git install'
t deny  '\git branch new'
t deny  'echo commit | xargs git'
t deny  'echo -m x | xargs -n2 git commit-tree'
t deny  'echo new | xargs git branch'
t deny  'echo expire | xargs git reflog'
t allow 'ls | xargs git log --'

echo "guard-git: R11 allowlist, read-only and scratch forms allowed"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git ls-tree HEAD' 'git cat-file -p HEAD' 'git shortlog -s' 'git describe --tags' 'git reflog' \
         'git grep -n foo' 'git config --get user.name' 'git config --list' 'git config get user.name' \
         'git for-each-ref refs/shipwright' 'git merge-base main HEAD' 'git name-rev HEAD' \
         'git worktree list --porcelain' 'git -P log' 'git --no-optional-locks status' \
         'git --git-dir=/r/.git --work-tree=/r status' 'git --git-dir /r/.git status' 'git -C "$d" status' \
         'git commit-tree abc -p HEAD -p def -m "snapshot t1"' 'git commit-tree abc' \
         'GIT_INDEX_FILE=/tmp/tmp.Ab12 git update-index --add --remove -- a b' 'GIT_INDEX_FILE=/tmp/tmp.Ab12 git update-index --add --remove a b' \
         'GIT_INDEX_FILE=/tmp/i git update-index --add --remove f' \
         'git worktree add --detach ../w' 'git worktree remove --force ../w' 'git fetch origin main' \
         'cd "$(git rev-parse --show-toplevel)" && ls' 'git diff > out.patch' 'which git'; do
    t allow "$c"
done

echo "guard-git: R11 allowlist, everything else denied"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'git config user.name x' 'git config --unset user.name' 'git config --get x && git config core.x y' \
         'git reflog expire --expire=now --all' 'git worktree prune' 'git worktree add --detach -b x ../w' \
         'git worktree add --detach ../w HEAD extra' 'git worktree move ../a ../b' \
         'git update-ref refs/shipwright/../heads/main HEAD' 'git update-ref refs/shipwright/a b c' \
         'git update-ref --stdin' 'git update-ref "refs/shipwright/t1" HEAD' 'git commit-tree -p HEAD abc' \
         'git commit-tree abc -S' 'git write-tree --prefix=x' 'GIT_INDEX_FILE=$t git read-tree -m HEAD' \
         'GIT_INDEX_FILE=$t git update-index --add --remove --chmod=+x f' 'GIT_INDEX_FILE=$t git update-index --add f' \
         'git apply' 'git fetch --all' 'git fetch origin a b' 'git -c foo log' 'git --exec-path log' \
         'git -C' 'git remote add o u' 'git gc' 'git notes add -m x' \
         'GIT_INDEX_FILE="/tmp/i" git read-tree HEAD' \
         'GIT_INDEX_FILE=/tmp/i git update-index --add f'; do
    t deny "$c"
done

echo "guard-git: R12 more read and setup commands allowed"
for c in 'git --version' 'git version' 'git help commit' 'git help -a' 'brew upgrade git && git --version' \
         'git rev-list --count HEAD' 'git show-ref --heads' 'git show-ref --verify refs/heads/main' 'git ls-remote origin' \
         'git remote' 'git remote -v' 'git remote show origin' 'git remote get-url origin' \
         'git fetch' 'git fetch origin' 'git fetch --prune origin' 'git fetch -q' 'git fetch --quiet origin main' \
         'git clone https://example.com/a/b' 'git clone --depth 1 https://example.com/a/b /tmp/b' 'git init' 'git init /tmp/new'; do
    t allow "$c"
done
for c in 'git remote remove o' 'git remote set-url o u' 'git remote rename a b' 'git remote prune o' 'git remote show' \
         'git fetch --tags' 'git fetch --prune --tags origin' 'git fetch -p origin' 'git fetch origin +main:main' \
         'git clone -u x https://example.com/a/b' 'git clone --upload-pack=x .' 'git clone -c core.fsmonitor=x u' \
         'git clone --config core.fsmonitor=x u' 'git ls-remote --upload-pack=x .' 'git init --separate-git-dir /tmp/x'; do
    t deny "$c"
done

echo "guard-git: R13 -c and grep -O run programs"
for c in 'git -c core.fsmonitor=x status' 'git -c color.ui=never diff' 'git -c core.pager=cat log' \
         'git grep -Ovim foo' 'git grep -nOvim foo' 'git grep --open-files-in-pager=vim foo' 'git grep --open foo'; do
    t deny "$c"
done
t allow 'git -c color.ui=never diff' "$OK"
t allow 'git grep -n -e Option foo'

echo "guard-git: review round 3 probes"
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'cat p.diff | git apply \--cached' "cat p.diff | git apply \$''--cached" "cat p.diff | git apply \$'--cached'" \
         'cat p.diff | git apply {--cached,}' 'cat p.diff | git apply $(printf %s --cached)' \
         'git fetch origin $(echo +main:feature)' 'git fetch origin `echo main:newb`' \
         'GIT_INDEX_FILE=/tmp/x git read-tree \--index-output=.git/index' \
         'GIT_INDEX_FILE=/tmp/x git read-tree $(echo --index-output=.git/index HEAD)' \
         "x='--cached p'; git apply \$x" \
         'GIT_INDEX_FILE=.gi\t/index git read-tree HEAD' 'GIT_INDEX_FILE=.GIT/index git read-tree HEAD' \
         'cd .git && GIT_INDEX_FILE=index git read-tree HEAD' 'GIT_INDEX_FILE=/r/.GiT/index git read-tree HEAD' \
         'GIT_INDEX_FILE=/r/x.git/index git read-tree HEAD' 'GIT_INDEX_FILE=relative/i git read-tree HEAD' \
         'GIT_INDEX_FILE=/tmp/a\b git read-tree HEAD' 'git_index_file=/tmp/i git read-tree HEAD' \
         $'git log -1 --oneline \\\n\ngit branch hidden' $'git status \\\n\ngit worktree add -b hb ../w2' \
         'git init --se=../moved' 'git init --bare .git' 'git init --bare /tmp/x' 'git init --template=/t' \
         'git clone --con=core.hooksPath=/h src d2' \
         'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0="touch pwned" git status' \
         'export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0=x; git status' \
         'git_config_count=1 git status' 'GIT_EXTERNAL_DIFF="touch x" git diff' 'export GIT_SSH_COMMAND=x; git fetch origin' \
         'export GIT_DIR; git status' 'g\it commit --allow-empty -m x' 'gi\t branch viabs' \
         'GIT commit -m x' 'Git branch new' '/usr/bin/GIT push' \
         'git commit-tree abc > ../s && cp ../s .git/refs/heads/main' \
         'git log -1 --format=%H HEAD~1 --output=.git/refs/heads/main' 'git log -1 --output=/tmp/o' \
         'git diff --output /tmp/o' 'git rev-list --output=/tmp/o HEAD' 'cd .git && cp ../../s refs/heads/main' \
         'cd /r/.git && cp ../s refs/heads/main' 'cat .git/HEAD' 'type .git\HEAD' \
         '/usr/libexec/git-core/git-commit -m x' 'git-commit -m x' '/x/git-core/git-update-ref refs/heads/main HEAD' \
         'timeout 5 /usr/libexec/git-core/git-push' '/usr/libexec/git-core/git-log --output=/tmp/o'; do
    t deny "$c"
done
# Beyond the probes: brace and bracket spellings of git, and GIT_CONFIG named only indirectly.
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in '{git,} commit -m x' 'gi{t,} branch new' 'g[i]t branch new' 'x=GIT_CONFIG_COUNT; export $x=1; git status'; do
    t deny "$c"
done
for c in 'bash git_helpers.sh' 'cat .gitignore' 'ls .github/workflows' 'git clone https://example.com/a/b.git' \
         'grep -rn foo . --exclude-dir=.git' '/usr/libexec/git-core/git-log -1' 'git-status' 'cat git-notes.txt' \
         'git --git-dir=/r/.git status'; do
    t allow "$c"
done
# Moved from the R11 allow list: a variable or an unanchored index path is no longer accepted.
# shellcheck disable=SC2016  # literal command strings for the hook: $ must not expand
for c in 'GIT_INDEX_FILE=$t git update-index --add --remove -- a b' 'GIT_INDEX_FILE=$t git update-index --add --remove a b' \
         'git update-ref refs/shipwright/t1 "$sha"'; do
    t deny "$c"
done
# Long separator runs stay fast (finding 5).
semis=$(printf '%300000s' '' | tr ' ' ';'); s=$SECONDS
raw "allow: 300000 semicolons" "" "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"$semis\"}}"
raw "allow: x\" + 300000 semicolons" "" "{\"cwd\":\"$REPO\",\"tool_input\":{\"command\":\"x\\\"$semis\"}}"
if [ $((SECONDS - s)) -le 6 ]; then echo "  [PASS] separator runs within 6 s"; else echo "  [FAIL] separator runs took $((SECONDS - s)) s"; fails=$((fails+1)); fi

echo "guard-git: hooks.json wiring"
J="$ROOT/hooks/hooks.json"
# shellcheck disable=SC2016  # literal hooks.json text: ${CLAUDE_PLUGIN_ROOT} must not expand
for want in '"PreToolUse"' '"matcher": "Bash"' '"matcher": "Edit|Write|MultiEdit|NotebookEdit"' '"shell": "bash"' \
            '"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" guard-git"' \
            '"powershell": "& \"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" guard-git"'; do
    if grep -qF -- "$want" "$J" 2>/dev/null; then echo "  [PASS] hooks.json has $want"
    else echo "  [FAIL] hooks.json lacks $want"; fails=$((fails+1)); fi
done
# A crashed or timed-out guard must block the call, on both entries.
n=$(grep -c '"onFailure": "block"' "$J" 2>/dev/null)
if [ "$n" = 2 ]; then echo "  [PASS] both hook entries fail closed"; else echo "  [FAIL] onFailure block on $n of 2 entries"; fails=$((fails+1)); fi

if [ "$fails" -eq 0 ]; then echo "STATUS: PASSED"; else echo "STATUS: FAILED ($fails)"; exit 1; fi
