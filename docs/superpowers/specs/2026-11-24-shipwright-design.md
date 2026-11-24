# Shipwright — design (approved 2026-11-24)

**Date:** 2026-11-24
**Status:** Approved by the user on 2026-11-24. Claude's calls stand as written. Decisions, open questions and progress are tracked in `docs/tracker.md`. The questions must be answered before the plan is written.

## 1. Intent

The team, plus Claude, needs one development workflow that works in **any project, whatever the tech stack**. Claude takes the requirements and does the work. A developer watches and approves in Claude Code. The work must follow the project's coding standards, the user's requirements, edge cases, recorded trade-offs and optimisation concerns.

## 2. What the user asked for (their requirements, condensed)

### 2.1 New feature
1. **Understand before building.**
   - Read the requirements, then the existing codebase, and learn how work is done in that project.
   - Ask questions wherever information is missing. Clear every doubt and assume nothing.
   - Rely on evidence. Do not always agree with the user: if they forget something the project already decided, show it to them.
   - Proceed on an assumption only after the user confirms it.
   - Understand trade-offs. When there are several ways to build it, recommend one, explaining why.
2. **Plan.**
   - A concrete, detailed implementation plan made of small tasks. Each task covers everything it needs, including test cases and edge cases.
   - The user may review the plan, or it can be approved automatically.
   - Tasks run in parallel across multiple agents where possible, otherwise one after another.
3. **Commit and PR.**
   - If committing is permitted, commit properly on the planned branch.
   - If not, give the user the commit message and which changes go in which branch.
   - Help the user create the PR, with a proper title and description.

### 2.2 Existing feature: something broke
1. If observability tooling exists, check it for the reported issue.
2. Otherwise, check the logs if there are any.
3. Otherwise, try to reproduce the issue.
4. If it still can't be reproduced, work with the developer and ask for every necessary detail, including minor ones.
5. Read the database if possible. If there is no access, ask the user for **read-only** access. If they refuse, carry on without the database.
6. Explain the whole scenario in very simple terms, along with an easy fix.
7. After the user approves the fix, implement it under the same conditions as a new feature (§2.1 steps 2-3).

### 2.3 Who uses it, and how they watch (answered 2026-11-24)
- **Users:** the user, their team, and Claude.
- **Watching the work:** the team monitors and approves inside Claude Code, in an interactive session. This is not an unattended CI pipeline.
- **Tickets:** Shipwright has no ticket or status integration (decided 2026-11-24). Tickets stay with other devs and managers.

### 2.4 Coding standards (answered 2026-11-24)
- **The user's rule, in order:**
  1. If coding standards are defined in **any** file in the project, follow them.
  2. Otherwise, follow the project's existing code patterns.
  3. If the code is not well managed, so there is no consistent pattern to follow, **flag that to the user** and follow industry standards.
- **Proposed edge-case defaults (to confirm):**
  - **Written standard vs. existing code:** the written standard wins for new code. Flag the mismatch, and do not rewrite existing code unless that is asked for.
  - **"Industry standards":** the language's or framework's official style guide, plus any linters or formatters already configured in the repo.
  - **When to flag:** once, at the start of work in a project, with the evidence (files and examples), not again on every task.

### 2.5 Recorded decisions (answered 2026-11-24)
- Projects have no older decision log. Going forward, the user creates documentation in the project's `docs/` folder whenever work starts.
- **Shipwright behaviour (proposed):**
  - Before new work, read the project's `docs/` and cite any earlier decision that bears on the request. This is the evidence for pushback.
  - Write its own specs and plans into `docs/`, with every decision the user confirms recorded in them.
- **Answered (Q4a):** clients do not want docs in their repo. Docs location is therefore a per-project setting:
  - **Client repo:** docs are local and git-excluded.
  - **Repo that allows docs:** durable decisions (specs, bug write-ups) are committed.
  - **Working files:** progress notes, drafts and notes containing production data always stay local.
- **Answered (Q4b):** yes, share decisions across the team, but not through an extra repo per project. Shipwright gets a **shared document module** (design to follow).
- **Storage mode is the user's choice (decided 2026-11-24).** On first use in a project, Shipwright asks where docs should live, then follows that choice:
  1. **In repo:** committed and versioned with the code. For technical teams that want docs reviewed alongside code.
  2. **Local only:** git-excluded. For client repos that forbid docs.
  3. **Shared doc tool:** decisions live in a wiki, so they are shared without touching the repo.
- **Proposed details (to confirm):**
  - It asks **once per project** and remembers the answer. The developer can change it at any time.
  - **Where the choice is stored:** in a local, git-ignored config, except in in-repo mode, where it can be committed so the whole team shares it.
  - **Working files** (progress notes, data-bearing investigation notes) stay local in every mode.
