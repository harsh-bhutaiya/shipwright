---
name: ai-observability
description: Use in a project that calls LLMs, when adding or reviewing tracing, logging, metrics or alerts for model calls, when debugging a bad or failed model answer from a trace, or when verifying that a model feature can be observed in production.
---

# AI Observability

What to trace, log, measure and alert on for model calls and the workflows around them. A model call that cannot be inspected after the fact cannot be debugged, costed or improved.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Record these for every model call, through the provider abstraction so every call is covered:
  - the prompt and the response;
  - the model, the parameters and the prompt version;
  - tokens in and out, and the cost;
  - time to first token and total latency;
  - the finish reason, the retries, and which model provider served it.
- [practice] Emit a span for each workflow step and each tool call, nested under the span of the request that caused it. Carry a correlation ID from the entry point through every step, tool call and retry. Follow the OpenTelemetry GenAI conventions for span and attribute names where the project's tracing supports them.
- [practice] Treat traces as a store of personal data. Decide and apply redaction, sampling, retention and who has access. Redaction itself is owned elsewhere. See `shipwright:ai-security-privacy`.
- [practice] Track these metrics, each queryable by model and by workflow:
  - errors by code;
  - fallback rate;
  - validation-failure rate;
  - daily cost;
  - p95 latency.
- [practice] Alert on cost spikes, error spikes and quality drops. Each alert has a threshold, an owner and a first step to take. Cost targets and budgets: see `shipwright:ai-cost-latency`.
- [practice] Link user feedback (ratings, corrections, reports) to the trace of the answer it is about. Feedback and production failures are candidates for an eval set. See `shipwright:ai-evaluation`.
- [practice] Make a trace replayable: keep the exact inputs, prompt version, model and parameters, and tool results, so a failed call can be re-run to debug it. A replay must not repeat side effects.

## Ask the developer
- Tracing platform: detect it from the project first (an existing tracing SDK, OpenTelemetry setup, or logging pipeline). Ask only if none is found. Options: a hosted tracing product (fast to adopt, data leaves the project), self-hosted or OpenTelemetry-compatible backend (data stays in, more to run), or structured logs only (cheapest, weakest for replay and search). Follow the project's existing choice if there is one.
- Sampling rate and retention? Full capture is easiest to debug but costs storage and holds more personal data; sampling cuts both but can miss the rare failure. Options include keeping every error and every low-feedback trace while sampling the rest, and a short retention for full prompts with a longer one for metrics. Follow the project's existing choice if there is one.
- Alert thresholds? Tight thresholds catch problems early but page often; loose ones miss slow drifts. Ask for the cost, error-rate, latency and quality limits that should alert, and who is told. Follow the project's existing choice if there is one.

## Checks
- Does every model call record the prompt, response, model, parameters, prompt version, tokens, cost, latency, finish reason, retries and serving model provider?
- Is there a span for each workflow step and tool call, with a correlation ID that follows the request end to end?
- Are redaction, sampling, retention and access for traces decided, with personal data handling pointing to `shipwright:ai-security-privacy`?
- Are errors by code, fallback rate, validation-failure rate, daily cost and p95 latency tracked?
- Do alerts exist for cost spikes, error spikes and quality drops, with thresholds the developer approved?
- Is user feedback tied to a trace ID?
- Can a failed call be replayed from its trace without repeating side effects?
- Does the tracing follow the project's existing platform instead of a new one?

## Related skills
- `shipwright:ai-security-privacy`: personal data in traces and logs, redaction, secrets kept out of logs.
- `shipwright:ai-evaluation`: user feedback and production failures feed eval sets; quality metrics.
- `shipwright:ai-cost-latency`: cost and latency targets, budgets and caching behind the metrics and alerts.
