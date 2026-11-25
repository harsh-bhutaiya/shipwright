---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits or Checkpoints (see Commit or Checkpoint).

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `shipwright:using-git-worktrees` skill at execution time.

**Save plans to:** `<docs_dir>/plans/YYYY-MM-DD-<feature-name>.md`, where `<docs_dir>` is `"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get docs_dir`. After saving, call `shipwright:publishing-docs` with the file (it does nothing unless `docs_mode` is `shared-tool`).
- (User preferences for plan location override this default)

## Settings

Read these before writing; they shape the plan:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get plan_approval
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get commit_push
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get pr_line_cap
```

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step (only when `commit_push=allowed`; see Commit or Checkpoint)

## Risky Tagging and Approval

Every task carries its own line, exactly `Risky: none` or `Risky: <category>[, <category>]`. Categories are these 9, named as written:

1. DB schema/migrations/backfills
2. deleting or overwriting data or files outside the feature
3. auth, permissions, secrets or security
4. payments, billing or pricing
5. a public API or contract change
6. infra, deploy or CI config
7. adding or upgrading dependencies
8. anything irreversible or touching production
9. the project's "do not change" areas

Approval rule: when `plan_approval=auto` and every task says `Risky: none`, the plan proceeds without waiting for review. In every other case (`plan_approval=review`, or any task names a category) stop and ask the developer to review the plan, even under `auto`. Say which tasks are risky and why.

## Commit or Checkpoint

When `commit_push=allowed`, the last step of each task is a commit step. Otherwise (including unset) the task ends with a Checkpoint, and no step runs `git add`, `git commit` or `git push`:

```markdown
- [ ] **Checkpoint:** files `<path>`, `<path>`; commit message `<message in the project's format>`
```

## Branch Stack

When `pr_line_cap` is set, cut the tasks into a stack of branches so each branch stays under the cap of non-test lines. Keep one branch otherwise. Rules (spec §4.3):

- No file appears in two branches.
- Each branch passes the tests on its own, in stack order.

Record the stack under `## Branch stack` in the plan, one line per branch: `- <branch-name>: tasks <N-M>; based on <base branch>`.

## Acceptance Checklist

Every plan has a section headed exactly `## Acceptance checklist`, one line per case decided in the spec, saying how it is verified (spec §2.10 step 1):

```markdown
- [ ] <case> — verify: <test | live run | log check> — <how>
```

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use shipwright:subagent-driven-development (recommended) or shipwright:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Review Focus

[The five input classes or failure modes the spec implies but no task's
tests exercise that are most likely to bite a person using this software
— one line each, naming the input or condition and the behavior a
reasonable person would expect, most likely first. The spec is a vision
document: it says what the software must do, not everything it will
meet, and its silence on an input is not permission for that input to
break the program. Write the list here, once, with the spec in front of
you. Then, for each line, add the test that pins it to the task that
owns the code, in that task's own step style.]

---

## Branch stack

[One line per branch, in stack order: `- <branch-name>: tasks <N-M>; based on <base branch>`. Without `pr_line_cap`, one line for the single branch: `- <branch-name>: tasks 1-N; based on <base branch>`.]

## Acceptance checklist

[One line per decided case.]
```

## Task Structure

````markdown
### Task N: [Component Name]

Risky: none

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit** (when `commit_push=allowed`)

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

When `commit_push` is not `allowed`, replace Step 5 with the Checkpoint line (see Commit or Checkpoint).
````

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command to run and the output that means it
  passed.
- **A reference to another task:** that task's Interfaces block says what
  to use; the plan does not repeat that task's code.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing ("TBD", "handle edge cases", "add appropriate validation",
"write tests for the above", a type or function no task defines) are the
opposite failure, and the self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.

**5. Risk, checklist and stack:** Does every task have a `Risky:` line? Does every decided case have an acceptance line? With `pr_line_cap` set, does any file appear in two branches?

**6. Proportion:** Compare the plan's length to the spec's. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of the document, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving and self-reviewing the plan, link it for your human partner
to read. Then apply the approval rule (Risky Tagging and Approval).

**When the approval rule says proceed** (`plan_approval=auto` and every task
says `Risky: none`): do not wait for a review. Say in one line that the plan
is auto-approved, name the execution method (the one they supplied, else your
recommendation below, with its reason) and start it.

**In every other case,** the plan waits for their review. If they have
already explicitly supplied an execution method, ask them to review the plan
and confirm it captures what they want; wait for that review before
implementation, then use the preserved method. Otherwise, ask them to review
the plan and choose an execution method before implementation. Under `auto`,
also say which tasks are risky and why.

**When the plan waits for review and no execution method has already been supplied:**

**"Plan complete and saved to `<docs_dir>/plans/<filename>.md`. Please review the plan. Which execution approach would you prefer?**

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Native** - I implement every task myself in this session, the way this harness runs work, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Runs well with a mid-tier session model, since the plan carries the design.

**For this plan I recommend <one of the two>, because <one sentence from the plan: how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost>. Does the plan capture what you want, and which approach should we use?"**

**When the plan waits for review and an execution method has already been supplied:**

**"Plan complete and saved to `<docs_dir>/plans/<filename>.md`. Please review the plan. Does it capture what you want?"**

**If Subagent-driven chosen:**
- **REQUIRED SUB-SKILL:** Use shipwright:subagent-driven-development

**If Native chosen:**
- **REQUIRED SUB-SKILL:** Use shipwright:executing-plans
