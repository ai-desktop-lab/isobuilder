#!/usr/bin/env bash
set -euo pipefail

OS_FAMILY="${OS_FAMILY:-debian}"
OS_RELEASE="${OS_RELEASE:-13}"
ARCH="${ARCH:-x86_64}"
CLOUD_TEMPLATE="${CLOUD_TEMPLATE:-${OS_FAMILY}-${OS_RELEASE}}"
DISK_SIZE="${DISK_SIZE:-20G}"
PRODUCT_NAME="${PRODUCT_NAME:-task-ai-desktop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build/${OS_FAMILY}-${OS_RELEASE}}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output}"
PACKAGE_LIST="${PACKAGE_LIST:-${SCRIPT_DIR}/project/${OS_FAMILY}.list}"

case "${OS_FAMILY}" in
    debian|ubuntu|fedora|rocky) ;;
    *) echo "OS_FAMILY must be debian, ubuntu, fedora or rocky" >&2; exit 2 ;;
esac
[[ -f "${PACKAGE_LIST}" ]] || { echo "missing package list: ${PACKAGE_LIST}" >&2; exit 2; }
for command in virt-builder qemu-img; do
    command -v "${command}" >/dev/null 2>&1 || {
        echo "missing build dependency: ${command}" >&2
        exit 2
    }
done

mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "${PACKAGE_LIST}")
install_args=()
if ((${#packages[@]} > 0)); then
    install_args=(--install "$(IFS=,; echo "${packages[*]}")")
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
output="${OUTPUT_DIR}/${PRODUCT_NAME}-cloud-${OS_FAMILY}-${OS_RELEASE}-${ARCH}.qcow2"
tmp_output="${BUILD_DIR}/image.qcow2"

virt-builder "${CLOUD_TEMPLATE}" \
    --format qcow2 \
    --output "${tmp_output}" \
    --size "${DISK_SIZE}" \
    --hostname "task-ai-desktop" \
    --root-password disabled \
    --mkdir /etc/cloud/cloud.cfg.d \
    --upload "${SCRIPT_DIR}/cloud-init/99-task-ai-desktop.cfg:/etc/cloud/cloud.cfg.d/99-task-ai-desktop.cfg" \
    "${install_args[@]}"

qemu-img convert -O qcow2 -c "${tmp_output}" "${output}"
qemu-img info "${output}"
echo "${output}"
