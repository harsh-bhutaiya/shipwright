#!/usr/bin/env bash
# Runs every tests/**/test-*.sh with bash; exits non-zero if any fails.
cd "$(dirname "$0")/.." || exit 1
failed=0
while IFS= read -r t; do
    if bash "$t" >/tmp/shipwright-test.$$ 2>&1; then
        echo "PASS $t"
    else
        echo "FAIL $t"; sed 's/^/    /' /tmp/shipwright-test.$$; failed=$((failed + 1))
    fi
done < <(find tests -name 'test-*.sh' ! -name 'test-helpers.sh' | sort)
rm -f /tmp/shipwright-test.$$
if [ "$failed" -eq 0 ]; then echo "ALL PASS"; else echo "$failed FAILED"; exit 1; fi
