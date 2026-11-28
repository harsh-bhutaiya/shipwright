---
name: ai-context-management
description: Use in a project that calls LLMs, when planning or reviewing what goes into a model's context window: budgeting tokens, ordering the prompt, managing conversation history, handling large documents, isolating context, deciding where multi-turn state lives, or debugging a model call's bad answer that may come from missing, buried or stale context.
---

# Context Management

This covers what goes into the context window and in what order. A window that is overfull, badly ordered or full of irrelevant content gives worse answers and costs more.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Budget the window across its parts: system prompt, history, retrieved documents, tool results and reserved output. Give each part a limit.
- [reliability] Reserve output tokens out of the window so the reply is never cut off. Token limits and counting: see `shipwright:ai-llm-calls`.
- [practice] Order the context deliberately.
  - Put long documents first and the question or instruction last.
  - Models miss facts buried in the middle ("lost in the middle"), so put what matters most at the start or the end.
- [practice] Manage history so it does not grow without bound. Choose one strategy and apply it before the budget is hit, not after the call fails.
  - Sliding window: keep the last N turns. Simple, but older facts are lost.
  - Summarization: replace old turns with a summary. Keeps the gist, but costs a call and can drop details.
  - Compaction: drop or shrink low-value content, such as old tool output, and keep the rest verbatim.
- [practice] Tool results: follow the developer's choice from `shipwright:ai-tool-use` (full, paginate, summarize or truncate). Filter what stays in context for relevance, and drop results that no longer matter.
- [practice] Put the stable prefix first (system prompt, tool definitions, fixed instructions), and the parts that change per request last, so caching works. Caching rules: see `shipwright:ai-cost-latency`.
- [practice] Large documents: chunk them. For a document that does not fit, process the chunks separately and then combine the results (map-reduce). Do not truncate silently.
- [practice] Context isolation follows the project's design.
  - Use subagents only if the project already does, or its design calls for them.
  - Otherwise scope and summarize within one context.
- [reliability] A subagent never dispatches subagents, and reports back when its task does not fit its context. See `shipwright:ai-agents`.
- [practice] Keep multi-turn state where the project's design puts it, and keep it separate from the prompt text. Rebuild the context for each call from that state. Do not rely on an earlier call's context being still there.

## Ask the developer
- Context isolation: subagents only if the project's design uses them? Subagents keep each task's context small and clean, but add dispatch cost, handoff loss and more to coordinate. One context with scoping and summaries is simpler, but it fills up faster. Follow the project's existing choice if there is one.
- History: sliding window, summarize or compact? A sliding window is cheapest and simplest but forgets old facts. Summarizing keeps the gist but costs an extra call and can lose detail. Compaction keeps the important parts verbatim but needs rules for what to drop. Follow the project's existing choice if there is one.
- Where multi-turn state is stored? On the client, the app server's memory, a database or cache, or with the model provider. Client or provider storage is simple but gives the project less control. A database or cache survives restarts and scales across servers, but needs retention and access rules. Follow the project's existing choice if there is one.

## Checks
- Does the plan or diff give each part of the window (system prompt, history, documents, tool results, output) a limit, with output tokens reserved?
- Is the long material placed before the question, with the key facts at the start or end rather than the middle?
- Does history have a strategy that applies before the budget is exceeded?
- Is tool-result content filtered for relevance, in line with the developer's choice in `shipwright:ai-tool-use`?
- Is the stable prefix first and the per-request content last?
- Is a document that exceeds the window chunked, rather than truncated silently?
- Are subagents used only where the project's design calls for them?
- Is multi-turn state stored where the developer chose, and is the context rebuilt from it each call?

## Related skills
- `shipwright:ai-tool-use`: tool result size and the full, paginate, summarize or truncate choice.
- `shipwright:ai-agents`: subagent rules, agent state and memory.
- `shipwright:ai-cost-latency`: caching and the stable prefix.
- `shipwright:ai-llm-calls`: token counting and limits.
