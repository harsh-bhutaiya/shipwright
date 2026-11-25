# Shipwright tracker

The single place to see where the Shipwright build stands: decisions, open questions and progress. Update it whenever any of these change.

## Status

**Phase:** v0.2.0 built (Tasks 6-13); v0.1.0 is public
**Next:** The owner commits and opens the PRs, then "Try it on a real project"

## Decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-24 | Build it as a Claude Code **plugin** that the team installs from this repo's marketplace | A plugin is the only unit that bundles skills, agents, hooks and MCP servers and installs as one |
| 2026-11-24 | It must work for **any project and tech stack** | The team works across many projects |
| 2026-11-24 | The team watches and approves **interactively in Claude Code** | Not an unattended CI pipeline |
| 2026-11-24 | **No ticket or status integration.** Shipwright does not read or update Jira or any other tracker | User's call; tickets stay with other devs and managers |
| 2026-11-24 | **No status doc in target projects.** This tracker exists only for building Shipwright, because Shipwright itself has no Jira | User's call |
| 2026-11-24 | **Coding standards ladder:** (1) follow standards written in any project file; (2) otherwise follow the project's existing code patterns; (3) if the code is not well managed, flag it to the user and follow industry standards | User's call. Edge-case defaults in design §2.4 are proposed and still need the user's confirmation |
| 2026-11-24 | **Decision record = `docs/`.** Projects have no older decision log. Going forward, every piece of work gets documentation in the project's `docs/`. Shipwright reads `docs/` before starting work and writes its own specs and plans there | User's practice. Still open: whether `docs/` is shared with the team or kept local (Q4a) |
| 2026-11-24 | **Docs location is set per project.** In client repos, docs never go into the repo: they stay local and git-excluded. In repos that allow it, durable decisions can be committed. Working files are always local | Clients don't want docs in their repo |
| 2026-11-24 | **Shared team decisions: yes, but not via an extra repo.** Decisions should be visible to the whole team without a separate docs repo per project | An extra repo is too complicated; a shared document module is wanted |
| 2026-11-24 | **Docs storage mode: Shipwright asks.** On first use in a project it asks where docs live, then acts on the answer. The three modes: (1) **in repo**, committed and versioned with the code; (2) **local only**, git-excluded; (3) **shared doc tool**, such as a wiki | Technical teams want docs versioned with the code; clients forbid docs in their repo; some teams want sharing without the repo |
| 2026-11-24 | **Shared doc tool is tool-agnostic.** Shipwright works with whatever doc connector the user already has (Confluence, Notion, Google Docs, ...) and ships none of its own. One real connector is tested first | Teams use different doc tools |
| 2026-11-24 | **Plan approval is a per-project setting, and risky work is never auto-approved.** Even with auto-approve on, a plan that touches anything risky stops for a human | User's call |
| 2026-11-24 | **Commit permission (clarified):** the rule covers the final commits only. If the developer agrees to commits in their name, Shipwright commits **and pushes**. Otherwise it hands over the files to stage and a commit message for each branch. Default: not allowed. Private scratch git state during the build is fine. Enforced by a hook | User's clarification (Q9). Claude's call: the switch belongs to each developer and is never committed, because a commit carries a person's name |
| 2026-11-24 | **Observability: detect, don't presume.** Shipwright finds out by itself whether a project has any observability integrated. It asks the user only if it can't find any. No platform gets priority | User's correction: no platform is a priority target |
| 2026-11-24 | **Approach B: fork superpowers 7.0.2** into Shipwright and adapt its skills; keep the MIT notice | User's pick. Claude agreed after finding that 13 of 15 skills assume commits, its review scripts are commit-based, and 3 skills hard-code docs paths |
| 2026-11-24 | **Mid-build decisions: split.** Ask about everything during requirements and planning. During the build, stop only for issues that change what gets built or touch a risky category; decide and record everything else, then list it at the end | User's pick (Q10) |
| 2026-11-24 | **Databases:** never write to real or shared ones (production, staging, shared dev). Those are read-only, through a read-only user or connector only, and never with the project's `.env` credentials. Local and test databases may be written | User's pick (Q11) |
| 2026-11-24 | **Verification loop:** after implementing, Shipwright tests the real thing, reads the logs, and proves every decided case. On failure it fixes and re-checks the whole checklist. After 3 failed attempts on the same problem it stops and escalates with the evidence | User's requirement (design §2.10) and pick (Q12) |
| 2026-11-25 | **Personal project, published publicly** at `harsh-bhutaiya/shipwright`. Only the owner pushes; others fork and open PRs. The `protect-main` ruleset blocks force-push and deletion and requires a PR (0 approvals), with the owner on the bypass list. Secret scanning, push protection and private vulnerability reporting are on | Owner's decision; the owner also merges their own changes through PRs |
| 2026-11-25 | **Licence: MIT.** Superpowers' notice is kept and the owner's copyright line added. `.idea/` and `.DS_Store` are git-ignored, and `.idea/` is untracked | Owner's decision |
| 2026-11-24 | Name: **Shipwright** | Chosen from a shortlist; Keel was the runner-up |
| 2026-11-25 | **Release v0.1.0 = Milestone 1; Tasks 6-13 in v0.2+** | The user wants to publish today; Milestone 1 (forked skills, settings script, git guard, session-start hook, onboarding) is complete and reviewed |
| 2026-11-25 | **CI: tests and ShellCheck on every PR, with a results comment.** Tests run on Ubuntu and on macOS's bash 3.2; ShellCheck is pinned to 0.10.0, the IDE's version. A separate workflow comments, and it never runs PR code. Evals and `claude plugin validate` stay out of CI | Owner's call: evals need an API key and cost money; validate would need the Claude CLI in CI |

