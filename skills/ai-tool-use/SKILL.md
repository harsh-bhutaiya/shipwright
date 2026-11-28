---
name: ai-tool-use
description: Use in a project that calls LLMs, when defining or changing tools or function calls the model can invoke, choosing how to expose many tools, running tool calls in parallel, deciding how much of a tool result goes back to the model, or adding an MCP server.
---

# Tool Use and Function Calling

How tools are described, narrowed, validated, run and answered. Tools are where model output turns into actions, so mistakes here cost correctness, context and safety.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Treat tool names and descriptions as part of the prompt. Write them for the model: say what the tool does, when to use it and when not to. Keep parameter schemas tight (typed, enumerated, required fields marked, no catch-all fields).
- [practice] When there are many tools, accuracy of tool choice drops as the count grows. Narrow what the model sees:
  - Group tools into categories. Classify the question's intent and send only the matching categories' tools.
  - When routing picks the wrong category, give the model a way to ask for another category or to search for a tool. Never leave it stuck with the wrong set.
  - Where the model provider offers tool search (such as a provider's tool search feature), use it only behind the provider abstraction. See `shipwright:ai-llm-calls`.
  - Measure tool-selection accuracy with an eval, before and after narrowing. See `shipwright:ai-evaluation`.
- [security] Validate every tool argument against the schema and business rules before use. Model output is untrusted, whatever the schema said. See `shipwright:ai-security-privacy`.
- [reliability] Return tool errors to the model as content it can recover from (what failed, why, what it may try next). Never let a tool error crash the loop. Do not leak secrets or stack traces in the message.
- [reliability] Make tool side effects idempotent, so a retried or repeated call does not act twice (idempotency key, upsert, or check-then-act).
- [practice] Mark each tool's side effects in its description and code. Where the developer wants a dry-run mode (see Ask the developer), give those write tools one that reports what would change without changing it.
- [security] Apply least privilege: separate read tools from write tools, and give each tool only the access it needs. Confirm destructive or irreversible actions with the user or developer before they run, in code, not by asking the model.
- [reliability] Cap how many tool calls run at once. Run in parallel only calls that are independent (none needs another's result, none writes what another reads). Handle partial failure: return each call's own result or error to the model, never drop the successes because one call failed.
- [practice] Decide tool result size per tool, never by a blanket default. Apply the developer's choice (full, paginate, summarize or truncate). A truncated or paginated result says so and tells the model how to get more. See `shipwright:ai-context-management` for the context budget.
- [practice] Use MCP when a maintained server already exposes the tools, or several clients must share them. Write a plain tool when one project needs one or two. Only connect servers the developer has named as trusted. Pin the server version, and review its tool descriptions and results as untrusted content. See `shipwright:ai-prompt-injection`.

## Ask the developer
- Result size: full, paginate, summarize or truncate? Full is exact but spends context and can overflow it. Paginate keeps each result small but costs extra calls. Summarize is compact but may lose the detail the answer needs. Truncate is cheapest but can cut the part that matters. It depends on the data and the context budget. Follow the project's existing choice if there is one.
- Narrowing many tools: categories with intent routing, provider tool search, or both? Routing is predictable and provider-neutral but a wrong category hides the right tool. Provider tool search adapts to the query but ties you to a provider feature and its behaviour. Both give a fallback at the cost of more moving parts. Follow the project's existing choice if there is one.
- Concurrency cap value? A higher cap cuts latency but risks rate limits and overloads downstream systems. A lower cap is safer but slower. Follow the project's existing choice if there is one.
- Dry-run mode? It makes write tools safe to test and to preview but adds a code path per tool to maintain. Which tools need it? Follow the project's existing choice if there is one.
- Which MCP servers to trust? Own or vendor-maintained servers carry less risk than third-party ones, which add supply-chain and injection risk. Each trusted server widens what the model can reach. Follow the project's existing choice if there is one.

## Checks
- Are tool names and descriptions written for the model, with tight parameter schemas?
- With many tools, does the model see only the relevant ones, and can it recover when routing picked the wrong category?
- Is tool-selection accuracy measured with an eval?
- Is every tool argument validated before use?
- Does a tool error reach the model as content, without crashing the loop or leaking secrets?
- Is every tool with side effects idempotent, and does a retry not act twice?
- Are read and write tools separate, and is a destructive action confirmed in code before it runs?
- Is the number of parallel calls capped, are only independent calls parallel, and does one failure leave the other results intact?
- Does each tool's result size follow the developer's choice, and does a cut result tell the model it was cut?
- Is each MCP server one the developer named as trusted?

## Related skills
- `shipwright:ai-security-privacy`: tool arguments and model output as untrusted, authorization in code.
- `shipwright:ai-prompt-injection`: tool results and MCP content as injection channels.
- `shipwright:ai-evaluation`: measuring tool-selection accuracy.
- `shipwright:ai-llm-calls`: the provider abstraction that provider tool search sits behind.
- `shipwright:ai-context-management`: the context budget that bounds result size.
