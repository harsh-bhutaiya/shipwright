---
name: ai-architecture-decisions
description: Use in a project that calls LLMs, when brainstorming or scoping an AI feature, deciding whether it needs a model at all, choosing between a single call, a workflow and an agent, or choosing the implementation level, the retrieval or fine-tuning approach, the execution mode, human oversight or the failure behaviour.
---

# AI Architecture Decisions

Frames the problem before any model code is planned: whether an LLM is needed, how much machinery it needs, and what happens when it fails. The cheapest mistake to fix is the one made on paper.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Test the need for an LLM first. Check whether rules, regex, search or classic ML would do the job, and say why not before a model is chosen. A model adds cost, latency and unpredictability.
- [practice] Pick the simplest rung that works: single call, then workflow, then agent. Move up only when the lower rung fails on the success criteria, and record the failure that justified the move.
- [practice] When a workflow is needed, name the pattern: chaining, routing, parallel calls, orchestrator-workers or evaluator-optimizer. A named pattern can be tested step by step.
- [practice] Justify an agent only when the number of steps is unknown, or the choice of tool depends on what happens along the way. A fixed sequence of steps is a workflow.
- [practice] Compare the implementation levels (provider's single-call API, the provider's agent SDK, a framework) on lock-in and debuggability, and state the trade-off in the plan.
- [practice] Choose between prompting, RAG and fine-tuning on evidence. Start with prompting. Add retrieval when the model lacks knowledge, and fine-tune only when prompting and retrieval fall short of the success criteria. See `shipwright:ai-rag`.
- [practice] Decide real-time, background job or batch from the user's wait and the cost. Do not run a model in the request path if the user does not need the answer in it.
- [practice] Decide where a human approves or takes over before building, not after. Put an approval step before any action that is hard to undo.
- [practice] Define success criteria up front, measurable and before the first prompt is written. See `shipwright:ai-evaluation`.
- [practice] Design the failure path with the happy path: what the user sees and what the system does when the model is down, wrong or refuses. A failure path found in production was a missing requirement.
- [practice] Multi-agent designs are not decided here. See `shipwright:ai-agents`.

## Ask the developer
- Does this need an LLM at all? Rules, regex, search or classic ML are cheaper, faster and deterministic, but break on open-ended input. Follow the project's existing choice if there is one.
- Single call, workflow (which pattern) or agent? A single call is the simplest and easiest to test. A workflow adds steps with a known order. An agent handles unknown steps at the cost of predictability, cost and testing effort. Follow the project's existing choice if there is one.
- Implementation level: provider API, agent SDK or framework? The provider API gives the most control and the least lock-in. An agent SDK or framework saves code but adds lock-in and hides what is sent to the model. Follow the project's existing choice if there is one.
- Prompting, RAG or fine-tuning? Prompting is the cheapest to change. RAG supplies fresh or private knowledge. Fine-tuning changes style or narrow behaviour but is costly to maintain and must be redone when the model changes. Follow the project's existing choice if there is one.
- Real-time, background or batch? Real-time gives the fastest answer at the highest price and the least retry room. Background frees the user but needs status and delivery. Batch is the cheapest but slow. Follow the project's existing choice if there is one.
- Where does a human approve or take over? More approval is safer but slower. Less is faster but a wrong action goes through. Follow the project's existing choice if there is one.
- What are the success criteria? Without a number there is nothing to test or to gate a change on. Follow the project's existing choice if there is one.
- What should happen when the model is down, wrong or refuses? Options are a fallback model, a non-AI fallback, a plain error, a retry later or a hand-off to a human. Each trades availability against cost and quality. Follow the project's existing choice if there is one.

## Checks
- Does the plan say why rules, regex, search or classic ML are not enough?
- Is the chosen rung (single call, workflow, agent) the simplest that meets the success criteria?
- If it is a workflow, is the pattern named?
- If it is an agent, is the unknown number of steps or the tool choice that depends on events stated?
- Is the implementation level chosen, with its lock-in and debuggability trade-off stated?
- Is the choice between prompting, RAG and fine-tuning made, with a reason?
- Is the execution mode (real-time, background, batch) chosen and matched to what the user waits for?
- Is it clear where a human approves or takes over?
- Are the success criteria written down, measurable, and handed to the evaluation plan?
- Does the plan say what happens when the model is down, wrong or refuses?

## Related skills
- `shipwright:ai-agents`: loops, budgets and multi-agent rules, once an agent is chosen.
- `shipwright:ai-rag`: retrieval design, once RAG is chosen.
- `shipwright:ai-evaluation`: turning the success criteria into metrics and an eval set.
