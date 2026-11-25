#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
mkdir -p docs/specs .shipwright/work
printf '# Demo design\n\nDecided: use a queue.\n' > docs/specs/2026-11-25-demo-design.md
printf 'docs_mode=shared-tool\nwiki_connector=wiki\nwiki_location=ENG\n' > .shipwright/project.conf
printf 'docs/specs/2026-11-25-demo-design.md.page_id=page-42\ndocs/specs/2026-11-25-demo-design.md.last_published_version=5\n' > .shipwright/work/published.conf
