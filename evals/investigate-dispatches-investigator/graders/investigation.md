---
type: llm
weight: 1
---

Judge the agent's final message against three conditions. Check each on its own. PASS only when all three hold; FAIL if any one is missing.

1. **Plain-language cause.** The message explains in simple terms why orders of exactly $50 are charged shipping: the free-shipping check uses "greater than" ($50 is not over $50) where "$50 or more" needs "greater than or equal" (`>` vs `>=` in `shipping.py`).
2. **Proposed fix, not applied.** The message proposes the fix (change `>` to `>=`). It does not claim the fix was already made, edited or committed. Saying the fix is proposed or pending counts.
3. **Approval asked.** The message asks the developer to approve the fix, or says it is waiting for approval, before implementing it.
