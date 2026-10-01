# Cloud VM image

`build.sh` produces a compressed `qcow2` cloud image with cloud-init, ICEWM,
Xvfb, X11VNC, Thunar and a terminal. It uses `virt-builder` templates so the
same entry point can target Debian 13, Ubuntu 26.04, Fedora 43 and Rocky Linux
9 or 10.

## Host dependencies

```sh
sudo apt-get install -y libguestfs-tools qemu-utils
```

The template name can be overridden with `CLOUD_TEMPLATE` when a local
virt-builder repository uses different names. `DISK_SIZE`, `PACKAGE_LIST`,
`BUILD_DIR` and `OUTPUT_DIR` are also configurable.

## Examples

```sh
OS_FAMILY=debian OS_RELEASE=13 CLOUD_TEMPLATE=debian-13 ./cloud/build.sh
OS_FAMILY=ubuntu OS_RELEASE=26.04 CLOUD_TEMPLATE=ubuntu-26.04 ./cloud/build.sh
OS_FAMILY=fedora OS_RELEASE=43 CLOUD_TEMPLATE=fedora-43 ./cloud/build.sh
OS_FAMILY=rocky OS_RELEASE=10 CLOUD_TEMPLATE=rocky-10 ./cloud/build.sh
```
