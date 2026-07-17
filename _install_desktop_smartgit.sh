#!/usr/bin/env bash
set -euo pipefail

SMARTGIT_EXECUTABLE="$HOME/.local/opt/smartgit/bin/smartgit.sh"

if [[ ! -x "$SMARTGIT_EXECUTABLE" ]]; then
    printf 'ERROR: SmartGit executable not found or not executable: %s\n' "$SMARTGIT_EXECUTABLE" >&2
    exit 1
fi

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

escaped_executable="${SMARTGIT_EXECUTABLE//\\/\\\\}"
escaped_executable="${escaped_executable//\"/\\\"}"

cat >"$DESKTOP_DIR/SmartGit.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SmartGit
Comment=Git graphical client
Exec="$escaped_executable"
Icon=smartgit
Terminal=false
Categories=Development;RevisionControl;
StartupNotify=true
EOF

chmod +x "$DESKTOP_DIR/SmartGit.desktop"

if command -v gio >/dev/null 2>&1; then
    gio set "$DESKTOP_DIR/SmartGit.desktop" metadata::trusted true 2>/dev/null || true
fi

printf 'SmartGit desktop shortcut installed in %s\n' "$DESKTOP_DIR"
