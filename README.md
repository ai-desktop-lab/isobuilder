# isobuilder

`isobuilder` provides reproducible customization profiles for Debian, Ubuntu,
Fedora and Rocky Linux. CentOS is no longer a CI target; the old
`centos7-custom-iso` directory is retained only as historical source material.

## Profiles

| Family | Builder | CI target |
| --- | --- | --- |
| Debian | `debian-ai-desktop-iso/build.sh` | Debian 13 / `trixie` |
| Ubuntu | `debian-ai-desktop-iso/build.sh` | Ubuntu 26.04 / `resolute` |
| Fedora | `rpm-custom-iso/build.sh` | Fedora 43 (overrideable) |
| Rocky | `rpm-custom-iso/build.sh` | Rocky 9 and 10 |

The GitHub Actions workflow is manual for full ISO builds because ISO creation
is network-heavy and requires package inputs. Pull requests run script and
profile validation; a workflow dispatch can build one target or all targets and
uploads the resulting ISO as an artifact.

For Debian/Ubuntu dispatches, `debian_deb_url` and `ubuntu_deb_url` point to
tar.gz archives whose top-level contents are the target-compatible `.deb` files
required by the Debian profile. The workflow keeps the package archives
separate because their dependency sets differ.

See [`.github/workflows/custom-iso.yml`](.github/workflows/custom-iso.yml),
[`debian-ai-desktop-iso/README.md`](debian-ai-desktop-iso/README.md) and
[`rpm-custom-iso/README.md`](rpm-custom-iso/README.md).
