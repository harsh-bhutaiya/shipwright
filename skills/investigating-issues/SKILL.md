---
name: investigating-issues
description: Use when something in an existing feature broke or misbehaves and the cause is unknown, before proposing any fix
---

# Investigating Issues

Something that used to work is broken. Find out why, explain it simply, and only then fix it.

Use `shipwright:systematic-debugging` for the root-cause discipline. No fix is proposed before the root cause is found.

## Read-only rules

- Observability, logs and databases are read-only. Query; never write, annotate or delete.
- Real or shared databases (production, staging, shared dev) are reached only through a read-only user or connector that the developer grants. Never open, cat or grep the values in `.env*` or any credential file, and never run the app, its tests or scripts that would connect to a real or shared database with app credentials. Never print secret values. Local and test databases may be written to.

## Delegating the evidence gathering

Connector steps stay in this session: check observability through its MCP connector (step 1) and read the database through the developer's read-only connector (step 5) yourself, read-only. A subagent cannot see MCP connectors.

The `shipwright:investigator` agent is read-only and gathers the rest: code, config, logs (step 2) and reproduction (step 3), plus observability that does not need a connector (SDKs, config). It is undocumented whether a skill can dispatch a plugin agent. Try it. If it cannot be dispatched, dispatch a general-purpose subagent and give it the full text of `agents/investigator.md` as its instructions. If no subagent tool exists, do the steps yourself under the same rules.

## The flow

1. If observability tooling exists, check it for the reported issue.
2. Otherwise, check the logs if there are any.
3. Otherwise, try to reproduce the issue.
4. If it still can't be reproduced, work with the developer and ask for every necessary detail, including minor ones.
5. Read the database if possible. If there is no access, ask the user for **read-only** access. If they refuse, carry on without the database.
6. Explain the whole scenario in very simple terms, along with an easy fix.
7. After the user approves the fix, implement it under the same conditions as a new feature (§2.1 steps 2-3). Those steps are: plan, then commit and PR; the Step 7 addition below names the skills.

Additions to the steps:

- Step 1: detect observability as described below. Do not edit code before step 7.
- Step 3: actually attempt a reproduction with read-only commands before saying you cannot. Say what you tried.
- Step 4: ask specific questions (exact inputs, which users or accounts, when it started, what changed), each with a short reason. When you end your turn on a question, combine it with the step 5 request.
- Step 5: ask for a read-only user or connector. Never ask for write credentials, and never use the project's `.env` or app credentials.
- Step 6: if `docs_mode` is empty, run `shipwright:onboarding` first. Then write it up at `<docs_dir>/investigations/YYYY-MM-DD-<topic>.md` (`"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get docs_dir`, default `docs`). If `docs_mode` is `shared-tool`, publish it with `shipwright:publishing-docs`.
- Step 6, production data: the write-up describes the data's shape (fields, types, counts) and the scenario, never real records, values, identifiers or secrets. Redact before writing or publishing. Keep data-bearing notes (rows, IDs, log lines with personal data) in `.shipwright/work/`, never in the write-up.
- Step 7: the path is `shipwright:writing-plans`, then `shipwright:subagent-driven-development` or `shipwright:executing-plans`, then `shipwright:verifying-work`, then `shipwright:finishing-a-development-branch`. The write-up plays the spec's role for all of them: writing-plans builds the acceptance checklist from it, and finishing appends the completion summary to it.
- Report each step's outcome as you go, including empty ones ("no observability found", "no logs").

## Detecting observability

Platforms differ by project, and no platform gets priority. Read `"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get observability` first: onboarding may already have recorded it. Otherwise detect from:

- dependencies and SDK imports for tracing, errors or metrics;
- config files and docs;
- env var **names** (never their values) and docker-compose services;
- MCP connectors visible in this session (check these yourself; the investigator cannot see them).

**Found something:** say which platform and where, then use it. No question is needed.
**Found nothing:** say so plainly ("no observability found"), then ask the developer whether the project has any and how to reach it: links, exports or read-only API access. If there is none, go to step 2.
