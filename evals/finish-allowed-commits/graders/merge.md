---
type: tool_used
tool: Bash
input_match: '(git|\$[A-Za-z_][A-Za-z0-9_]*) merge'
min: 1
arm: both
---

At least one Bash call runs git merge, directly or through a variable holding the git path.
