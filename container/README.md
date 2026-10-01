# OCI container image

`build.sh` builds a headless ICEWM/X11 desktop container and exports it as an
OCI-compatible image archive. The image starts `Xvfb`, then `dbus-run-session`
and `icewm-session`; it does not require systemd or a physical display. When
`AI_DESKTOP_DEB_DIR` is supplied, the Debian package family is included and its
native XDock/XLaunch session launcher is used.

## Examples

```sh
OS_FAMILY=debian OS_RELEASE=13 BASE_IMAGE=debian:13 ./container/build.sh
OS_FAMILY=ubuntu OS_RELEASE=26.04 BASE_IMAGE=ubuntu:26.04 ./container/build.sh
OS_FAMILY=fedora OS_RELEASE=43 BASE_IMAGE=fedora:43 ./container/build.sh
OS_FAMILY=rocky OS_RELEASE=10 BASE_IMAGE=rockylinux:10 ./container/build.sh
```

For Debian/Ubuntu package integration, set `AI_DESKTOP_DEB_DIR` to the
target-compatible `.deb` directory used by the ISO build.

The output is written to `container/output/*.oci.tar`. Load it with `podman
load` or `docker load`.

Docker builds require skopeo for true OCI archive export; Podman can export
OCI directly. ARCH selects the container build platform. Native component
packages are required for a complete XDock/XLaunch desktop.
