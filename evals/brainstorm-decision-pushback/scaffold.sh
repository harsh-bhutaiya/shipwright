#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
printf '# demo\n' > README.md
mkdir -p .shipwright docs/specs
printf 'docs_mode=in-repo\n' > .shipwright/project.conf
cat > docs/specs/2026-10-02-auth-design.md <<'S'
# Auth design

## Decisions
- Auth uses sessions, not JWT. Sessions are stored server-side so we can revoke them instantly.
S
