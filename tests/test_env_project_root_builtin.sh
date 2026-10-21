#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
REAL_DIRNAME="$(command -v dirname)"
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/project/scripts/player.d" "$TMP_DIR/project space/scripts/player.d"
cat > "$TMP_DIR/bin/dirname" <<'STUB'
#!/usr/bin/env bash
printf 'dirname\n' >> "$ENV_DIRNAME_LOG"
exec "$REAL_DIRNAME" "$@"
STUB
chmod +x "$TMP_DIR/bin/dirname"
export REAL_DIRNAME ENV_DIRNAME_LOG="$TMP_DIR/dirname.log" PATH="$TMP_DIR/bin:$PATH"

setup_project() {
    local project="$1" tag="$2"
    mkdir -p "$project/scripts" "$TMP_DIR/$tag/config" "$TMP_DIR/$tag/data" "$TMP_DIR/$tag/state" "$TMP_DIR/$tag/cache" "$TMP_DIR/$tag/runtime"
    cp "$ROOT/scripts/env" "$project/scripts/env"
    printf '{"modules":{"time":true,"timer":true},"geometry":{}}\n' > "$project/settings.json"
    printf '{}' > "$TMP_DIR/$tag/config/settings.json"
    printf '{}' > "$TMP_DIR/$tag/data/calendar-notes.json"
    : > "$TMP_DIR/$tag/config/.migration-settings-v1"
    : > "$TMP_DIR/$tag/data/.migration-calendar-notes-v1"
}

run_case() {
    local project="$1" tag="$2" mode="$3" output
    export QS_CONFIG_DIR="$TMP_DIR/$tag/config" QS_DATA_DIR="$TMP_DIR/$tag/data"         QS_STATE_DIR="$TMP_DIR/$tag/state" QS_CACHE_DIR="$TMP_DIR/$tag/cache"         XDG_RUNTIME_DIR="$TMP_DIR/$tag/runtime" HOME="$TMP_DIR/$tag/home"
    mkdir -p "$HOME"
    output="$TMP_DIR/$tag/project.out"
    case "$mode" in
        absolute)
            env -u QS_PROJECT_DIR bash -c 'source "$1/scripts/env"; printf "%s\n" "$QS_PROJECT_DIR"' _ "$project" > "$output"
            ;;
        relative)
            (cd "$project" && env -u QS_PROJECT_DIR bash -c 'source scripts/env; printf "%s\n" "$QS_PROJECT_DIR"') > "$output"
            ;;
        dotdot)
            (cd "$project" && env -u QS_PROJECT_DIR bash -c 'source scripts/player.d/../env; printf "%s\n" "$QS_PROJECT_DIR"') > "$output"
            ;;
        bare)
            (cd "$project/scripts" && env -u QS_PROJECT_DIR bash -c 'source ./env; printf "%s\n" "$QS_PROJECT_DIR"') > "$output"
            ;;
    esac
    [[ "$(<"$output")" == "$project" ]] || { echo "wrong project root for $mode: $(<"$output") != $project" >&2; exit 1; }
}

setup_project "$TMP_DIR/project" first
setup_project "$TMP_DIR/project space" spaced
: > "$ENV_DIRNAME_LOG"
run_case "$TMP_DIR/project" first absolute
run_case "$TMP_DIR/project" first relative
run_case "$TMP_DIR/project" first dotdot
run_case "$TMP_DIR/project" first bare
run_case "$TMP_DIR/project space" spaced absolute
[[ ! -s "$ENV_DIRNAME_LOG" ]] || { echo "env path resolution invoked dirname $(wc -l < "$ENV_DIRNAME_LOG") time(s)" >&2; exit 1; }
printf 'env project-root resolution uses Bash built-ins for absolute/relative, dot-dot, bare and spaced paths: OK\n'
