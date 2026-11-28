---
name: ai-prompt-engineering
description: Use in a project that calls LLMs, when writing, editing or reviewing a prompt, system message, prompt template or few-shot examples, deciding where a prompt lives in the repo, or changing a prompt after a model change.
---

# Prompt Engineering

How prompts are structured, written, stored and changed. A prompt is code that the model executes, so it needs structure, versioning and review like any other code.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Structure each prompt in a fixed order: role, task, context, constraints, output format. Separate the parts, and keep variable content apart from instructions with delimiters or tags. Delimiting untrusted content is an injection defence: see `shipwright:ai-prompt-injection`. A reader and the model can then tell instructions from data.
- [practice] Write clear, direct instructions and explain why a constraint exists. State what to do, not only what to avoid. A model that knows the reason applies the rule to cases the prompt did not list.
- [practice] Choose few-shot examples that are diverse and representative of real inputs, including edge cases and the refusal or empty case.
  - Watch for ordering bias: the model leans toward the last or most common example. Vary the order and check that results do not depend on it.
  - Do not use examples that are near-copies, or that differ only in the wording of one field.
- [practice] Use reasoning or thinking modes only for tasks that need multi-step reasoning, and only where an eval shows a gain. Skip them for simple extraction, classification and formatting. They add latency and output tokens. The developer decides the trade-off (see Ask the developer).
- [practice] Put stable instructions in the system message: role, rules, output format, tool guidance. Put the per-request input and retrieved content in the user message. Keeping the stable part first and unchanged also helps caching (see `shipwright:ai-cost-latency`).
- [practice] Build prompts from templates with named variables. Fill every variable explicitly, and fail on a missing one instead of sending a literal placeholder. Escaping and delimiting untrusted input in a template is covered by `shipwright:ai-prompt-injection`.
- [practice] Keep prompts in files (or a prompt store), not inline strings scattered through code.
  - Version them in the repository, with the prompt file as the unit of change.
  - Review prompt diffs like code diffs: a one-line wording change can change behaviour.
  - Record the prompt version with each call, so a bad answer can be traced to the prompt that produced it.
- [practice] Re-tune prompts when the model changes. A prompt tuned for one model can degrade on another. See `shipwright:ai-model-lifecycle`.
- [reliability] Every prompt change must pass the eval gate before it ships. See `shipwright:ai-evaluation`.
- [practice] Avoid these anti-patterns:
  - contradictory instructions (for example "be brief" and "explain in full detail");
  - shouting in capitals or repeated emphasis in place of a reason;
  - bloat: long lists of rules and one-off patches that were never removed. Prune instructions that an eval shows are not needed.

## Ask the developer
- Use of reasoning or thinking modes (cost trade-off)? On: better results on multi-step tasks, but more latency and more output tokens per call. Off: faster and cheaper, with weaker results on hard tasks. A budget or effort level sits in between. Follow the project's existing choice if there is one.

## Checks
- Does each prompt separate role, task, context, constraints and output format, with variable or untrusted content in delimiters?
- Does each constraint say what to do, with a reason, and is the prompt free of contradictions, capitals-for-emphasis and unused rules?
- Are the few-shot examples diverse and representative, and was the effect of their order checked?
- Is the system message limited to stable instructions, with per-request input in the user message?
- Are prompts files in the repo with named variables, and does a missing variable fail instead of passing through?
- Is the prompt version recorded with each call, and is the prompt diff reviewed?
- Does a prompt change have a passing eval gate, and was the prompt re-tuned if the model changed?
- Is any use of reasoning or thinking mode backed by the developer's choice and an eval result?

## Related skills
- `shipwright:ai-evaluation`: the eval gate on prompt changes.
- `shipwright:ai-model-lifecycle`: re-tuning prompts on a model change, and release.
- `shipwright:ai-prompt-injection`: escaping and delimiting untrusted input in templates.
- `shipwright:ai-cost-latency`: prompt caching, and the cost of reasoning modes.
