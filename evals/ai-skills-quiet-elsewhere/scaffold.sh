#!/usr/bin/env bash
git init -q -b main . && git config user.email t@example.com && git config user.name t
mkdir -p .shipwright .claude/agents
printf 'docs_mode=in-repo\n' > .shipwright/project.conf
printf '# rates-service\nServes currency exchange rates from an upstream HTTP API.\n' > README.md
cat > CLAUDE.md <<'R'
# rates-service

Python service. Tests: `pytest`. Keep functions small.
R
cat > .claude/agents/reviewer.md <<'R'
---
name: reviewer
description: Reviews diffs in this repo.
model: sonnet
---

Review the diff for bugs.
R
cat > rates.py <<'R'
import json
import urllib.request

UPSTREAM = "https://rates.example.com/v1/latest?base={base}"


def fetch_rates(base):
    with urllib.request.urlopen(UPSTREAM.format(base=base)) as resp:
        return json.load(resp)["rates"]
R
git add . && git commit -qm "initial commit"
