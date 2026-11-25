---
name: verifying-work
description: Use after the last task and its review are done, before finishing the branch, to run the plan's whole Acceptance checklist against the real thing and loop until it passes or you must stop.
---

# Verifying Work

After implementing, you test the feature or the fix yourself, check the logs, and do whatever else is needed to be sure it works. Every case decided during planning must be handled. If anything fails, or does not behave according to the requirement, you iterate (fix, then verify again) until it works.

This adds to `shipwright:test-driven-development` and `shipwright:verification-before-completion`; it does not replace them.

## 1. Read the checklist

Read the plan's `## Acceptance checklist`. Each line has the form:

`- [ ] <case> — verify: <test | live run | log check> — <how>`

A decided case with no line, or a plan with no checklist: build the lines from the spec's decided cases and show them to the developer before you run anything. Never drop a case.

## 2. Run the real thing, the project's way

Start the app, service, CLI or job as the project does. Exercise it through its real interface (API call, CLI command, UI via browser automation when available), then read the logs and traces it produced. When something it needs can't run locally, such as a service or credentials, ask the user how to run it rather than skipping the check.

Discover how from the project itself: its README, CLAUDE.md, package scripts, Makefile, compose files and CI config. Never assume a stack.

Databases: a real or shared one (production, staging, shared dev) is read-only, reached only through a read-only user or connector, and never with the project's `.env` or app credentials. A local or test database may be written to.

Run every line, record the result next to it (command, output, log excerpt), and tick it only on evidence you saw in this run.

## 3. For bugs

Reproduce the failure first, before the fix, then show it passing after the fix.

## 4. Failure means another loop

Find the root cause with `shipwright:systematic-debugging`, fix, then re-run the **whole** checklist, not just the failed line, to catch regressions.

## 5. Guardrails on "fix it anyhow"

- Never make a check pass by weakening, skipping or deleting a test.
- Never loosen an acceptance case, or silence or hide an error.
- Changing what counts as "working" is a requirements change, so it stops and asks.

## 6. Stopping rule

After **3 failed fix attempts on the same problem**, stop. Show the developer what failed, what was tried, the evidence gathered (output, logs, traces) and the best current theory, then continue with their input.

## 7. Keep what the live check found

When a live check catches a problem, also add an automated test for it where you can, so the finding can be re-run.

## 8. Fixes made here

Fixes made during verification come after the final review. Record each in the plan's ledger. Under `shipwright:subagent-driven-development`, each also gets a scoped re-review like a fix round, before finishing.

## Result

Report each checklist line with its result and evidence. A line that failed or was not run stays unticked with the reason. `shipwright:finishing-a-development-branch` and `shipwright:writing-pr-descriptions` use this report.
