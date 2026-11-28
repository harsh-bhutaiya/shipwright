---
name: ai-evaluation
description: Use in a project that calls LLMs, when defining success criteria or metrics for an AI feature, building or changing an eval set, writing graders or an LLM judge, changing a prompt or model, setting up evals in CI, or verifying or debugging a bad model answer.
---

# Evaluation

Evals measure whether model output meets the spec's success criteria. They are the gate for every prompt and model change, so their integrity decides whether any other claim about quality can be trusted. This skill is the canonical text for the eval gate, eval integrity and the N-runs rule.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Metrics come from the spec's success criteria. Each criterion maps to a metric with a threshold. A criterion with no metric is flagged, not skipped.
- [practice] Build the eval set from several sources:
  - golden answers;
  - edge cases;
  - adversarial cases;
  - production samples.
- [practice] Version the eval set. Review changes to it as you review code.
- [practice] Split the eval set into a dev part and a held-out set. Iterate on the dev part only; use the held-out set to confirm.
- [security] Eval datasets holding confidential data are never committed. Keep them in access-controlled storage and commit only a loader or a reference. Personal data in datasets is redacted before it enters the set. See `shipwright:ai-security-privacy`.
- [practice] Use the cheapest grader that is reliable:
  - code checks (exact match, regex, schema) first;
  - an LLM judge for what code cannot check;
  - human review for what the judge cannot settle, and to calibrate the judge.
- [practice] An LLM judge has a written rubric and is calibrated against human labels. Report its agreement with them.
- [practice] The judge model differs from the generator model. Check for judge bias: position, length, and preference for its own family's output.
- [practice] Model output is nondeterministic, so run each case N times and report the pass rate against a threshold. One run is never a result. The rule holds whenever a skill or plan cites an eval result.
  - Choose N from the variance and the budget. Record N with the result.
  - Report the pass rate and the spread, not the best run.
- [practice] Evaluate at the level where the fault would show:
  - per component (retrieval, tool choice);
  - end to end;
  - agent trajectory (steps taken, tools called, stop reason).
- [practice] Offline evals gate changes. Online evals watch production: sampled production traffic, shadow runs of a candidate, A/B. See `shipwright:ai-observability` for production samples.
- [practice] Track latency, cost, refusal rate and format-failure rate next to quality, with thresholds. A quality gain that breaks one of them is a regression.
- [reliability] Eval integrity. When a result is below the bar:
  - never lower a threshold;
  - never edit golden answers or the judge to fit;
  - never tune on the held-out set;
  - never cherry-pick runs.
  - Fix the prompt, model or code, or tell the developer the bar was not met. Changing a threshold, a golden answer or the judge is a decision for the developer, made on stated grounds, never to turn a run green.
- [practice] Feed production failures back into the dev part of the eval set, redacted, with the expected answer agreed by the developer.
- [reliability] Every prompt change and every model change passes the eval gate before it ships: run the eval set N times and compare with the baseline on the same set, judge and N. Treat a model version bump as a model change. A change with no passing run is not done.
- [practice] Beyond the gate, when evals run (in CI on every commit, on prompt or model change only, on a schedule, or a cheap subset per commit with the full set on a schedule) is the developer's choice; see Ask the developer. State what a run costs (calls, tokens, time) and keep it inside the budget they set.
- [practice] Mocks and recorded fixtures in the unit suite test code paths, not model quality; evals test quality. Never use one in place of the other. See `shipwright:ai-testing`.

## Ask the developer
- Metrics and thresholds? Options are the spec's criteria turned into pass rates, plus latency, cost, refusal and format-failure limits. A high bar blocks changes more often; a low bar lets regressions through. Follow the project's existing choice if there is one.
- Dataset sources? Options are hand-written golden answers, edge and adversarial cases, and redacted production samples. Production samples are the most realistic but need redaction and an access decision; hand-written sets are safe but drift from real use. Follow the project's existing choice if there is one.
- Grader types and judge model? Code checks are cheap and exact but narrow; an LLM judge covers open-ended output but costs more and needs calibration; human review is the reference but slow. The judge must differ from the generator. Follow the project's existing choice if there is one.
- Number of runs? More runs give a steadier pass rate and cost more per eval. Follow the project's existing choice if there is one.
- Online method (sampling, shadow, A/B)? Sampling is cheap and passive; shadow runs test a candidate on real traffic with no user impact at double the cost; A/B measures user effect but exposes users to the candidate. Follow the project's existing choice if there is one.
- When evals run in CI, and their budget? Every commit catches regressions early and costs the most; on prompt or model change only is cheaper but misses indirect breaks; a schedule is cheapest and slowest to catch. Follow the project's existing choice if there is one.

## Checks
- Does every success criterion in the spec map to a metric with a threshold?
- Does the eval set include golden, edge-case, adversarial and production-sample cases, and is it versioned?
- Is there a held-out set, and was it left out of tuning?
- Is personal data redacted in the eval set, and is confidential data kept out of the repo?
- Is the judge model different from the generator, with a rubric and a calibration against human labels?
- Does each reported result state N and the pass rate, not a single run?
- Does the diff leave every threshold, golden answer and judge prompt unchanged, unless the developer approved the change?
- Does every prompt or model change have a passing eval run against the baseline?
- Are latency, cost, refusal rate and format-failure rate tracked?
- Do production failures flow back into the eval set?
- Is it stated when evals run in CI beyond the gate, as the developer chose, and what they cost?

## Related skills
- `shipwright:ai-testing`: mocks, fixtures and fault injection in the unit suite, as distinct from evals.
- `shipwright:ai-observability`: production samples and traces that feed online evals and the dataset.
- `shipwright:ai-security-privacy`: redaction and handling of personal and confidential data in datasets.
- `shipwright:ai-model-lifecycle`: model migration and rollout, which rely on the eval gate here.
- `shipwright:ai-prompt-engineering`: prompt changes that must pass the gate.
