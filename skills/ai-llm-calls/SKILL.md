---
name: ai-llm-calls
description: Use in a project that calls LLMs, when planning or reviewing code that makes a model call or wraps a model SDK: its retries, timeouts, rate limiting, streaming, fallback provider, structured output (JSON or schema) or model parameters, or a model call that fails, truncates or returns output that does not parse.
---

# LLM Calls

How a model call is made: the provider abstraction, errors and retries, limits, streaming, structured output and parameters. A call that is not built for failure breaks in production, because model providers time out, rate-limit, truncate and refuse.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules

- [reliability] All model calls go through one provider abstraction: one interface, one adapter per model provider.
  - Model choice comes from config, not code.
  - No provider types (request, response, error or exception classes) leak into domain code. Adapters map them to the project's own types.
  - Provider-only features (such as tool search, caching, batch) sit behind the abstraction too.
- [practice] A prompt may need a variant per model provider. Keep variants next to the adapter, not in domain code.
- [reliability] Retry only retryable errors: 429, 5xx, overloaded, timeout, connection errors. Never retry 400, 401/403, unknown model, context too long or content policy. Retrying those repeats the failure and costs money.
- [reliability] Retry with exponential backoff and jitter, honor `retry-after` when present, and cap attempts. Without a cap and jitter, retries become a storm.
- [reliability] Put a circuit breaker around each model provider. After repeated failures it stops sending calls for a cool-down, then probes.
- [reliability] A retried call must be idempotent. If the call, or the tool calls it triggers, has side effects, use an idempotency key or a check before acting, so a retry never repeats a charge, email or write.
- [reliability] Every call sets timeouts: connect, read, total, and for a stream the idle time between events. An unset timeout can hang a worker forever.
- [reliability] Count tokens before the call.
  - The context window and the max output tokens are separate limits; check both.
  - Reserve the output budget out of the window.
  - Have a defined truncation strategy for input that does not fit. See `shipwright:ai-context-management`.
- [reliability] Rate-limit on the client: a limiter for the provider's per-minute request and token limits, a concurrency cap, and a queue. A key shared across services shares one limit, so budget it across them.
- [practice] Enforce per-tenant quotas so one tenant cannot use up the shared limit.
- [reliability] Handle every finish reason explicitly: normal stop, max-tokens truncation, refusal, content filter and tool-call stop. Never treat truncated or refused output as a complete answer.
- [reliability] Handle stream errors. A stream cannot be resumed, so on an error mid-stream either restart the call or show the partial result and mark it incomplete.
- [practice] Streaming code handles each event type and assembles partial output; handles client disconnect and cancellation (stop the upstream call, so it stops costing money); and applies backpressure. Never parse partial JSON or act on a partial tool call until it is complete.
- [practice] Structured output uses the provider's native schema mode or tool calling, not a format request in the prompt.
- [reliability] Validate every structured response against the schema.
  - On failure, retry with the validation error fed back, with a retry cap.
  - Also check business rules the schema cannot express (ranges, cross-field consistency, IDs that exist). A response that parses is not yet a valid one.
- [practice] Design the schema for the model: enums over free text, required fields for what you need, shallow nesting. Add an evidence or citation field where the answer must be checkable.
- [reliability] Pin model versions: use a dated or fixed model ID, not a moving alias. Check model IDs and SDK signatures against the project's pinned SDK and the provider's current docs, never memory. See `shipwright:ai-model-lifecycle` for migration.
- [practice] Set temperature, seed and reasoning budget on purpose. A seed or temperature 0 reduces variation but does not guarantee identical output; never write a test or a rule that depends on it.
- [practice] Use async calls and parallel calls where requests are independent, within the client-side limits above.
- [practice] Fallback provider, if the project has one:
  - decide what triggers it (which errors, how many, how long);
  - pick an equivalent model tier;
  - check prompt and structured-output parity: the same schema must validate on both paths;
  - evaluate the fallback path too (see `shipwright:ai-evaluation`);
  - log which provider actually served each request (see `shipwright:ai-observability`).
- [practice] Batch APIs suit offline jobs, and caching suits repeated input. See `shipwright:ai-cost-latency`.

## Ask the developer

- Which provider(s) and SDK? Name the model providers and the SDK or client the project uses; a second provider adds an adapter and parity work. Follow the project's existing choice if there is one.
- Fallback provider: whether, trigger, model tier? No fallback is simplest but an outage is your outage; a fallback adds parity checks and eval cost. The trigger can be errors, timeouts or the breaker opening. A same-tier model keeps quality, a cheaper tier keeps the service up. Follow the project's existing choice if there is one.
- Streaming? Streaming lowers time to first token and suits chat, but adds mid-stream error and partial-output handling; a full response is simpler for backend jobs and parsing. Follow the project's existing choice if there is one.
- Retry attempt count and backoff values? More attempts and longer waits raise the success rate but also latency and cost during an outage. Follow the project's existing choice if there is one.
- Temperature, seed or reasoning budget when determinism matters? Low temperature and a seed give steadier output, a larger reasoning budget gives better answers on hard tasks but costs latency and tokens. Follow the project's existing choice if there is one.
- Batch for offline jobs? Batch is cheaper and has higher limits but returns late; synchronous calls are fast and cost more. Follow the project's existing choice if there is one.

## Checks

- Does every model call go through the provider abstraction, with the model chosen from config?
- Is any provider type or error class visible outside the adapter?
- Does every call have connect, read, total and (for streams) idle timeouts?
- Does the code retry only the retryable errors, with backoff, jitter, `retry-after` and an attempt cap?
- Is there a circuit breaker, and are retried calls free of repeated side effects?
- Are tokens counted before the call, with the output budget reserved and a truncation strategy?
- Is there a client-side rate limiter and concurrency cap?
- Is every finish reason handled, including max-tokens, refusal and content filter, and are stream errors handled?
- Is structured output requested natively, validated, retried with a cap, and checked against business rules?
- Is the model version pinned, and were the model ID and SDK calls checked against current docs?
- If there is a fallback, are its parity, evals and served-provider logging covered?

## Related skills

- `shipwright:ai-cost-latency`: caching, batch, routing, budgets.
- `shipwright:ai-observability`: logging which provider and model served each request.
- `shipwright:ai-evaluation`: evals, including the fallback path.
- `shipwright:ai-model-lifecycle`: pinning policy and model migration.
- `shipwright:ai-context-management`: what goes in the window when input does not fit.
- `shipwright:ai-testing`: mocks, recorded fixtures and fault injection for these paths.
