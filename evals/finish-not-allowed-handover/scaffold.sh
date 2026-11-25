#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
mkdir -p src docs/plans .shipwright
printf '# demo\n' > README.md
printf 'def add(a, b):\n    return a + b\n' > src/calc.py
git add . && git commit -qm "chore: initial commit"
printf 'def mul(a, b):\n    return a * b\n' >> src/calc.py
printf 'from src.calc import mul\n\ndef test_mul():\n    assert mul(2, 3) == 6\n' > test_calc.py
cat > docs/plans/2026-11-24-mul.md <<'P'
# Add mul

### Task 1: mul function
Risky: none
- [x] Add mul to src/calc.py
- [ ] **Checkpoint:** files `src/calc.py`, `test_calc.py`; commit message `feat: add mul to calculator`

## Acceptance checklist
- [x] mul(2, 3) is 6 — verify: test — test_calc.py::test_mul passes
P
printf 'docs_mode=in-repo\ndocs_dir=docs\n' > .shipwright/project.conf
printf 'commit_push=not-allowed\n' > .shipwright/developer.conf
