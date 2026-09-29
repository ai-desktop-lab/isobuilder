#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output}"
DEBIAN_SUITE="${DEBIAN_SUITE:-trixie}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-https://deb.debian.org/debian}"
AI_DESKTOP_DEB_DIR="${AI_DESKTOP_DEB_DIR:-}"

if [[ -z "${AI_DESKTOP_DEB_DIR}" || ! -d "${AI_DESKTOP_DEB_DIR}" ]]; then
    echo "AI_DESKTOP_DEB_DIR must point to a directory containing the task-ai-desktop package family, xdock and xlaunch .deb files." >&2
    exit 2
fi
for package in \
    task-ai-desktop-core task-ai-desktop-session \
    task-ai-desktop-xdock task-ai-desktop-xlaunch task-ai-desktop-apps \
    task-ai-desktop task-ai-desktop-vps xdock xlaunch; do
    compgen -G "${AI_DESKTOP_DEB_DIR}/${package}_*.deb" >/dev/null || {
        echo "missing ${package} package in ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
done

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
rsync -a "${SCRIPT_DIR}/config/" "${BUILD_DIR}/config/"
mkdir -p "${BUILD_DIR}/config/packages.chroot"
cp "${AI_DESKTOP_DEB_DIR}"/*.deb "${BUILD_DIR}/config/packages.chroot/"

cd "${BUILD_DIR}"
lb config \
    --distribution "${DEBIAN_SUITE}" \
    --mode debian \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR}" \
    --binary-images iso-hybrid \
    --debian-installer live \
    --bootappend-live "boot=live components username=aiuser" \
    --iso-application "task-ai-desktop" \
    --iso-volume "TASK-AI-DESKTOP"
lb build

iso="$(find . -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name '*.iso' \) | head -n 1)"
if [[ -z "${iso}" ]]; then
    echo "live-build did not produce an ISO" >&2
    exit 1
fi
cp "${iso}" "${OUTPUT_DIR}/task-ai-desktop-${DEBIAN_SUITE}.iso"
echo "${OUTPUT_DIR}/task-ai-desktop-${DEBIAN_SUITE}.iso"