- **Shared doc tool (Q4c, answered 2026-11-24):** Shipwright must work with any doc tool. Proposed approach:
  - **Bring your own connector.** Shipwright uses the doc connector (MCP server) the user already has installed for Confluence, Notion, Google Docs and so on. It ships none of its own and never handles their credentials.
  - **It needs four operations from the connector:** search, read, create and update a page. On first use it lists the connectors it can see, asks which one and which space or folder to use, and remembers the answer with the storage mode.
  - **No connector:** it says so, and offers mode 1 or 2 instead.
  - **One real connector is tested first**; others follow the same four operations.

### 2.6 Plan approval (answered 2026-11-24)
- **Per-project setting:** `review` or `auto`. The proposed default is `review`.
- **Risky work is never auto-approved.** Even in `auto` mode, a plan with any risky task stops for a human. Shipwright says which tasks are risky and why.
- **"Risky" (confirmed 2026-11-24):**
  1. database schema changes, data migrations or backfills
  2. deleting or overwriting data or files outside the feature
  3. authentication, authorisation, permissions, secrets or security settings
  4. money: payments, billing, pricing
  5. a change to a public API or contract that other systems call
  6. infrastructure, deployment or CI configuration
  7. adding or upgrading dependencies
  8. anything irreversible or touching production
  9. a plan that touches the project's recorded "do not change" areas, if the project lists any

### 2.7 Commit permission (answered 2026-11-24; clarified)
- **The rule is about the final commits, when the work is done.** It is not about git use inside the build.
- **Developer agrees to the agent committing in their name:** Shipwright commits on the planned branch **and may push**. There is one switch covering commit and push.
- **Developer does not agree** (the default): Shipwright never runs `git add`, `git commit` or `git push` on the developer's branches. When the work is done, it hands over:
  - the branch order, if the work spans several branches;
  - for each branch: the files to stage and a commit message in the project's format;
  - the PR title and description.
- **Private scratch git state during the build is allowed** (Q9, answered 2026-11-24). For example: a detached worktree, or hidden scratch snapshots used for per-task reviews and parallel workers. All of it is removed before handover. The developer's branches, history and staging area are left exactly as they were, apart from the final commits when those are allowed.
- **Enforcement:** a PreToolUse hook blocks commits on named branches, pushes and branch creation when the switch is off. Scratch operations stay allowed. Instructions alone are not enough.
- **Claude's calls (correct if wrong):**
  - **The switch belongs to each developer, never the project.** A commit carries a person's name, so the setting lives only in that developer's local, git-ignored config, even in in-repo docs mode. Default: off.
  - **Commits use the developer's own git identity.** Whether to add an AI co-author line follows the project's commit conventions. If the project has none, Shipwright asks the developer once.

### 2.9 Decisions during the build (Q10, answered 2026-11-24: split)
- **Requirements and planning:** ask about everything open. Assume nothing; this is where "assume nothing" applies in full.
- **During the build, stop and ask only when** the issue would change *what* gets built (the requirements or agreed scope), or touches one of the 9 risky categories in §2.6.
- **Everything else:** Shipwright decides, records the decision with its reason and what it costs if wrong, and keeps going. Every recorded decision is listed in the end-of-work summary for the developer to review, and is appended to the spec's completion summary (§4.3).
- **Auto-approved plans follow the same rule:** auto-approval never removes a stop for requirements or risky issues.

