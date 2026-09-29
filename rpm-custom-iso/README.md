# Fedora / Rocky custom ISO

This profile replaces the historical CentOS 7 path. The supported RPM
families are Fedora and Rocky Linux; the builder uses `lorax`, `dnf`,
`createrepo_c` and `xorriso`.

## Host dependencies

On Fedora or Rocky:

```sh
sudo dnf install -y lorax dnf-plugins-core createrepo_c xorriso
```

Rocky desktop packages such as `icewm` or `x11vnc` may require an enabled EPEL
repository. Add the repository URL through `EXTRA_REPOS` rather than hardcoding
CentOS mirrors.

## Build

```sh
OS_FAMILY=fedora OS_RELEASE=42 \
  ./rpm-custom-iso/build.sh

OS_FAMILY=rocky OS_RELEASE=9 \
  ./rpm-custom-iso/build.sh
```

Override `BASE_MIRROR`, `APPSTREAM_MIRROR`, `EXTRA_REPOS`, `PACKAGE_LIST`,
`BUILD_DIR` and `OUTPUT_DIR` for internal mirrors or a custom package profile.
The default package lists are intentionally small; add the AI desktop RPMs or
local repository to the selected profile before producing a release ISO.
