#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$ROOT/CHECK.sh"

missing=()
while IFS= read -r -d '' test_file; do
    name="$(basename "$test_file")"
    if ! grep -Fq "tests/$name" "$CHECK"; then
        missing+=("$name")
    fi
done < <(find "$ROOT/tests" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

if ((${#missing[@]})); then
    printf 'Test files not wired into CHECK.sh:\n' >&2
    printf '  - %s\n' "${missing[@]}" >&2
    exit 1
fi

count="$(find "$ROOT/tests" -maxdepth 1 -type f -name '*.sh' | wc -l | tr -d ' ')"
refs="$(grep -oE 'tests/[A-Za-z0-9_.-]+\.sh' "$CHECK" | sort -u | wc -l | tr -d ' ')"
if [[ "$count" != "$refs" ]]; then
    echo "Test coverage mismatch: $count test files but CHECK.sh references $refs unique test scripts" >&2
    exit 1
fi
printf 'CI test coverage: all %s shell tests are wired into CHECK.sh\n' "$count"

# Calculator and pointer-hover regression coverage is part of CHECK.sh.
grep -q "test_launcher_calculator_and_pointer_hover.sh" "$ROOT/CHECK.sh"