### 2.8 Observability and logs (answered 2026-11-24)
- Platforms differ by project, so Shipwright **detects by itself** whether any observability is integrated. No platform gets priority (user's correction, 2026-11-24).
  1. **Detect.** Look at the connectors installed in Claude Code, and at the project itself: dependencies and SDK imports for tracing, errors or metrics, config files and docs.
  2. **Found something:** say which platform it found, and where, then use it. No question is needed.
  3. **Found nothing:** ask the user whether the project has observability and how to reach it, with links, exports or read-only API access. If there is none, fall back to logs, then to reproducing the issue (design §2.2).
  4. **Read-only, always:** query traces, errors and logs; never write, annotate or delete.

### 2.10 Verification loop after implementation (added 2026-11-24)
- **The user's requirement:**
  - After implementing, the agent tests the feature or the fix **itself**, checks the logs, and does whatever else is needed to be sure it works.
  - It confirms that every case decided during planning is handled.
  - If anything fails, or does not behave according to the requirement, it iterates (fix, then verify again) until it works.
- **Proposed shape (Claude's calls; correct if wrong):**
  1. **Acceptance checklist from the spec.** Every decided case becomes a line saying how it is verified: an automated test, running the real thing and observing the result, or a log or trace check.
  2. **Run the real thing, the project's way.** Start the app, service, CLI or job as the project does. Exercise it through its real interface (API call, CLI command, UI via browser automation when available), then read the logs and traces it produced. When something it needs can't run locally, such as a service or credentials, ask the user how to run it rather than skipping the check.
  3. **For bugs:** reproduce the failure first, before the fix, then show it passing after the fix.
  4. **Failure means another loop:** find the root cause (the debugging flow), fix, then re-run the **whole** checklist, not just the failed line, to catch regressions.
  5. **Guardrails on "fix it anyhow":**
     - Never make a check pass by weakening, skipping or deleting a test.
     - Never loosen an acceptance case, or silence or hide an error.
     - Changing what counts as "working" is a requirements change, so it stops and asks (§2.9).
  6. **Stopping rule (Q12, answered 2026-11-24):** after **3 failed fix attempts on the same problem**, stop. Show the developer what failed, what was tried, the evidence gathered (output, logs, traces) and the best current theory, then continue with their input. This reuses superpowers' existing "3+ failed fixes, so question the approach" rule.
  7. **Relation to superpowers (Claude's call):** this adds to `test-driven-development` and `verification-before-completion` rather than replacing them. When a live check catches a problem, Shipwright also adds an automated test for it where it can, so the finding can be re-run.

## 3. Goals, non-goals, anti-goals (approved with the design)
- **Goals:** stack-agnostic; installable by the whole team as one unit; enforces the commit rule rather than only hoping it is followed; leaves an audit trail the team can read (plan, decisions, review results).
- **Non-goals (proposed):** unattended ticket-to-PR automation; replacing the project's own CI.
- **Anti-goals (proposed):**
  - The agent writes to a **real or shared** database (production, staging, shared dev).
  - The agent commits or pushes without permission.
  - The agent silently overrides a recorded project decision.
  - The agent "fixes" a bug before its root cause is shown.

## 4. Approaches and choice (decided 2026-11-24: B, fork superpowers)

| Option | What it means | Trade-off |
|---|---|---|
| A. Thin layer on superpowers | Shipwright adds only the gaps and requires superpowers to be installed | Least to build, but its rules must override superpowers' instructions in many places |
| **B. Fork superpowers into Shipwright (chosen)** | Copy superpowers 7.0.2 (MIT licence) and change its skills directly to match the rules in §2 | Full control and a single install. We maintain the skills and must merge upstream fixes by hand |
| C. From scratch | Write every skill and agent ourselves | Most work; re-solves problems superpowers already handles |

**Why B and not A** (evidence from superpowers 7.0.2):
- 13 of its 15 skills assume Claude commits.
- The subagent-driven review mechanism is built on commit ranges (`scripts/review-package` takes BASE..HEAD).
- 3 skills hard-code `docs/superpowers/...` paths, which conflicts with the docs storage modes in §2.5.
- Overriding all of that from a second plugin would mean two sets of instructions fighting, and the commit-based review scripts need code changes, not just instructions.

### 4.1 Fork scope (proposed)
- **Keep and adapt:** brainstorming, writing-plans, subagent-driven-development, dispatching-parallel-agents, executing-plans, test-driven-development, verification-before-completion, requesting-code-review, receiving-code-review, systematic-debugging, finishing-a-development-branch, using-git-worktrees, using-superpowers (renamed using-shipwright).
- **Drop:**
  - writing-skills and diagnosing-superpowers: these are tools for maintaining a plugin, not for project work;
  - the non-Claude harness folders: `.codex-plugin`, `.cursor-plugin`, `.devin-plugin`, `.hermes-plugin`, `.kimi-plugin`, `.muse-plugin`, `.antigravity-plugin`, `.opencode`, `.pi`, `.agents`;
  - `GEMINI.md` and `gemini-extension.json`.
- **Licence:** keep superpowers' MIT copyright and permission notice (required). Record the forked version (7.0.2) in `UPSTREAM.md`, together with how to check upstream release notes and pick up fixes.
- **Running alongside superpowers:** both plugins carry skills with the same names and triggers. Teammates disable superpowers in projects where Shipwright is on. The README says so.

### 4.2 Components (proposed; the builder refines)
- **Per-project settings:** one file, written by the onboarding skill. It holds the docs storage mode, the wiki connector with its space or folder, plan approval (`review` | `auto`), and the observability platform found.
  - In mode 1 (in repo) the file is committed. Otherwise it is local and git-ignored.
  - The **commit-and-push switch is not stored here.** It sits in each developer's own local config (§2.7).
  - Defaults: plan approval `review`; commit-and-push off.
- **New skills:**
  - **project onboarding:** first use in a project. Asks for the docs mode and connector, plan approval, and this developer's commit-and-push consent; detects observability and standards; writes the settings file.
  - **investigate:** the §2.2 bug flow: observability → logs → reproduce → interview → read-only DB → plain-language explanation → approved fix through the normal plan and build.
  - **PR write-up:** title and description covering requirements, decisions, trade-offs, tests and risks.
- **Adapted skills:**
  - **brainstorming:** adds the coding-standards ladder (§2.4) and the decision lookup with evidence-based pushback (§2.5). Docs are written through the storage mode.
  - **writing-plans:** tags every task with the §2.6 risky categories. Auto-approve applies only when no task is risky. Commit steps appear only when commits are allowed.
  - **subagent-driven-development:** review packages come from working-tree diffs when commits are not allowed. Parallel lanes are allowed when tasks share no files.
  - **finishing-a-development-branch:** when commits are not allowed, it hands over the branch order, the files and commit message for each branch, and the PR write-up.
- **Enforcement (hooks plus permission rules):** a PreToolUse hook reads the developer's commit-and-push switch. When the switch is off, it denies commits on named branches, pushes and branch creation, while still allowing private scratch git state (§2.7). A SessionStart hook injects a short summary of the settings.
- **Agents:** implementer, task reviewer, final reviewer, and an investigator agent whose tools are read-only (no Edit, Write or state-changing Bash).
- **Database access (Q11, answered 2026-11-24):**
  - **Real or shared databases** (production, staging, shared dev): read-only, only through a read-only user or connector. Shipwright never uses the project's `.env` or app credentials for them, never asks for write credentials, and continues without the database if access is refused. The investigator agent's tool limits are added on top.
  - **Local and throwaway test databases:** writes are allowed. This covers the project's test suite and seeding data to reproduce a bug.

### 4.3 Calls made after the builder check (Claude's calls; correct if wrong)
- **Durable versus working artifacts:**
  - **Durable** (stored by the docs storage mode): the spec with its decisions, bug write-ups, and a short completion summary appended to the spec (what was built, any rulings, the review verdict).
  - **Working** (always local, removed when the work finishes): the plan's progress ledger, review packages, scratch notes.
  - The plan file stays on disk while it runs. Afterwards it is kept with the spec only in in-repo mode.
- **Shared doc tool mode is one-way publishing.** The local markdown is the master copy. Shipwright creates or updates the wiki page from it and never edits pages back from the wiki. Before updating a page it checks whether someone else changed it since the last publish; if so, it stops and shows the user, rather than overwriting.
- **Multiple branches:**
  - The default is one branch.
  - A per-project setting can cap PR size (e.g. 1,000 non-test lines). The plan then cuts tasks into a stack of branches.
  - The plan must not put the same file in two branches.
  - Each branch must pass tests on its own, in stack order.
- **Permission rules:** a plugin can ship hooks, but probably cannot ship permission rules (to be verified in the plan). The PreToolUse hook is therefore the enforcement Shipwright ships. Onboarding offers to add matching deny rules to the developer's local settings.

## 5. Platform facts relied on (from code.claude.com, 2026-11-24)
- **Plugin layout:** `.claude-plugin/plugin.json`, plus `skills/<name>/SKILL.md`, `agents/*.md`, `hooks/hooks.json`, `.mcp.json`.
- **Subagents:** run in parallel (default limit 20). Each can be restricted to certain tools (`tools` / `disallowedTools`) and a `model`.
- **PreToolUse hooks:** can deny a Bash command such as `git commit` / `git push`. The docs call hooks a guardrail and recommend permission rules for hard limits.
- **Permissions:** `allow` / `ask` / `deny` in settings.json are evaluated deny-first.
- **Team distribution:** a git repo with `.claude-plugin/marketplace.json`, then `/plugin marketplace add`, then `/plugin install <plugin>@<marketplace>`.
  - Project settings `enabledPlugins` enables the plugin for a repo, but each teammate still installs it once.
  - **Unverified:** the exact `extraKnownMarketplaces` JSON, and whether teammates are prompted automatically when they trust the repo.

## 6. Open questions
Tracked in `docs/tracker.md` (Open questions table), so they live in one place.

## 7. Left to the builder
- Exact names and the format of the settings file.
- Hook implementation language. It must run on macOS, Linux and Windows without project-specific runtimes.
- How each forked skill's text is reworded, as long as the §2 rules hold.
- The eval cases for each skill (`claude plugin eval`).

## 8. Next step
Builder check of this document, then user approval, then the implementation plan.
