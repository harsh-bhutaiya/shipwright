---
name: ai-security-privacy
description: Use in a project that calls LLMs, when planning or reviewing code around model calls that handles model provider keys, passes model output to SQL, a shell, HTML, code or file paths, enforces access control or tenant isolation around a model, sends user data to a model or logs it from model calls, adds models or MCP servers, or runs the risky check on a plan that touches model calls.
---

# Security and Privacy

Secrets, model output as untrusted input, authorization, and personal data, including personal data in traces and logs. A model call widens the attack surface and sends data to a third party, so each of these needs an explicit control.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [security] Keep secrets out of prompts (system prompts included), logs and client code. Keys live in a secret store, never in the repo, an image or a browser or mobile bundle. A key in a prompt can be echoed back to any user.
- [security] Use a separate key per environment (dev key, test, staging, production). One leaked dev key must not reach production data or spend.
- [practice] Rotate keys on a schedule and on any suspected leak. Build rotation so it needs no code change or redeploy of every service.
- [security] Treat model output as untrusted wherever it reaches SQL, shell, HTML, `eval`, generated code or file paths. The model can be steered by any text it read.
  - SQL: parameterize. Never build a query by concatenating output.
  - Shell: no shell string. Pass an argument list with an allowlisted command.
  - HTML: escape or sanitize before rendering. Never insert it as raw markup.
  - Code: run it only in a sandbox with no secrets and limited network. See `shipwright:ai-prompt-injection` for the injection defences.
  - File paths: resolve to a canonical path and check it stays inside an allowed root.
- [security] Enforce authorization in code, never by the model. The model is never told "only show this user their own data" as the control. Check the caller's permission on every tool call and data access, using the authenticated user's identity from the session, not an identity or ID the model supplies.
- [security] Isolate tenants. Scope every query, index, cache entry, memory store, file and trace by tenant in code, so one tenant's data cannot enter another's context. For retrieval access control, see `shipwright:ai-rag`.
- [security] Minimise personal data before it is sent to a model provider, and redact what is not needed (names, ids, contact details, secrets). Redact again before it is logged, traced, kept in memory or shown. Traces and logs follow the same redaction as the prompt. See `shipwright:ai-observability` for what to trace.
- [practice] Know what the model provider does with the data: retention period, whether it trains on it, and the zero-retention option. Use the provider's strictest setting the feature allows.
- [practice] Meet the data residency, data processing agreement (DPA), GDPR and HIPAA obligations that apply. Do not send regulated data to a model provider or region that has no agreement covering it.
- [practice] Check the supply chain before adding a model, package or MCP server. Pin versions, review who publishes it, and treat a tool server's descriptions and results as untrusted. Do not load model files in an unsafe serialization format (such as pickle-based files). Prefer a safe format.
- [security] Put per-user rate limits on every model-backed endpoint, so one user cannot exhaust the quota or budget.
- [practice] Defend against attacks that run up your bill: cap input and output tokens and agent steps, cap spend per user and per day, require authentication, and alert on spend spikes. Budgets are covered in `shipwright:ai-cost-latency`.
- [practice] Plan for content abuse (users using the feature to generate harmful content). Moderation is covered in `shipwright:ai-guardrails`.
- [practice] Use the OWASP Top 10 for LLM applications as the review checklist for the feature, and note which items apply.

## Ask the developer
- Data residency, retention and zero-retention needs? Residency pins the region (less choice of model and provider). Zero retention cuts what the provider keeps (and may cost more or switch off features that need stored data). Follow the project's existing choice if there is one.
- Compliance regime? Options include none, GDPR, HIPAA, SOC 2 or a sector rule. A stricter regime means more redaction, audit logging and approved providers, at the cost of speed and model choice. Follow the project's existing choice if there is one.
- Which provider data agreement applies? Options are the provider's standard terms, an enterprise or zero-retention agreement, or a signed DPA or BAA. The standard terms are quicker but may not cover regulated data. Follow the project's existing choice if there is one.

## Checks
- Does any key appear in a prompt, a log line, a trace, a committed file or client code?
- Is there a separate key for each environment, and a way to rotate it?
- Does model output reach SQL, a shell, HTML, `eval`, code or a file path, and is each place parameterized, escaped, sandboxed or path-checked?
- Is access control checked in code on every tool call and data access, using the authenticated user and not a model-supplied identity?
- Can any query, index, cache, memory or trace cross a tenant boundary?
- Is personal data minimised before the call and redacted in traces and logs?
- Does the provider's retention, residency and agreement match the data sent and the compliance regime?
- Is each new model, package, MCP server and model file pinned, vetted and in a safe format?
- Is there a per-user rate limit, a cap on spend and steps, and a plan for content abuse?
- Was the OWASP Top 10 for LLM applications walked through for this change?

## Related skills
- `shipwright:ai-prompt-injection`: injection defences and closing exfiltration channels.
- `shipwright:ai-rag`: retrieval access control.
- `shipwright:ai-observability`: what to trace and log, and redaction in traces.
- `shipwright:ai-guardrails`: moderation and content abuse.
- `shipwright:ai-cost-latency`: budgets and spend caps.
