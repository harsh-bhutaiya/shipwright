---
type: tool_used
tool: Skill
input_match: "subagent-driven-development|executing-plans"
min: 1
arm: both
---

The plan proceeds without review: after writing it, the agent starts an execution skill on its own. The prompt asks only for the plan, so only the `plan_approval=auto` rule can start the build.
