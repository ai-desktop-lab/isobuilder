#!/usr/bin/env bash
set -euo pipefail

OS_FAMILY="${OS_FAMILY:-debian}"
OS_RELEASE="${OS_RELEASE:-13}"
ARCH="${ARCH:-amd64}"
BASE_IMAGE="${BASE_IMAGE:-${OS_FAMILY}:${OS_RELEASE}}"
PRODUCT_NAME="${PRODUCT_NAME:-task-ai-desktop}"
IMAGE_TAG="${IMAGE_TAG:-${PRODUCT_NAME}:${OS_FAMILY}-${OS_RELEASE}}"
OUTPUT_DIR="${OUTPUT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/output}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DESKTOP_DEB_DIR="${AI_DESKTOP_DEB_DIR:-}"

case "${OS_FAMILY}" in
    debian|ubuntu|fedora|rocky) ;;
    *) echo "OS_FAMILY must be debian, ubuntu, fedora or rocky" >&2; exit 2 ;;
esac

if [[ -z "${CONTAINER_RUNTIME}" ]]; then
    if command -v podman >/dev/null 2>&1; then
        CONTAINER_RUNTIME=podman
    elif command -v docker >/dev/null 2>&1; then
        CONTAINER_RUNTIME=docker
    else
        echo "missing container runtime: install podman or docker" >&2
        exit 2
    fi
fi
command -v "${CONTAINER_RUNTIME}" >/dev/null 2>&1 || {
    echo "missing container runtime: ${CONTAINER_RUNTIME}" >&2
    exit 2
}

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${SCRIPT_DIR}/debs"
rm -f "${SCRIPT_DIR}/debs"/*.deb
if [[ -n "${AI_DESKTOP_DEB_DIR}" ]]; then
    [[ -d "${AI_DESKTOP_DEB_DIR}" ]] || {
        echo "AI_DESKTOP_DEB_DIR is not a directory: ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
    compgen -G "${AI_DESKTOP_DEB_DIR}/*.deb" >/dev/null || {
        echo "AI_DESKTOP_DEB_DIR has no .deb files: ${AI_DESKTOP_DEB_DIR}" >&2
        exit 2
    }
    cp "${AI_DESKTOP_DEB_DIR}"/*.deb "${SCRIPT_DIR}/debs/"
fi
"${CONTAINER_RUNTIME}" build \
    --file "${SCRIPT_DIR}/Containerfile" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "OS_FAMILY=${OS_FAMILY}" \
    --tag "${IMAGE_TAG}" \
    "${SCRIPT_DIR}"

archive="${OUTPUT_DIR}/${PRODUCT_NAME}-container-${OS_FAMILY}-${OS_RELEASE}-${ARCH}.oci.tar"
if [[ "${CONTAINER_RUNTIME}" == podman ]]; then
    "${CONTAINER_RUNTIME}" save --format oci-archive --output "${archive}" "${IMAGE_TAG}"
else
    # Docker's save archive is accepted by Docker, Podman and OCI import tools.
    "${CONTAINER_RUNTIME}" save --output "${archive}" "${IMAGE_TAG}"
fi
echo "${archive}"
