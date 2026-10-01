# isobuilder

`isobuilder` provides reproducible customization profiles for Debian, Ubuntu,
Fedora and Rocky Linux and emits three deployment formats. CentOS is no longer a CI target; the old
`centos7-custom-iso` directory is retained only as historical source material.

## Output formats

| Output | Builder | Artifact |
| --- | --- | --- |
| OCI container image | `container/build.sh` | `.oci.tar` image archive |
| Cloud VM image | `cloud/build.sh` | compressed `.qcow2` |
| USB/install ISO | Debian/Ubuntu live-build; experimental RPM lorax installer | `*-hybrid.iso` |

## Profiles

| Family | Builder | CI target |
| --- | --- | --- |
| Debian | `debian-ai-desktop-iso/build.sh` | Debian 13 / `trixie` |
| Ubuntu | `debian-ai-desktop-iso/build.sh` | Ubuntu 26.04 / `resolute` |
| Fedora | `rpm-custom-iso/build.sh` | Fedora 43 (overrideable) |
| Rocky | `rpm-custom-iso/build.sh` | Rocky 9 and 10 |

The GitHub Actions workflow is manual for image builds. Pull requests run
script and profile validation; a workflow dispatch independently enables
`build_container`, `build_cloud` and `build_iso`, selects one target or all
targets, and uploads each output type as a separate artifact.

For Debian/Ubuntu dispatches, `debian_deb_url` and `ubuntu_deb_url` point to
tar.gz archives whose top-level contents are the target-compatible `.deb` files
required by the ISO profile. The same optional archives are included in the
corresponding Debian/Ubuntu OCI image. The workflow keeps the package archives
separate because their dependency sets differ.

See [`.github/workflows/custom-iso.yml`](.github/workflows/custom-iso.yml),
[`container/README.md`](container/README.md),
[`cloud/README.md`](cloud/README.md),
[`debian-ai-desktop-iso/README.md`](debian-ai-desktop-iso/README.md) and
[`rpm-custom-iso/README.md`](rpm-custom-iso/README.md).

## Acceptance status

This PR supplies build definitions and lightweight CI validation, not built
release images. Debian/Ubuntu ISO dispatch supports `display_manager` and
`desktop_core`, defaults to LightDM/ICEWM, and requires compatible component
packages. Fedora/Rocky currently have a lorax **installer** scaffold, not a
validated Live desktop/install workflow. Native XDock/XLaunch RPM packaging
and Fedora/Rocky Live desktop acceptance remain follow-up work. Cloud images
require a matching virt-builder template in the configured catalog; template
availability is not guaranteed. OCI builds without component packages provide
only the baseline desktop scaffold, not the full AI Desktop shell.
