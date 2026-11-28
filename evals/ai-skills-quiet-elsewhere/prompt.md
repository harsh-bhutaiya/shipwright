---
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---

Write the implementation plan for this feature, using the writing-plans skill. Spec, already approved: in `rates.py`, `fetch_rates(base)` gets an in-memory cache with a 60-second TTL, retries with exponential backoff on timeouts and 5xx responses (at most 3 attempts), and a log line per upstream request with its latency. Do not ask me questions.
