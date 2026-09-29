# Debian + task-ai-desktop ISO

This profile builds a modern Debian live ISO containing the
`task-ai-desktop` ICEWM/X11 environment:

- ICEWM session
- XDock EWMH dock
- XLaunch compact Menu and full-screen app launcher
- xfce4-terminal
- Thunar + GVFS
- Chromium or Firefox ESR

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

`AI_DESKTOP_DEB_DIR` must contain the `task-ai-desktop`, `xdock`, and
`xlaunch` packages. The output is written to `output/task-ai-desktop-*.iso`.

The default mirror is `https://deb.debian.org/debian`. Override
`DEBIAN_MIRROR` for an internal mirror.

## Runtime

The live session starts an ICEWM X11 session. The sample ICEWM startup and
menu files are installed into `/etc/skel`; they start the native XDock and
XLaunch binaries after a user logs in.
