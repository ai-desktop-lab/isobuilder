# Debian + task-ai-desktop ISO

This profile builds a modern Debian live ISO containing the
`task-ai-desktop` ICEWM/X11 environment:

- LightDM with GTK Greeter and ICEWM as the default session
- Xorg X11 display server
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


The default mirror is the Debian public mirror. Set DEBIAN_MIRROR to use an
internal mirror.

The ISO profile is unified. Set DISPLAY_MANAGER to lightdm (the default) or
sddm; both launch the ICEWM session. Set DESKTOP_CORE to icewm (the default)
or kde. The kde option adds task-ai-desktop-kde-plasma-core, starts XLaunch
through KDE autostart, and leaves XDock optional.

Examples:

~~~sh
DISPLAY_MANAGER=lightdm DESKTOP_CORE=icewm ./build.sh
DISPLAY_MANAGER=sddm DESKTOP_CORE=icewm ./build.sh
DISPLAY_MANAGER=lightdm DESKTOP_CORE=kde ./build.sh
~~~

## Runtime

The ISO enables LightDM with lightdm-gtk-greeter as the default display
manager and selects ICEWM for the user session. XLaunch provides the compact
application menu and XDock starts as the low-power bottom dock.

The live session starts an ICEWM X11 session. The sample ICEWM startup and
menu files are installed into `/etc/skel`; they start the native XDock and
XLaunch binaries after a user logs in. The same image includes the
`start-headless-session.sh` profile for an Xvfb-backed session; set
`ENABLE_NOVNC=1` when browser access on port 8080 is required.
