#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)
cd "${SCRIPT_DIR}"

if docker compose version >/dev/null 2>&1; then
    compose='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
    compose='docker-compose'
else
    echo 'Docker Compose v2 or docker-compose is required.' >&2
    exit 1
fi

mkdir -p "${SCRIPT_DIR}/../libwdi/dist" "${SCRIPT_DIR}/dist"

# Docker-outside-of-Docker note:
# act on Windows copies the repository into its Linux runner at /mnt/<drive>/...
# but the Docker Desktop daemon sees the real Windows checkout through
# /host_mnt/<drive>/... (or /run/desktop/mnt/host/<drive>/...). Runtime bind
# mounts must therefore use a daemon-visible path, not GITHUB_WORKSPACE.
DAEMON_REPO_ROOT="${REPO_ROOT}"
HOST_REMAPPED=0
case "${REPO_ROOT}" in
    /mnt/[a-z]/*)
        drive=$(printf '%s' "${REPO_ROOT}" | cut -d/ -f3)
        rest=$(printf '%s' "${REPO_ROOT}" | cut -d/ -f4-)
        for probe in \
            "/host_mnt/${drive}/${rest}" \
            "/run/desktop/mnt/host/${drive}/${rest}"
        do
            if docker run --rm -v "${probe}:/probe:ro" alpine:3.24.2 \
                test -f /probe/CMakeLists.txt >/dev/null 2>&1; then
                DAEMON_REPO_ROOT="${probe}"
                HOST_REMAPPED=1
                break
            fi
        done
        ;;
esac

# Ensure output directories exist from the Docker daemon's point of view before
# Compose tries to bind-mount them. This is especially important for Docker
# Desktop/act where the runner and daemon do not share the same root filesystem.
docker run --rm -v "${DAEMON_REPO_ROOT}:/repo" alpine:3.24.2 sh -eu -c '
    mkdir -p /repo/externals/libwdi/dist /repo/externals/xilinx-usb-driver/dist
'

LIBWDI_HOST_SRC=${LIBWDI_HOST_SRC:-${DAEMON_REPO_ROOT}/externals/libwdi}
LIBWDI_HOST_DIST=${LIBWDI_HOST_DIST:-${DAEMON_REPO_ROOT}/externals/libwdi/dist}
XPCU_HOST_DIST=${XPCU_HOST_DIST:-${DAEMON_REPO_ROOT}/externals/xilinx-usb-driver/dist}
export LIBWDI_HOST_SRC LIBWDI_HOST_DIST XPCU_HOST_DIST

echo "[xpcu] repository visible to Docker daemon: ${DAEMON_REPO_ROOT}"
echo "[xpcu] libwdi source: ${LIBWDI_HOST_SRC}"
echo "[xpcu] libwdi output: ${LIBWDI_HOST_DIST}"
echo "[xpcu] package output: ${XPCU_HOST_DIST}"

cleanup() {
    $compose down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

status=0
$compose up --build --abort-on-container-exit --exit-code-from package package || status=$?

if [ "${status}" -ne 0 ]; then
    echo '[xpcu] build failed; preserving service logs before cleanup' >&2
    $compose logs --no-color libwdi-x86 libwdi-x64 package >&2 || true
    exit "${status}"
fi

# Verify the canonical driver package from the daemon-visible output directory.
docker run --rm -v "${XPCU_HOST_DIST}:/drivers:ro" alpine:3.24.2 sh -eu -c '
    cd /drivers
    test -s xilinx-platform-cable-windows.zip
    test -s xilinx-platform-cable-windows.zip.sha256
    sha256sum -c xilinx-platform-cable-windows.zip.sha256
'

echo '[xpcu] canonical Windows driver package built and checksum verified'
