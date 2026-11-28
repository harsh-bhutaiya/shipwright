---
name: ai-ux
description: Use in a project that calls LLMs, when designing or reviewing the user-facing side of an AI feature, such as streamed answers, loading states, citations, regenerate or feedback buttons, error and refusal messages, or the notice that content comes from AI.
---

# UX for AI Features

How model output reaches the user: streaming and loading states, citations and uncertainty, controls, failure messages and AI disclosure. Model output is slow, variable and sometimes wrong, so the interface has to show progress, say how far to trust it and give the user a way out.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Show progress before the first token arrives: a loading state, then the stream. Show partial output as it comes where the answer reads well in pieces. Streaming itself is owned by `shipwright:ai-llm-calls`; this rule covers only what the user sees.
- [practice] Let the user stop a running response, and keep what has streamed so far. Do not leave the interface frozen on a slow or stalled stream.
- [practice] Do not render half-finished structure as if it were final. A partial list, table, link or markup is held back or shown as incomplete until it is complete.
- [practice] Show the source of each claim the answer rests on, as a citation the user can open. Show a citation only for a source that was really retrieved. Never let the model invent one. Grounding rules are in `shipwright:ai-rag`.
- [practice] Show uncertainty in plain words when the system has a signal for it, such as no source found, low retrieval score or a refusal to guess. Do not fake confidence with a number the system does not measure.
- [practice] Offer the regenerate, edit and feedback controls the developer chose (see Ask the developer). Regenerate keeps the earlier answer reachable. Edit lets the user change their own input and rerun it. Feedback is one tap, with an optional reason.
- [practice] Link each feedback action to the trace of the response it rates, so the feedback can be used. See `shipwright:ai-observability`. Keep personal data out of what feedback stores (`shipwright:ai-security-privacy`).
- [practice] Write failure messages for the user's next step: what went wrong in plain words, and what to do (retry, rephrase, contact support). Do not show raw errors, stack traces, provider names or request IDs the user cannot use.
- [practice] Give a refusal its own message, apart from an error. Say what the system cannot help with and offer another route. Do not blame the user, and do not show the model's own refusal text unreviewed. Handling every finish reason is in `shipwright:ai-llm-calls`; filtering and safe fallbacks are in `shipwright:ai-guardrails`.
- [practice] Tell users when they are dealing with AI: label AI-written content, and make a chat or agent clear that it is not a person. Keep the label visible on content that is copied, shared or saved, where the format allows. Check any legal disclosure duty with the developer rather than assuming one.

## Ask the developer
- Streaming display? Stream token by token (feels fast, but half-finished text, links and structure can show, and the layout can jump), stream by sentence or block (steadier, a little slower), or show the whole answer at once with a loading state (simplest, but long waits feel broken). Follow the project's existing choice if there is one.
- How do citations and uncertainty show? Inline markers (easy to check each claim, more clutter), a source list under the answer (clean, harder to match to claims), or hover or expand (compact, easy to miss). Uncertainty can be a plain-words note, a visual cue, or hidden unless there is no source. Follow the project's existing choice if there is one.
- Which regenerate, edit and feedback controls? None, regenerate only, edit and resend, thumbs, or thumbs with a reason. Each added control gives more signal and more to build, test and keep in the interface. Follow the project's existing choice if there is one.
- What AI disclosure wording? A persistent label, a one-time notice, or a per-message tag. Plain "AI-generated" wording builds trust but may reduce use; softer wording risks misleading users, and some places require a disclosure. Follow the project's existing choice if there is one.

## Checks
- Does the user see a loading state or stream within a moment of sending, and can they stop it?
- Is partial output never shown as complete structure, such as a half-formed link or table?
- Does every citation point to a source that was actually retrieved, not one written by the model?
- Does the interface say so when there is no source or the system is unsure, in plain words?
- Do regenerate, edit and feedback work as designed, with the earlier answer still reachable?
- Is each feedback record linked to the trace of the response it rates?
- Do failure messages tell the user what to do next, with no raw errors or internal details?
- Is a refusal shown with its own message, apart from an error?
- Is it clear to the user that the content or chat is AI, wherever it appears?

## Related skills
- `shipwright:ai-llm-calls`: streaming, stream errors and finish reasons, refusals included.
- `shipwright:ai-guardrails`: filtering output before it is shown, and safe fallbacks.
- `shipwright:ai-observability`: traces that feedback is linked to.
- `shipwright:ai-rag`: grounding and the sources that citations point to.
- `shipwright:ai-security-privacy`: personal data in feedback and in output.
