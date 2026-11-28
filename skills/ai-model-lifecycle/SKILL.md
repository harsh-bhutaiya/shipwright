---
name: ai-model-lifecycle
description: Use in a project that calls LLMs, when choosing a model, pinning or upgrading a model version, migrating to a new or deprecated model, changing model or prompt config, or planning how an AI change is released, rolled out or rolled back.
---

# Model and Prompt Lifecycle

This covers choosing, pinning and migrating models, and releasing AI changes. A silent model swap or an unmeasured rollout changes behaviour for every user at once.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Choose a model on capability, context size, cost, latency, modality and data policy. Write down why it was chosen, so a later migration knows what to preserve.
- [practice] Benchmark candidate models on the project's own evals, not on public leaderboards. A leaderboard does not measure your task. See `shipwright:ai-evaluation`.
- [practice] Weigh open-weight and self-hosted models on their own trade-offs:
  - control, data residency and per-token cost at scale;
  - against the operating burden: GPUs, serving, scaling, upgrades and security patches;
  - weaker capability or tooling is possible, so measure it on your evals.
- [reliability] Pin every model to a dated snapshot, never a floating alias. An alias changes behaviour without a code change. Check the ID against the provider's current docs, not memory.
- [practice] Record each pinned model's deprecation date and watch it. Schedule the migration before the date, not after the failure.
- [practice] Migrate a model in this order:
  1. run the evals on the new model;
  2. diff the results against the old model, per case, not only the average;
  3. re-tune prompts for the new model and run the evals again;
  4. release by the project's rollout method.
- [practice] Keep prompt and model config (model ID, parameters, prompt version) versioned separately from code, so each can change, be compared and be rolled back on its own. Prompt versioning in code is owned by `shipwright:ai-prompt-engineering`.
- [practice] Release an AI change behind a control that can be turned off: a feature flag, canary, shadow run or A/B test. Have a rollback that restores the previous model and config without a deploy.
- [security] Use separate dev, staging and production keys. Where the keys are kept is owned by `shipwright:ai-security-privacy`.
- [reliability] Evals passing is the release gate for a model or prompt change. See `shipwright:ai-evaluation`, which owns the eval gate.
- [reliability] Model calls go through the provider abstraction, so a model change is a config change. See `shipwright:ai-llm-calls`.

## Ask the developer
- Which model (capability, cost, latency, modality, data policy)? A stronger model costs more and is slower; a smaller one is cheaper and faster but may fail harder cases; modality and data policy can rule options out. Decide from your own evals. Follow the project's existing choice if there is one.
- Open-weight or self-hosted? A hosted model is simplest to run; open-weight or self-hosted gives control over data and cost at scale, at the price of operating it. Follow the project's existing choice if there is one.
- Rollout method (flags, canary, shadow, A/B)? Flags switch fast and roll back at once; a canary limits the users at risk; shadow runs the new model on live traffic without showing it; A/B compares outcomes but needs traffic and time. Follow the project's existing choice if there is one.

## Checks
- Is every model pinned to a dated snapshot, with no floating alias?
- Is each model's deprecation date recorded, with a migration scheduled before it?
- Was the model chosen from the project's own evals, not a leaderboard?
- Does a migration plan run the evals, diff the results per case and re-tune prompts?
- Are prompt and model config versioned separately from code?
- Can the change be turned off, and rolled back to the previous model and config without a deploy?
- Are there separate dev, staging and production keys?
- Do the evals pass before release?
- For an open-weight or self-hosted model, is the operating cost and burden planned?

## Related skills
- `shipwright:ai-evaluation`: the eval gate, and the evals that compare models.
- `shipwright:ai-prompt-engineering`: prompt versioning in code and re-tuning prompts.
- `shipwright:ai-llm-calls`: the provider abstraction that makes a model swap a config change.
- `shipwright:ai-security-privacy`: keys and secrets.
