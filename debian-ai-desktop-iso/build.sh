#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output}"
DEBIAN_SUITE="${DEBIAN_SUITE:-trixie}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-https://deb.debian.org/debian}"
LB_MODE="${LB_MODE:-debian}"
DEBIAN_ARCHIVE_AREAS="${DEBIAN_ARCHIVE_AREAS:-main contrib non-free non-free-firmware}"
AI_DESKTOP_DEB_DIR="${AI_DESKTOP_DEB_DIR:-}"
DISPLAY_MANAGER="${DISPLAY_MANAGER:-lightdm}"
DESKTOP_CORE="${DESKTOP_CORE:-icewm}"

case "${DISPLAY_MANAGER}" in
    lightdm|sddm) ;;
    *) echo "DISPLAY_MANAGER must be lightdm or sddm" >&2; exit 2 ;;
esac
case "${DESKTOP_CORE}" in
    icewm|kde) ;;
    *) echo "DESKTOP_CORE must be icewm or kde" >&2; exit 2 ;;
esac

if [[ -z "${AI_DESKTOP_DEB_DIR}" || ! -d "${AI_DESKTOP_DEB_DIR}" ]]; then
    echo "AI_DESKTOP_DEB_DIR must point to a directory containing task-ai-desktop-core, xdock and xlaunch .deb files." >&2
    exit 2
fi
for package in task-ai-desktop-core xlaunch; do
    compgen -G "${AI_DESKTOP_DEB_DIR}/${package}_*.deb" >/dev/null || {
        echo "missing ${package} package in ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
done
if [[ "${DESKTOP_CORE}" == kde ]]; then
    compgen -G "${AI_DESKTOP_DEB_DIR}/task-ai-desktop-kde-plasma-core_*.deb" >/dev/null || {
        echo "missing task-ai-desktop-kde-plasma-core package in ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
else
    compgen -G "${AI_DESKTOP_DEB_DIR}/xdock_*.deb" >/dev/null || {
        echo "missing xdock package for the ICEWM profile in ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
rsync -a "${SCRIPT_DIR}/config/" "${BUILD_DIR}/config/"
mkdir -p "${BUILD_DIR}/config/packages.chroot"
cp "${AI_DESKTOP_DEB_DIR}"/*.deb "${BUILD_DIR}/config/packages.chroot/"

package_list="${BUILD_DIR}/config/package-lists/ai-desktop.list.chroot"
if [[ "${DISPLAY_MANAGER}" == sddm ]]; then
    sed -i -e '/^lightdm$/d' -e '/^lightdm-gtk-greeter$/d' "${package_list}"
    echo sddm >>"${package_list}"
    rm -rf "${BUILD_DIR}/config/includes.chroot/etc/lightdm"
    rm -f "${BUILD_DIR}/config/hooks/normal/0100-ai-desktop-lightdm.hook.chroot"
    mkdir -p "${BUILD_DIR}/config/includes.chroot/etc/sddm.conf.d"
    cat >"${BUILD_DIR}/config/includes.chroot/etc/sddm.conf.d/10-ai-desktop.conf" <<CONF
[General]
DisplayServer=x11
CONF
    cat >"${BUILD_DIR}/config/hooks/normal/0100-ai-desktop-sddm.hook.chroot" <<HOOK
#!/bin/sh
set -eu
if [ -x /usr/bin/sddm ]; then
    printf "%s\n" /usr/bin/sddm > /etc/X11/default-display-manager
    mkdir -p /etc/systemd/system
    ln -sf /lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service
    if command -v deb-systemd-helper >/dev/null 2>&1; then
        deb-systemd-helper enable sddm.service || true
    fi
fi
HOOK
    chmod 0755 "${BUILD_DIR}/config/hooks/normal/0100-ai-desktop-sddm.hook.chroot"
fi
if [[ "${DESKTOP_CORE}" == kde ]]; then
    echo task-ai-desktop-kde-plasma-core >>"${package_list}"
else
    echo xdock >>"${package_list}"
fi

command -v lb >/dev/null 2>&1 || {
    echo "live-build (lb) is required to build the ISO" >&2
    exit 2
}
cd "${BUILD_DIR}"
lb config \
    --distribution "${DEBIAN_SUITE}" \
    --mode "${LB_MODE}" \
    --archive-areas "${DEBIAN_ARCHIVE_AREAS}" \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR}" \
    --binary-images iso-hybrid \
    --debian-installer live \
    --bootappend-live "boot=live components username=aiuser" \
    --iso-application "task-ai-desktop" \
    --iso-volume "TASK-AI-DESKTOP"
lb build

iso="$(find . -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "${iso}" ]]; then
    echo "live-build did not produce an ISO" >&2
    exit 1
fi
cp "${iso}" "${OUTPUT_DIR}/task-ai-desktop-${DEBIAN_SUITE}-${DISPLAY_MANAGER}-${DESKTOP_CORE}-hybrid.iso"
echo "${OUTPUT_DIR}/task-ai-desktop-${DEBIAN_SUITE}-${DISPLAY_MANAGER}-${DESKTOP_CORE}-hybrid.iso"
