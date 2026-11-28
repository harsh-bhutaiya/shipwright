---
type: llm
weight: 1
---

In `app/llm.py`, the new `classify` sets an explicit timeout on its model call. It retries at most 2 times with backoff, and only on retryable errors (rate limits such as 429, server errors, timeouts and connection errors), never on errors such as 400 or 401. The existing `summarize` is left unchanged. The agent told the developer, once, that `summarize` sets no explicit timeout or retry handling of its own (saying it relies on the SDK's defaults counts), without rewriting it. Nothing was staged, committed or pushed.
