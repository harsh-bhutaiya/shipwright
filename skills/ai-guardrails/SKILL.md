---
name: ai-guardrails
description: Use in a project that calls LLMs, when planning or reviewing moderation of user input or model output, personal data in output, hallucination or grounding checks, topic restrictions, refusal handling, or hand-off to a human when the model is not confident.
---

# Guardrails and Output Safety

Guardrails sit around the model call: they check what goes in and what comes out, and decide when a person takes over. They matter because the model can be wrong, unsafe or off-topic, and the product is still answerable for what the user sees.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Moderate input and output as separate checks. Input moderation stops abuse before it costs a call; output moderation catches what the model produced anyway. Which sides to cover is an Ask item.
  - A blocked input or output returns a defined, user-safe message, never the raw model text or the raw error.
  - Log which guardrail fired, without the content (see `shipwright:ai-security-privacy`).
- [security] Detect personal data in output before it is shown, stored or passed on, and redact or block it. Output can leak data the model saw in context, retrieval or tools. See `shipwright:ai-security-privacy` for the wider personal-data rules.
- [practice] Check answers that claim facts for hallucination, using the method the developer chose.
  - Where retrieval or tools supply sources, check that each claim is supported by them; an unsupported claim is removed, flagged or sent back for a retry with a cap.
  - Check citations point at sources that were actually provided.
  - Measure the check itself with an eval set that includes known-bad answers. See `shipwright:ai-evaluation`.
- [practice] Enforce topic restrictions in two places: the prompt says what is out of scope, and a check outside the model confirms it. A prompt instruction alone is not a restriction. Out-of-scope requests get a clear redirect, not a silent drop.
- [reliability] Handle refusals as a normal outcome: detect them, do not retry them unchanged, and show a clear message instead of an empty or broken result. See finish reasons in `shipwright:ai-llm-calls`.
- [practice] Hand off to a human when confidence is low, using the threshold the developer set.
  - Define the signal that produces confidence (grader score, grounding result, model-reported value, or a rule), and note that a model's self-reported confidence is weak evidence.
  - The hand-off keeps the context a person needs and tells the user what happens next. See `shipwright:ai-ux`.
- [practice] Guardrail checks fail in a defined direction. Decide per check whether an error in the check blocks the output (fail closed) or lets it through (fail open), and do not leave it to whatever the code does by accident.
- [practice] Guardrail thresholds and blocklists are versioned, and changes to them are tested against an eval set before release. See `shipwright:ai-evaluation`.
- [practice] Keep guardrail checks in code, not only in the prompt. A guardrail the model can talk itself out of is not a guardrail. Injection defences are in `shipwright:ai-prompt-injection`.

## Ask the developer
- Which moderation (input, output)? Input only is cheapest and stops abuse early, but misses unsafe model output. Output only catches what users would see, but pays for the model call first. Both cost the most latency and money, and give the best coverage. Follow the project's existing choice if there is one.
- Topic restrictions? None leaves the model open to any request. A prompt-only scope is cheap but easy to bypass. A prompt plus a classifier or allowlist check is stronger but adds latency and a component to maintain. Follow the project's existing choice if there is one.
- When to hand off to a human (confidence threshold)? A high threshold sends more cases to people, which is safer but costs staff time and slows answers. A low threshold automates more and lets more mistakes through. The answer depends on the cost of a wrong answer. Follow the project's existing choice if there is one.
- Hallucination-check method? Source-grounded claim checks are the strongest where there are sources, but need retrieval or tools. A second model as judge is general but adds cost and its own errors. Rule or schema checks are cheap but cover only what rules can express. Sampling and human review is the cheapest and slowest. Follow the project's existing choice if there is one.

## Checks
- Is output moderated as well as input, or is the one-sided choice written down by the developer?
- Is personal data in output detected and redacted or blocked before display and storage?
- Does a refusal reach the user as a clear message, and is it not retried unchanged?
- Is the hallucination check applied to every answer that claims facts, with a defined action when it fails?
- Is each topic restriction enforced by a check outside the prompt?
- Is there a defined path to a human, with a stated threshold and the context handed over?
- Does each guardrail have a fail-open or fail-closed decision?
- Are guardrail changes tested on an eval set, including known-bad examples?

## Related skills
- `shipwright:ai-security-privacy`: personal data handling, untrusted model output, logging without content.
- `shipwright:ai-llm-calls`: finish reasons, including refusals.
- `shipwright:ai-evaluation`: eval sets for guardrails and for the hallucination check.
- `shipwright:ai-ux`: refusal messages, uncertainty display and the hand-off experience.
- `shipwright:ai-prompt-injection`: injection defences.
