#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if ! command -v xdg-user-dir >/dev/null 2>&1; then
    printf 'ERROR: xdg-user-dir is not installed. Install the xdg-user-dirs package.\n' >&2
    exit 127
fi

DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
if [[ -z "$DESKTOP_DIR" ]]; then
    printf 'ERROR: the desktop directory could not be determined.\n' >&2
    exit 1
fi

mkdir -p -- "$DESKTOP_DIR"
chmod +x "$PROJECT_ROOT/_run_server.sh" "$PROJECT_ROOT/_stop_server.sh"

escaped_root="${PROJECT_ROOT//\\/\\\\}"
escaped_root="${escaped_root//\"/\\\"}"

cat >"$DESKTOP_DIR/knowledge-system-start.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Start knowledge-system
Comment=Start the local knowledge-system server
Exec="$escaped_root/_run_server.sh"
Icon=utilities-terminal
Terminal=true
Categories=Development;
StartupNotify=true
EOF

cat >"$DESKTOP_DIR/knowledge-system-stop.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Stop knowledge-system
Comment=Stop the local knowledge-system server
Exec="$escaped_root/_stop_server.sh" --pause
Icon=process-stop
Terminal=true
Categories=Development;
StartupNotify=false
EOF

cat >"$DESKTOP_DIR/knowledge-system.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=knowledge-system
Comment=Открыть knowledge-system Command Center
Exec=firefox --new-window http://127.0.0.1:8765/command-center
Icon=firefox
Terminal=false
Categories=Development;
StartupNotify=true
EOF

chmod +x \
    "$DESKTOP_DIR/knowledge-system-start.desktop" \
    "$DESKTOP_DIR/knowledge-system-stop.desktop" \
    "$DESKTOP_DIR/knowledge-system.desktop"

if command -v gio >/dev/null 2>&1; then
    gio set "$DESKTOP_DIR/knowledge-system-start.desktop" metadata::trusted true 2>/dev/null || true
    gio set "$DESKTOP_DIR/knowledge-system-stop.desktop" metadata::trusted true 2>/dev/null || true
    gio set "$DESKTOP_DIR/knowledge-system.desktop" metadata::trusted true 2>/dev/null || true
fi

printf 'Desktop shortcuts installed in %s\n' "$DESKTOP_DIR"
