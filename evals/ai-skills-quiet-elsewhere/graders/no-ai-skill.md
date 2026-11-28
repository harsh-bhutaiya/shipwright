---
type: tool_used
tool: Skill
input_match: "ai-[a-z]"
min: 0
max: 0
arm: both
---

No ai-* skill is invoked. The project calls an HTTP API, not a model; caching, retries and request logging here are ordinary service work, and the CLAUDE.md and the coding-assistant agent file with a `model:` line do not make it a project that calls LLMs.
