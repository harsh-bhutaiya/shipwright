#!/usr/bin/env bash
git init -q . && git config user.email t@example.com && git config user.name t
mkdir -p .shipwright logs
printf 'docs_mode=in-repo\n' > .shipwright/project.conf
printf '# shop\nSmall checkout service. No monitoring and no database. Application logs are written to logs/app.log.\n' > README.md
cat > shipping.py <<'PY'
FREE_SHIPPING_THRESHOLD = 50.00
FLAT_RATE = 4.99


def shipping_cost(order_total):
    if order_total > FREE_SHIPPING_THRESHOLD:
        return 0.0
    return FLAT_RATE
PY
cat > logs/app.log <<'LOG'
2026-11-12 09:14:02 INFO order=1041 total=72.40 shipping=0.00
2026-11-18 10:02:51 INFO order=1088 total=50.00 shipping=4.99
2026-11-18 11:20:09 INFO order=1090 total=31.25 shipping=4.99
2026-11-19 16:45:33 INFO order=1103 total=50.00 shipping=4.99
2026-11-20 08:31:17 INFO order=1117 total=118.00 shipping=0.00
LOG
printf 'DATABASE_URL=postgres://app:REDACTED@db.internal/shop\n' > .env
git add -A && git commit -qm init
