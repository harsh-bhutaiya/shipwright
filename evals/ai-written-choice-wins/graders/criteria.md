---
type: llm
weight: 1
---

In `app/llm.py`, the new `classify` does not retry, in effect: no retry loop or retry wrapper was added, and the SDK's own automatic retries are turned off for its call (for example a retry setting of zero on the client or the call it uses). A `classify` that uses a client still on the SDK's default retries fails this check. The agent cites the CLAUDE.md rule ("no retries, fail fast") as the reason. `classify` still sets an explicit timeout on its model call, because CLAUDE.md says nothing about timeouts. The existing `summarize` is left unchanged. Nothing was staged, committed or pushed.
