---
name: ai-cost-latency
description: Use in a project that calls LLMs, when planning or verifying the cost or speed of model calls, adding or changing a model call, choosing a model for a task, adding a cache in front of model calls, setting spend caps, budgets or quotas for model use, moving model calls to batch, or making a slow AI feature feel faster.
---

# Cost and Latency

Covers what an AI feature costs and how fast it feels: measuring, routing, caching, token reduction, budgets, spend limits and perceived latency. Unmeasured cost surprises the team, and an unsafe cache leaks one user's data to another.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Measure before optimising. Record cost per request, per user and per feature, from token counts and the current price. Compare any optimisation against that baseline. See `shipwright:ai-observability` for how to trace and measure it.
- [practice] When the developer chooses routing or a cascade: route by task difficulty. Send simple, high-volume tasks to a smaller or cheaper model and hard ones to a bigger model. A cascade tries the small model first and escalates on a failed check (validation failure, low confidence, refusal). Check the cascade on an eval set: it must hold quality, and the escalation rate must keep total cost below always using the big model.
- [practice] Design prompts around a stable prefix so the model provider's prompt caching hits: static instructions, tool definitions and shared documents first; per-request content last. Nothing that changes per request (timestamp, user name, request ID) goes in the prefix. Check cache-hit tokens in usage data after the change. See `shipwright:ai-context-management` for the layout.
- [security] A cache never serves one user's response to another. Every response cache key includes the tenant and user (or a permission scope that is provably identical), the model and the prompt version. Never cache a response built from user-specific or personal data under a shared key. Test with two users.
- [practice] Response caching, exact or semantic, is added only where the answer can safely repeat. Every entry has a TTL, and an invalidation path for when the source data, prompt or model changes. A semantic cache has a similarity threshold tuned on an eval set, because a near match can be the wrong answer. Never cache errors, refusals or truncated output.
- [practice] Reduce tokens before reaching for a cheaper model: trim context to what the task needs, cap output length (`max tokens` set per call, matching the expected answer), and use compact formats for data sent in and structured output coming out.
- [practice] Use batch pricing for work no user is waiting on (backfills, nightly jobs, bulk classification, eval runs). Batch results arrive late and can fail per item: handle partial failure. See `shipwright:ai-llm-calls`.
- [reliability] Retries and agent loops have budgets: a retry cap per call, a token and step cap per run. See `shipwright:ai-llm-calls` and `shipwright:ai-agents`.
- [practice] Put limits on spend: a hard spend cap per environment, per-tenant quotas, alerts before the cap (for example at 50% and 80%) and a kill switch that turns the feature off or falls back without a deploy. The limit check runs before the call. Test what the user sees when a limit trips.
- [practice] Prices change. Keep prices and model names in config, not scattered in code, with the date they were checked, and review them when the model provider announces a change. Cost reports use the config.
- [practice] Improve perceived latency, not only total time:
  - stream output so the first tokens show early;
  - run independent calls in parallel (see `shipwright:ai-tool-use` for the caps);
  - use smaller models and shorter outputs on the critical path;
  - move long tasks to background jobs with progress updates.
- [practice] Verify cost and latency after the change, with numbers: p50 and p95 latency, time to first token, cost per request against the baseline. Do not claim a saving or speed-up without them.

## Ask the developer
- Spend cap and quota values? A low cap protects the budget but can cut off real users; a high one risks a bill spike. Per-tenant quotas protect fairness but need tenant tracking. Ask for the numbers and what happens on hitting a limit. Follow the project's existing choice if there is one.
- Routing or cascade between models? A single model is simpler and predictable. Routing by task type is cheap to run but needs a clear split. A cascade saves the most but adds latency on escalation and needs a reliable quality check. Follow the project's existing choice if there is one.
- Response caching (exact or semantic), given staleness and cross-user risk? None is safest. Exact match is predictable but hits rarely. Semantic hits more but can return a wrong near match. Ask the TTL and what is shared across users, if anything. Follow the project's existing choice if there is one.
- Batch for offline work? Batch is cheaper but results are delayed and arrive per item. Online calls are immediate and cost more. Ask which jobs can wait. Follow the project's existing choice if there is one.

## Checks
- Is there a baseline of cost per request, per user and per feature before any optimisation?
- Does each cache key include the tenant or user, the model and the prompt version, and is there a two-user test?
- Does every cache entry have a TTL and an invalidation path, and are errors and refusals never cached?
- Is the stable prefix first in the prompt, with nothing per-request in it, and are cache hits visible in usage data?
- If there is a route or cascade, is it checked on an eval set for both quality and total cost?
- Is output length capped on every call?
- Are retries and agent loops bounded by a cap?
- Are there a spend cap, per-tenant quotas, alerts and a kill switch, and is the limit-tripped path tested?
- Are prices kept in config with a check date?
- Are streaming, parallel calls or background jobs used where a user waits?
- Are before and after numbers given for any claimed cost or latency gain?

## Related skills
- `shipwright:ai-context-management`: stable prefix layout, trimming context.
- `shipwright:ai-llm-calls`: batch calls, retries, timeouts, streaming.
- `shipwright:ai-agents`: loop budgets and stop conditions.
- `shipwright:ai-observability`: measuring cost and alerts.
- `shipwright:ai-tool-use`: parallel tool calls.
- `shipwright:ai-evaluation`: eval sets for checking routes and caches.
