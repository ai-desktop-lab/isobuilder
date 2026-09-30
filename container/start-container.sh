#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"
SCREEN_SIZE="${SCREEN_SIZE:-1280x800x24}"

if [[ -x /usr/lib/task-ai-desktop/start-container.sh ]]; then
    exec /usr/lib/task-ai-desktop/start-container.sh
fi

Xvfb "${DISPLAY}" -screen 0 "${SCREEN_SIZE}" -nolisten tcp &
xvfb_pid=$!
trap 'kill "${xvfb_pid}" 2>/dev/null || true' EXIT

if command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session -- icewm-session
fi
exec icewm-session
