#!/usr/bin/env bash
set -euo pipefail

PAUSE_ON_EXIT=false
if [[ "${1:-}" == "--pause" ]]; then
    PAUSE_ON_EXIT=true
    shift
fi

if (( $# > 0 )); then
    printf 'ERROR: unknown argument: %s\n' "$1" >&2
    exit 2
fi

pause_on_exit() {
    if [[ "$PAUSE_ON_EXIT" == true && -t 0 ]]; then
        printf '\nНажмите любую клавишу, чтобы закрыть окно...'
        read -r -n 1 _ || true
        printf '\n'
    fi
}
trap pause_on_exit EXIT

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PID_FILE="$PROJECT_ROOT/.raytsystem/run-server.pid"

if [[ ! -f "$PID_FILE" ]]; then
    printf 'raytsystem is not running: PID file not found.\n'
    exit 0
fi

pid="$(<"$PID_FILE")"
if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
    printf 'ERROR: invalid PID file: %s\n' "$PID_FILE" >&2
    exit 1
fi

if ! kill -0 "$pid" 2>/dev/null; then
    rm -f -- "$PID_FILE"
    printf 'raytsystem is not running; removed a stale PID file.\n'
    exit 0
fi

process_cwd="$(readlink -f -- "/proc/$pid/cwd" 2>/dev/null || true)"
process_command="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || true)"

if [[ "$process_cwd" != "$PROJECT_ROOT" ]] || [[ "$process_command" != *raytsystem* ]]; then
    printf 'ERROR: PID %s does not identify this project server; refusing to stop it.\n' "$pid" >&2
    exit 1
fi

kill -TERM "$pid"

for _ in {1..50}; do
    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f -- "$PID_FILE"
        printf 'Сервер raytsystem успешно остановлен.\n'
        exit 0
    fi
    sleep 0.2
done

printf 'ERROR: server PID %s did not stop within 10 seconds.\n' "$pid" >&2
exit 1
