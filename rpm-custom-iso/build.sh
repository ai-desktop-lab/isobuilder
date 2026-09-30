#!/usr/bin/env bash
set -euo pipefail

OS_FAMILY="${OS_FAMILY:-rocky}"
OS_RELEASE="${OS_RELEASE:-9}"
ARCH="${ARCH:-x86_64}"
PRODUCT_NAME="${PRODUCT_NAME:-task-ai-desktop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build/${OS_FAMILY}-${OS_RELEASE}}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output}"
PACKAGE_LIST="${PACKAGE_LIST:-${SCRIPT_DIR}/project/${OS_FAMILY}-core.list}"
BASE_MIRROR="${BASE_MIRROR:-}"
APPSTREAM_MIRROR="${APPSTREAM_MIRROR:-}"
EXTRA_REPOS="${EXTRA_REPOS:-}"

usage() {
    cat <<'EOF'
Usage: build.sh

Build a Rocky Linux or Fedora installer ISO with lorax and a local package
profile. Set OS_FAMILY=fedora|rocky and OS_RELEASE to the target release.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi
case "${OS_FAMILY}" in
    fedora|rocky) ;;
    *) echo "OS_FAMILY must be fedora or rocky" >&2; exit 2 ;;
esac
[[ -f "${PACKAGE_LIST}" ]] || { echo "missing package list: ${PACKAGE_LIST}" >&2; exit 2; }

for command in lorax dnf createrepo_c xorriso; do
    command -v "${command}" >/dev/null 2>&1 || {
        echo "missing build dependency: ${command}" >&2
        exit 2
    }
done

if [[ -z "${BASE_MIRROR}" ]]; then
    if [[ "${OS_FAMILY}" == "rocky" ]]; then
        BASE_MIRROR="https://dl.rockylinux.org/pub/rocky/${OS_RELEASE}/BaseOS/${ARCH}/os"
        APPSTREAM_MIRROR="${APPSTREAM_MIRROR:-https://dl.rockylinux.org/pub/rocky/${OS_RELEASE}/AppStream/${ARCH}/os}"
    else
        BASE_MIRROR="https://download.fedoraproject.org/pub/fedora/linux/releases/${OS_RELEASE}/Everything/${ARCH}/os"
        APPSTREAM_MIRROR="${APPSTREAM_MIRROR:-${BASE_MIRROR}}"
    fi
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}" "${BUILD_DIR}/Packages"

lorax \
    -p "${PRODUCT_NAME}" \
    -v "${OS_RELEASE}" \
    -r "${OS_RELEASE}" \
    --isfinal \
    -s "${BASE_MIRROR}" \
    -s "${APPSTREAM_MIRROR}" \
    "${BUILD_DIR}/lorax"

repo_args=(
    "--releasever=${OS_RELEASE}"
    "--setopt=cachedir=${BUILD_DIR}/dnf-cache"
    "--setopt=keepcache=True"
    "--repofrompath=base,${BASE_MIRROR}"
    "--repofrompath=appstream,${APPSTREAM_MIRROR}"
)
for repository in ${EXTRA_REPOS}; do
    repo_args+=("--repofrompath=${repository}")
done

mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "${PACKAGE_LIST}")
dnf "${repo_args[@]}" download --resolve --alldeps \
    --destdir="${BUILD_DIR}/Packages" "${packages[@]}"
mkdir -p "${BUILD_DIR}/lorax/Packages"
cp "${BUILD_DIR}/Packages"/*.rpm "${BUILD_DIR}/lorax/Packages/"
createrepo_c "${BUILD_DIR}/lorax/Packages"

iso="${OUTPUT_DIR}/${PRODUCT_NAME}-${OS_FAMILY}-${OS_RELEASE}-${ARCH}-hybrid.iso"
[[ -f "${BUILD_DIR}/lorax/isolinux/isolinux.bin" || -f "${BUILD_DIR}/lorax/images/efiboot.img" ]] || {
    echo "lorax output has no BIOS or UEFI boot image" >&2
    exit 1
}

iso_args=(
    -as mkisofs
    -r -J -joliet-long -iso-level 3
    -V "${PRODUCT_NAME}-${OS_FAMILY}-${OS_RELEASE}"
    -o "${iso}"
)
if [[ -f "${BUILD_DIR}/lorax/isolinux/isolinux.bin" ]]; then
    iso_args+=(
        -c isolinux/boot.cat
        -b isolinux/isolinux.bin
        -no-emul-boot
        -boot-load-size 4
        -boot-info-table
    )
fi
if [[ -f "${BUILD_DIR}/lorax/images/efiboot.img" ]]; then
    iso_args+=(
        -eltorito-alt-boot
        -e images/efiboot.img
        -no-emul-boot
    )
fi

isohybrid_mbr="${ISOHYBRID_MBR:-}"
if [[ -z "${isohybrid_mbr}" ]]; then
    for candidate in \
        /usr/share/syslinux/isohdpfx.bin \
        /usr/lib/ISOLINUX/isohdpfx.bin \
        /usr/lib/syslinux/isohdpfx.bin; do
        if [[ -f "${candidate}" ]]; then
            isohybrid_mbr="${candidate}"
            break
        fi
    done
fi
if [[ -n "${isohybrid_mbr}" ]]; then
    iso_args+=(
        -isohybrid-mbr "${isohybrid_mbr}"
        -isohybrid-gpt-basdat
    )
fi

xorriso "${iso_args[@]}" "${BUILD_DIR}/lorax"

if [[ -z "${isohybrid_mbr}" ]]; then
    command -v isohybrid >/dev/null 2>&1 || {
        echo "isohybrid or a syslinux isohdpfx.bin is required for a USB-bootable ISO" >&2
        exit 2
    }
    isohybrid --uefi "${iso}" 2>/dev/null || isohybrid "${iso}"
fi
echo "${iso}"
