#!/bin/sh
# Linux Deploy Component (shared helper)
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3
#
# Download an image from Docker Hub and unpack its layers to ${CHROOT_DIR}.
# Used by the "docker" bootstrap and by the distributions that are installed from
# the official Docker Hub images (Fedora, Rocky Linux, AlmaLinux, Arch Linux x86_64,
# Debian >= 12 and Ubuntu >= 22.04, whose packages cannot be unpacked by busybox).
#
# usage: docker_pull <image> <tag> <arch> [os] [variant]
#   image   e.g. library/fedora
#   tag     e.g. 43
#   arch    docker architecture: arm, arm64, 386, amd64
#   os      default linux
#   variant optional, e.g. v7 or v5 for 32-bit arm

docker_pull()
{
    local image="$1" tag="$2" arch="$3" os="${4:-linux}" variant="$5"
    [ -n "${tag}" ] || tag="latest"
    local registry="https://registry-1.docker.io/v2/${image}"
    local accept_list="application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.index.v1+json"
    local accept_one="application/vnd.docker.distribution.manifest.v2+json,application/vnd.oci.image.manifest.v1+json"

    msg -n "Authorization in Docker repository ... "
    local token=$(wget -q -O - "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${image}:pull" | grep -oE '"token":"[.a-zA-Z0-9_-]+"' | tr -d '"' | awk -F':' '{print $2}')
    test -n "${token}"
    is_ok "fail" "done" || return 1

    msg -n "Fetching manifests from the repository ... "
    local entries=$(wget -q -O - --header "Authorization: Bearer ${token}" --header "Accept: ${accept_list}" "${registry}/manifests/${tag}" | tr -d '\n\r\t ' | sed 's/},{/\n/g' | grep "\"architecture\":\"${arch}\"" | grep "\"os\":\"${os}\"")
    local manifest=""
    if [ -n "${variant}" ]; then
        manifest=$(echo "${entries}" | grep "\"variant\":\"${variant}\"" | grep -oE 'sha256:[a-f0-9]{64}' | head -n1)
    fi
    [ -n "${manifest}" ] || manifest=$(echo "${entries}" | grep -oE 'sha256:[a-f0-9]{64}' | head -n1)
    test -n "${manifest}"
    is_ok "fail" "done" || return 1

    msg -n "Fetching the list of layers ... "
    local layers=$(wget -q -O - --header "Authorization: Bearer ${token}" --header "Accept: ${accept_one}" "${registry}/manifests/${manifest}" | tr '\n' ' ' | tr '{}' '\n\n' | grep -E 'tar.gzip' | grep -oE 'sha256:[0-9a-f]{64}')
    test -n "${layers}"
    is_ok "fail" "done" || return 1

    msg "Retrieving rootfs blobs: "
    local digest
    for digest in ${layers}
    do
        msg -n " * ${digest} ... "
        wget -q -O - --header "Authorization: Bearer ${token}" "${registry}/blobs/${digest}" | tar xz -C "${CHROOT_DIR}"
        is_ok "fail" "done" || return 1
    done

    return 0
}

# Convert an architecture name of a distribution to the Docker one
docker_arch()
{
    case "$1" in
    aarch64|arm64|armv8*) echo "arm64" ;;
    x86_64|amd64) echo "amd64" ;;
    armhfp|armhf|armv7*|armel|arm) echo "arm" ;;
    i386|i686|x86|386) echo "386" ;;
    *) echo "$1" ;;
    esac
}
