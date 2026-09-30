# Debian + task-ai-desktop ISO

This profile builds a modern Debian live ISO containing the
`task-ai-desktop` ICEWM/X11 environment:

- ICEWM session
- XDock EWMH dock
- XLaunch compact Menu and full-screen app launcher
- xfce4-terminal
- Thunar + GVFS
- Chromium or Firefox ESR
- Xvfb + X11VNC with optional noVNC/websockify for headless access

The profile consumes locally built Debian packages from `ai-desktop`, XDock,
and XLaunch. It does not download source code during the ISO build.

## Build

Install the host tools:

```sh
sudo apt install live-build debootstrap xorriso squashfs-tools rsync
```

Build the component packages first, then run:

```sh
AI_DESKTOP_DEB_DIR=/path/to/debs \
  DEBIAN_SUITE=trixie \
  ./build.sh
```

`AI_DESKTOP_DEB_DIR` must contain the runtime package family
(`task-ai-desktop-core`, `task-ai-desktop-session`, `task-ai-desktop-xdock`,
`task-ai-desktop-xlaunch`, `task-ai-desktop-apps`, `task-ai-desktop`, and
`task-ai-desktop-vps`) plus `xdock` and `xlaunch`. The container package is
consumed by the OCI Containerfile and is not required in the live ISO. The
output is written to `output/task-ai-desktop-*-hybrid.iso`. The `iso-hybrid`
profile can be written directly to a USB device and still boots the installer.

The default mirror is `https://deb.debian.org/debian`. Override
`DEBIAN_MIRROR` for an internal mirror.

## Runtime

The live session starts an ICEWM X11 session. The sample ICEWM startup and
menu files are installed into `/etc/skel`; they start the native XDock and
XLaunch binaries after a user logs in. The same image includes the
`start-headless-session.sh` profile for an Xvfb-backed session; set
`ENABLE_NOVNC=1` when browser access on port 8080 is required.