## Open questions

Answer one at a time, in this order. Full context is in `docs/superpowers/specs/2026-11-24-shipwright-design.md`.

| # | Question | Status |
|---|---|---|
| Q1 | Ticket tracker and status updates | ✅ Answered: no integration (see Decisions) |
| Q2 | Should Shipwright keep a status doc like this one inside each target project, to track each feature's progress there? | ✅ Answered: no (see Decisions) |
| Q3 | Where do coding standards live in each project (CLAUDE.md, a standards doc, linter configs)? | ✅ Answered: the standards ladder (see Decisions; design §2.4) |
| Q4 | Where does each project record its decisions, so the agent can push back with evidence? | ✅ Answered: `docs/` (see Decisions; design §2.5) |
| Q4a | Are those `docs/` files committed and shared with the team, or kept local to each developer? | ✅ Answered: client repos are local only (see Decisions) |
| Q4b | For client projects, should decisions be shared across the team in a separate team docs repo outside the client repo, or is local-only fine? | ✅ Answered: shared, but no extra repo (see Decisions) |
| Q4c | Which shared document tool does the team already use, as the home for shared decisions? | ✅ Answered: must work with any tool (see Decisions) |
| Q5 | Plan approval: who chooses auto-approve versus review, and is it per project, per task size or per developer? | ✅ Answered: per-project setting; risky work is never auto-approved (see Decisions) |
| Q5a | What counts as "risky"? Confirm or correct the proposed list in design §2.6 | ✅ Answered: the 9-item list is confirmed |
| Q6 | Commit permission default: allowed or not, per project or per developer? | ✅ Answered: per project, not allowed by default (see Decisions; design §2.7) |
| Q7 | Which observability and log tools does the team use, so we know which MCP servers to support first? | ✅ Answered: detected per project, ask the user only if none is found (see Decisions; design §2.8) |
| Q8 | superpowers — thin plugin on top, fork it, or build from scratch? | ✅ Answered: B, fork (see Decisions; design §4) |
| Q9 | With commits not allowed, may Shipwright use **private, throwaway git state** that the developer never sees (a detached worktree, hidden scratch commits deleted at handover)? | ✅ Answered: yes; the rule covers the final commits only (design §2.7) |
| Q10 | During the build, when something the plan doesn't settle comes up, does Shipwright **stop and ask**, or **decide, record it and report at the end**? | ✅ Answered: split (design §2.9) |
| Q11 | Does "never write to a database" cover **every** database, or only real and shared ones (production, staging, shared dev)? May Shipwright use the project's own DB credentials from env files? | ✅ Answered: real and shared databases only; no `.env` credentials for them (design §4.2) |
| Q12 | Verification loop (design §2.10): when should Shipwright stop iterating and escalate to the developer? | ✅ Answered: after 3 failed attempts on the same problem |

## Progress

- [x] Brainstorm: requirements captured, see design §2
- [x] Repo scaffolded: manifests and marketplace; `claude plugin validate` passes
- [x] Open questions Q1-Q8 answered
- [x] Design approved (2026-11-24)
- [x] Implementation plan written: `docs/superpowers/plans/2026-11-24-shipwright.md`, 13 tasks in 4 milestones
- [x] Build (v0.1.0 shipped 2026-11-25; v0.2.0 built, Tasks 6-13)
- [ ] Try it on a real project
- [ ] Team rollout

## Log

- **2026-11-24:**
  - Brainstorm started; repo created at `~/PycharmProjects/shipwright`.
  - Named it Shipwright.
  - Decided on no ticket integration.
  - Added this tracker.
  - Decided on no status doc in target projects.
  - Decided on the coding standards ladder.
  - Decided that `docs/` is the decision record.
  - Decided that docs location is set per project, with client repos local only.
  - Decided on shared team decisions without an extra repo.
  - Decided that Shipwright asks for the docs storage mode (in repo, local only, or shared tool).
  - Decided the shared doc tool is tool-agnostic.
  - Decided that plan approval is per project and risky work is never auto-approved.
  - Confirmed the risky list.
  - Decided that commit permission is per project and not allowed by default.
  - Decided that observability adapts per project.
  - Corrected: no platform priority. Detect first, ask only if nothing is found.
  - Removed the dead `$schema` URL from marketplace.json (it 404s; the field is optional).
  - Chose approach B (fork superpowers) and wrote the full design (§4.1 scope, §4.2 components).
  - Builder check: 5 gaps. Claude settled 2 (design §4.3); 3 are for the user (Q9-Q11).
  - Q9 answered. Commit and push are one per-developer switch, and scratch git is allowed during the build.
  - Q10 answered: split.
  - Q11 answered. All questions closed; the design is ready for approval.
  - The user added the verification-loop requirement (design §2.10) and Q12 opened.
  - Q12 answered: stop after 3 attempts. The design is ready for approval again.
  - The user approved the design, and implementation planning started.
  - Implementation plan written: 13 tasks in 4 milestones.
- **2026-11-25:**
  - Milestone 1 built and reviewed (Tasks 1-5).
  - Wrote the README (install, settings, consent, guard and its known limits), CHANGELOG and CLAUDE.md note.
  - Decided to release v0.1.0 as Milestone 1 only; Tasks 6-13 move to v0.2+.
  - Published the repo publicly at `harsh-bhutaiya/shipwright` and added the `protect-main` ruleset, secret scanning, push protection and private vulnerability reporting.
  - v0.2.0 built (Tasks 6-13).
  - Added CI: tests on Ubuntu and macOS (bash 3.2), ShellCheck 0.10.0, and a PR results comment.
