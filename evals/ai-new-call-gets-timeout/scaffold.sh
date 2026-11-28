#!/usr/bin/env bash
git init -q -b main . && git config user.email t@example.com && git config user.name t
mkdir -p .shipwright app
printf 'docs_mode=in-repo\n' > .shipwright/project.conf
cat > README.md <<'R'
# ticket-bot
Summarises support tickets with a model. The code is not run in this repo: there is no API key here.
R
: > app/__init__.py
cat > app/llm.py <<'R'
from openai import OpenAI

client = OpenAI()


def summarize(text):
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": "Summarize this ticket:\n" + text}],
    )
    return resp.choices[0].message.content
R
cat > plan.md <<'R'
# Classify Tickets Implementation Plan

**Goal:** Label each support ticket as a bug, a feature request or a question.

**Settled with the developer:** use the existing client and model in `app/llm.py`; no fallback provider; no streaming; default model parameters. Retries: at most 2 retries, with exponential backoff starting at 1 second.

## Branch stack
- classify-tickets: tasks 1-1; based on main

## Acceptance checklist
- [ ] classify returns one of bug, feature, question — verify: live run — read `app/llm.py`; the code is not run here (no API key)

### Task 1: classify

Risky: none

**Files:**
- Modify: `app/llm.py`

- [ ] **Step 1:** Add `classify(text) -> str` to `app/llm.py`. It asks the model to label the ticket as exactly one of `bug`, `feature` or `question`, and returns that label.
- [ ] **Checkpoint:** files `app/llm.py`; commit message `feat: classify tickets`
R
git add . && git commit -qm "initial commit"
git checkout -q -b classify-tickets
