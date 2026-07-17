#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_DIR="$PROJECT_ROOT/.raytsystem"
PID_FILE="$STATE_DIR/run-server.pid"

if command -v uv >/dev/null 2>&1; then
    UV_BIN="$(command -v uv)"
elif [[ -n "${HOME:-}" && -x "$HOME/.local/bin/uv" ]]; then
    UV_BIN="$HOME/.local/bin/uv"
else
    printf 'ERROR: uv is not installed or is not available in PATH.\n' >&2
    exit 127
fi

mkdir -p -- "$STATE_DIR"

if [[ -f "$PID_FILE" ]]; then
    existing_pid="$(<"$PID_FILE")"
    if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
        printf 'ERROR: raytsystem appears to be running with PID %s.\n' "$existing_pid" >&2
        exit 1
    fi
    rm -f -- "$PID_FILE"
fi

temporary_pid_file="$PID_FILE.$$"
printf '%s\n' "$$" >"$temporary_pid_file"
mv -f -- "$temporary_pid_file" "$PID_FILE"

cd -- "$PROJECT_ROOT"
exec "$UV_BIN" run raytsystem start
