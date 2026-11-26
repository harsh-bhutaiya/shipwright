#!/usr/bin/env bash
git init -q -b main . && git config user.email t@example.com && git config user.name t
mkdir -p src docs/plans docs/specs .shipwright
printf '# demo\n' > README.md
printf 'def add(a, b):\n    return a + b\n' > src/calc.py
git add . && git commit -qm "initial commit"
git checkout -q -b feat/mul
printf 'def mul(a, b):\n    return a * b\n' >> src/calc.py
printf 'from src.calc import mul\n\ndef test_mul():\n    assert mul(2, 3) == 6\n' > test_calc.py
cat > docs/specs/2026-11-25-mul-design.md <<'P'
# Add mul design

Add a `mul(a, b)` function to `src/calc.py` that returns the product of its arguments.
P
cat > docs/plans/2026-11-25-mul.md <<'P'
# Add mul

### Task 1: mul function
Risky: none
- [x] Add mul to src/calc.py
- [x] Add test_calc.py

## Acceptance checklist
- [x] mul(2, 3) is 6 — verify: test — test_calc.py::test_mul passes
P
printf 'docs_mode=in-repo\ndocs_dir=docs\n' > .shipwright/project.conf
printf 'commit_push=allowed\nai_coauthor=no\n' > .shipwright/developer.conf
