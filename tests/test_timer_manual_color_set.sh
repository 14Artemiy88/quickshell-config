#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR/timer"
TIMER_DIR="$XDG_RUNTIME_DIR/timer"
file="$TIMER_DIR/manual"
printf '5 1234567890 0 aabbcc 0 preserve fields\n' > "$file"
printf '77\n' > "$TIMER_DIR/.elapsed-manual"

"$ROOT/scripts/timer" set_color "$file" '#12aBcD'
read -r total end ding color paused comment < "$file"
[[ "$total" == 5 && "$end" == 1234567890 && "$ding" == 0 && "$paused" == 0 && "$comment" == 'preserve fields' ]] || { echo 'manual color edit changed unrelated timer fields' >&2; exit 1; }
[[ "$color" == '12abcd' ]] || { echo "manual color not normalized: $color" >&2; exit 1; }
[[ "$(cat "$TIMER_DIR/.elapsed-manual")" == 77 ]] || { echo 'manual color edit changed cumulative elapsed sidecar' >&2; exit 1; }
cp "$file" "$TMP_ROOT/before-invalid"
if "$ROOT/scripts/timer" set_color "$file" 'bad' >/dev/null 2>&1; then
    echo 'invalid manual color was accepted' >&2
    exit 1
fi
cmp -s "$TMP_ROOT/before-invalid" "$file" || { echo 'invalid color changed timer file' >&2; exit 1; }

# The normal timer creation path and randomize action must use the selected range.
"$ROOT/scripts/timer" add 1 test light
new_file=$(find "$TIMER_DIR" -maxdepth 1 -type f ! -name '.*' ! -name manual | head -n 1)
[[ -n "$new_file" ]] || { echo 'new timer was not created' >&2; exit 1; }
read -r _ _ _ new_color _ _ < "$new_file"
for index in 0 2 4; do
    channel=$((16#${new_color:index:2}))
    (( channel >= 128 && channel <= 255 )) || { echo "new timer ignored light range: $new_color" >&2; exit 1; }
done
"$ROOT/scripts/timer" update_color "$file" dark
read -r _ _ _ new_color _ _ < "$file"
for index in 0 2 4; do
    channel=$((16#${new_color:index:2}))
    (( channel >= 0 && channel <= 127 )) || { echo "right-click random color ignored dark range: $new_color" >&2; exit 1; }
done

echo 'Timer manual color edit, elapsed metadata preservation, new timer range and reroll range: OK'
