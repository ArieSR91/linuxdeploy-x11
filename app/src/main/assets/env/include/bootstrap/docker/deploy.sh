#!/bin/sh
# Linux Deploy Component
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3

. "${INCLUDE_DIR}/bootstrap/docker/pull.sh"

[ -n "${SUITE}" ] || SUITE="linux"

if [ -z "${ARCH}" ]
then
    case "$(get_platform)" in
    x86) ARCH="386" ;;
    x86_64) ARCH="amd64" ;;
    arm) ARCH="arm" ;;
    arm_64) ARCH="arm64" ;;
    esac
fi

[ -n "${SOURCE_PATH}" ] || SOURCE_PATH="library/ubuntu:24.04"

do_install()
{
    msg ":: Installing ${COMPONENT} ... "

    local image="${SOURCE_PATH%%:*}"
    local tag="latest"
    case "${SOURCE_PATH}" in
    *:*) tag="${SOURCE_PATH##*:}" ;;
    esac

    docker_pull "${image}" "${tag}" "${ARCH}" "${SUITE}" || return 1

    return 0
}

do_help()
{
cat <<EOF
   --arch="${ARCH}"
     Architecture of the container, supported "arm", "arm64", "386" and "amd64".

   --suite="${SUITE}"
     OS of the container, supported "linux".

   --source-path="${SOURCE_PATH}"
     Installation source, can specify name and version of the container, e.g. "library/ubuntu:24.04".

EOF
}
