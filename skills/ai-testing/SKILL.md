---
name: ai-testing
description: Use in a project that calls LLMs, when planning or writing tests for code that calls a model: mocking the model client or recording its responses as fixtures, testing its retries, fallbacks, parsing or streaming, or deciding whether a check belongs in the unit suite or in an eval.
---

# AI Testing

Tests prove that your code handles what a model returns, including its failures. They are fast, deterministic and free. Whether the model gives good answers is a different question, answered by evals. This skill owns the line between the two.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Tests check your code, evals check the model's answers. A test passes or fails the same way every run. A question about answer quality ("is the summary good?") is an eval, not a test. See `shipwright:ai-evaluation`.
- [practice] Unit tests use a mocked model client, replaced at the provider abstraction. The mock returns what the test scripts, so the test exercises your code and nothing else.
- [practice] No real LLM calls in the unit suite. A real call is slow, costs money, needs a key and gives a different answer each run. Anything that needs a real call is an eval or an opt-in integration test, kept out of the default run.
- [practice] Record real responses once and replay them as fixtures, so the mock returns what a real model returned.
  - Record errors and streams too: rate-limit errors, refusals, truncated outputs, and streamed chunks in their real order.
  - Re-record when the model or the prompt changes, and review the diff. A stale fixture hides a break.
- [security] Strip secrets and personal data before a fixture is saved. A fixture holding real user data is never committed: real data in git stays in its history after the file is deleted.
- [practice] Inject faults and assert the behaviour in each case:
  - rate limit (429) with and without a `retry-after` header;
  - timeout;
  - server error;
  - malformed JSON, or JSON that fails validation;
  - truncated output (length finish reason);
  - a stream that stops mid-way;
  - a refusal or an empty response.
- [practice] Write contract tests for the code around the call: parsing, validation (business rules included), retry (only retryable errors, capped, with backoff), and fallback. Fake the clock so backoff tests do not sleep.
- [practice] Snapshot-test the rendered prompt: the exact text sent after templates and variables are filled in. A change to a snapshot is reviewed as a prompt change, and a prompt change also passes the eval gate. See `shipwright:ai-prompt-engineering` and `shipwright:ai-evaluation`.
- [practice] Keep model output out of assertions where it varies. Assert on structure, on fields, and on what your code did with the result, not on exact wording a live model might change.
- [practice] Test tool code on its own, with arguments a model could send: missing, wrong type, out of range, hostile. The model is not in the loop for these.
- [practice] Test the failure path of each model call, not only the success path. A call with no test for a timeout and a bad response is untested.

## Ask the developer
- Where should fixtures live? Ask only if the project has no test layout of its own. Options: next to the tests that use them (easy to find and review, clutters test folders), or one shared fixtures folder (one place to re-record, harder to see which test owns which file). Follow the project's existing layout if there is one.

## Checks
- Does every unit test that touches a model call use a mock or a recorded fixture, with no real call?
- Is each recorded fixture free of secrets and personal data?
- Are there fault tests for rate limit, timeout, malformed output, truncated output and a broken stream?
- Do contract tests cover parsing, validation, retry and fallback, with no real sleeps?
- Are rendered prompts snapshot-tested, and does a snapshot change get reviewed as a prompt change?
- Is any question about answer quality in a unit test that should be an eval?
- Does each test pass or fail the same way on every run?

## Related skills
- `shipwright:ai-evaluation`: judging answer quality, eval sets, graders, the eval gate.
- `shipwright:ai-llm-calls`: the provider abstraction the mock replaces, and the retry and validation behaviour the contract tests cover.
- `shipwright:ai-prompt-engineering`: prompts as code, and versioning the prompts you snapshot.
- `shipwright:test-driven-development`: the red-green loop these rules plug into.
