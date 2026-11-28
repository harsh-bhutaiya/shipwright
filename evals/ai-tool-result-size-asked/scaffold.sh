#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
mkdir -p .shipwright app
printf 'docs_mode=in-repo\n' > .shipwright/project.conf
printf '# support-agent\nA support agent that answers with a model and calls tools. The code is not run in this repo.\n' > README.md
: > app/__init__.py
cat > app/llm.py <<'R'
from openai import OpenAI

from app.tools import TOOLS

client = OpenAI()


def answer(messages):
    return client.chat.completions.create(model="gpt-4o-mini", messages=messages, tools=TOOLS.schemas())
R
cat > app/tools.py <<'R'
import json


class Registry:
    def __init__(self):
        self.fns = {}

    def tool(self, fn):
        self.fns[fn.__name__] = fn
        return fn

    def schemas(self):
        return [{"type": "function", "function": {"name": n, "description": f.__doc__}} for n, f in self.fns.items()]


TOOLS = Registry()


@TOOLS.tool
def get_ticket(ticket_id):
    """Return one ticket by id."""
    with open("data/tickets.json") as fh:
        return next(t for t in json.load(fh) if t["id"] == ticket_id)
R
cat > spec.md <<'R'
# Spec: search_tickets tool

**Status:** draft, for the design discussion.

**Goal:** let the support agent find tickets by text, so it can answer "has anyone reported this before?".

- A new tool `search_tickets(query)` in `app/tools.py`, registered like `get_ticket`.
- It reads `data/tickets.json`, which holds about 40,000 tickets, each with `id`, `title`, `body` and `status`.
- It finds tickets whose title or body contains `query`, case-insensitive.
- It returns the matching tickets as a list of `{id, title, status, body}`.
- An empty query returns an error message to the model instead of raising.
- No new dependencies. A unit test uses a small fixture file.
R
