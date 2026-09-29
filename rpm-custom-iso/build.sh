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

iso="${OUTPUT_DIR}/${PRODUCT_NAME}-${OS_FAMILY}-${OS_RELEASE}-${ARCH}.iso"
xorriso -as mkisofs -r -J -joliet-long \
    -V "${PRODUCT_NAME}-${OS_FAMILY}-${OS_RELEASE}" \
    -o "${iso}" "${BUILD_DIR}/lorax"
echo "${iso}"
