#!/bin/sh
# Linux Deploy Component (shared helper for RPM based distributions)
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3
#
# Fedora, Rocky Linux and AlmaLinux are installed from the official images of
# Docker Hub: a regular rpm2cpio of busybox cannot unpack the zstd packages
# which are used by modern RPM distributions.

. "${INCLUDE_DIR}/bootstrap/docker/pull.sh"

dnf_install()
{
    local packages="$@"
    [ -n "${packages}" ] || return 1
    (set -e
        chroot_exec -u root dnf -y install --setopt=strict=0 --setopt=install_weak_deps=False ${packages}
        chroot_exec -u root dnf clean all
    exit 0)
    return $?
}

# compatibility with the components written for CentOS
yum_install()
{
    dnf_install "$@"
}

yum_groupinstall()
{
    local groupname="$@"
    [ -n "${groupname}" ] || return 1
    (set -e
        chroot_exec -u root dnf -y group install --setopt=install_weak_deps=False ${groupname}
        chroot_exec -u root dnf clean all
    exit 0)
    return $?
}

# usage: rpm_bootstrap <default image>
rpm_bootstrap()
{
    local default_image="$1"

    is_archive "${SOURCE_PATH}" && return 0

    msg ":: Installing ${COMPONENT} ... "

    # settings of the old versions contain a URL of a mirror instead of the image name
    case "${SOURCE_PATH}" in
    ""|http*|ftp*) SOURCE_PATH="${default_image}" ;;
    esac

    local image="${SOURCE_PATH%%:*}"
    local tag="${SUITE}"
    case "${SOURCE_PATH}" in
    *:*) tag="${SOURCE_PATH##*:}" ;;
    esac

    docker_pull "${image}" "${tag}" "$(docker_arch ${ARCH})" || return 1

    component_exec core/emulator core/mnt core/net

    msg "Installing packages: "
    dnf_install sudo shadow-utils passwd glibc-langpack-en tzdata ${EXTRA_PACKAGES}
    is_ok || return 1

    return 0
}
