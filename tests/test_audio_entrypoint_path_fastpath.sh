#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Audio entry-point path fast path: FAIL: %s\n' "$1" >&2; exit 1; }

for file in \
    "$ROOT/scripts/get_volume" \
    "$ROOT/scripts/set_volume" \
    "$ROOT/scripts/set_mute" \
    "$ROOT/scripts/toggle_mute"; do
    grep -Fq 'SCRIPT_PATH="${BASH_SOURCE[0]}"' "$file" || fail "missing Bash path expansion in $file"
    if grep -Eq 'dirname[[:space:]]+--[[:space:]]+"\$\{BASH_SOURCE\[0\]\}"' "$file"; then
        fail "external dirname remains in $file"
    fi
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
project="$work/Audio Project With Spaces"
mkdir -p "$project/scripts/audio" "$work/bin"
cp "$ROOT/scripts/get_volume" "$ROOT/scripts/set_volume" "$ROOT/scripts/set_mute" "$ROOT/scripts/toggle_mute" "$project/scripts/"
cp "$ROOT/scripts/audio/common.sh" "$project/scripts/audio/common.sh"
cat > "$work/bin/wpctl" <<'WPCTL'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$WPCTL_LOG"
case "${1:-}" in
    get-volume) printf 'Volume: 0.42\n' ;;
    *) exit 0 ;;
esac
WPCTL
cat > "$work/bin/dirname" <<'DIRNAME'
#!/usr/bin/env bash
printf 'dirname\n' >> "$DIRNAME_LOG"
exit 98
DIRNAME
chmod +x "$work/bin/wpctl" "$work/bin/dirname"
export PATH="$work/bin:$PATH" WPCTL_LOG="$work/wpctl.log" DIRNAME_LOG="$work/dirname.log"
: > "$WPCTL_LOG"
: > "$DIRNAME_LOG"

absolute_output="$(bash "$project/scripts/get_volume")"
[[ "$absolute_output" == '42 0' ]] || fail "absolute get_volume failed: $absolute_output"
relative_output="$(cd "$project" && bash scripts/get_volume)"
[[ "$relative_output" == '42 0' ]] || fail "relative get_volume failed: $relative_output"

bash "$project/scripts/set_volume" main 55
bash "$project/scripts/set_mute" 1
bash "$project/scripts/toggle_mute"
grep -Fqx 'set-volume @DEFAULT_AUDIO_SINK@ 55%' "$WPCTL_LOG" || fail 'set_volume did not source audio helper'
grep -Fqx 'set-mute @DEFAULT_AUDIO_SINK@ 1' "$WPCTL_LOG" || fail 'set_mute did not source audio helper'
grep -Fqx 'set-mute @DEFAULT_AUDIO_SINK@ toggle' "$WPCTL_LOG" || fail 'toggle_mute did not source audio helper'
[[ ! -s "$DIRNAME_LOG" ]] || fail "audio entry points launched dirname: $(cat "$DIRNAME_LOG")"
printf 'Audio entry-point path fast path, absolute/relative paths with spaces, and controls: OK\n'
