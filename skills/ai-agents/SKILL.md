---
name: ai-agents
description: Use in a project that calls LLMs, when designing, planning or reviewing an agent loop, its stop conditions or budgets, agent state or memory, human approvals, code execution by a model, or a multi-agent or subagent setup.
---

# Agents

Loops, budgets, state, memory, human approvals, sandboxes, and the multi-agent and subagent rules. An agent runs unattended and spends money on every turn, so it needs hard limits and a way to stop.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [reliability] Every agent loop has stop conditions: a final answer, a max iteration count, a token budget, a cost budget and a time limit. The loop ends on whichever is hit first and returns a defined result, never hangs. A loop with no cap can run up cost without limit.
- [reliability] Detect loops and repetition. Track recent tool calls (name plus arguments) and results. On a repeat, or on several turns with no progress, stop or change course (feed back a note, then abort). An agent calling the same failing tool forever is the common failure.
- [practice] Keep agent state outside the model's context, in a store the code owns. Where the developer wants checkpoint and resume, checkpoint after each step so a crash resumes from the last checkpoint; resumed steps with side effects must be idempotent.
- [practice] Separate short-term memory (the current run's working state and history) from long-term memory (kept across runs). Decide per item what is stored, where, and when it is dropped. Long-term memory needs a forgetting rule: expiry, a size cap, or a delete on request.
- [security] Personal data in memory is minimised: store only what the task needs, redact before writing, and make it deletable per user. A memory store is a data store and follows `shipwright:ai-security-privacy`.
- [practice] Single agent or multi-agent is the developer's choice (see Ask the developer). When advising, the case for multiple agents is work that splits into independent parts, needs a different tool set or permission level, or would overflow one context. Each agent adds calls, latency and failure modes, and cost multiplies with each one.
- [practice] Hand off between agents with a narrow, explicit task and only the context that task needs. Each agent works in its own isolated context. It returns a short result, not its full transcript.
- [reliability] Subagents never dispatch subagents. Only the main agent dispatches. Enforce it by not giving subagents the dispatch tool, not by instruction alone.
- [reliability] A subagent that cannot handle its task within its own context reports back. It does not return a partial result as if it were complete. It says what did not fit and why. The main agent then narrows the task, splits it into smaller subagent tasks that it dispatches itself, or supplies the missing context.
- [practice] Put human-in-the-loop points where the developer chose (see Ask the developer). When advising, the usual places are actions that are irreversible, costly, or sent outside the system. The agent pauses, shows what it will do, and waits for approve, edit or reject. A human can also interrupt a running agent at any step. Where checkpoints are used, a pause must survive a restart. For confirmation before side effects, see `shipwright:ai-prompt-injection`.
- [security] Code the model writes runs in a sandbox: no access to host files, secrets or credentials, CPU, memory and time limits, and network access off or restricted to an allowlist.
- [security] Injection can spread from one agent to the next through handoff content. Treat an agent's output as untrusted input to the next. See `shipwright:ai-prompt-injection`.

## Ask the developer
- Single agent or multi-agent? One agent is simpler, cheaper and easier to debug. Multiple agents help with independent parallel work, separate permissions or context overflow, at a multiplied cost. Follow the project's existing choice if there is one.
- What memory stores, and when does it forget? Options are none, run-only, or long-term (a database, files, a vector store). Long-term memory helps continuity but holds personal data and can go stale; forgetting by expiry, cap or user request trades recall for privacy and size. Follow the project's existing choice if there is one.
- Where do humans approve or interrupt? Approving every action is safest and slowest; approving only irreversible or external actions keeps speed with less cover. Follow the project's existing choice if there is one.
- What budget values: iterations, tokens, cost, time? Tight budgets bound cost and stop runaways, but cut off long tasks; loose ones finish more but risk spend. Follow the project's existing choice if there is one.
- Is checkpoint and resume needed? It makes long or costly runs survive crashes, but adds a state store and idempotency work; short cheap runs can restart instead. Follow the project's existing choice if there is one.

## Checks
- Does the loop have an iteration cap, token, cost and time budgets, and a defined result when one is hit?
- Does the loop detect repeated calls or no progress, and act on it?
- Is state stored outside the context? If checkpoint and resume were chosen, can a crash resume from the last checkpoint, and are resumed side effects idempotent?
- Does long-term memory have a forgetting rule, and is personal data in it minimised and deletable?
- If there is more than one agent, is there a stated reason one agent will not do, and is the cost counted?
- Is the dispatch tool withheld from subagents in code, not only in the prompt?
- Does a subagent report back what did not fit and why, instead of returning a partial result as complete?
- Do the actions the developer chose pause for human approval, and can a human interrupt a run?
- Does model-written code run in a sandbox with resource and network limits?
- Is output passed between agents treated as untrusted?

## Related skills
- `shipwright:ai-tool-use`: tool design, parallel calls, result size.
- `shipwright:ai-context-management`: the context budget, history, isolation.
- `shipwright:ai-prompt-injection`: injection spreading across agents, confirmation before side effects.
- `shipwright:ai-cost-latency`: measuring and budgeting cost and time.
- `shipwright:ai-security-privacy`: personal data in stores and logs.
