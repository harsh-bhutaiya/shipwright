#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
printf '# demo\n' > README.md
mkdir -p .shipwright
printf 'plan_approval=auto\ndocs_mode=in-repo\n' > .shipwright/project.conf
