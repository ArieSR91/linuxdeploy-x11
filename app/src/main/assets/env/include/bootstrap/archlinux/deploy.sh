#!/bin/sh
# Linux Deploy Component
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3
#
# x86_64: official "archlinux" image from Docker Hub (the packages of Arch Linux use zstd,
#         which busybox cannot unpack, so the old package-by-package installer does not work).
# ARM:    root file system of Arch Linux ARM (ArchLinuxARM-<arch>-latest.tar.gz).

. "${INCLUDE_DIR}/bootstrap/docker/pull.sh"

[ -n "${SUITE}" ] || SUITE="latest"

if [ -z "${ARCH}" ]
then
    case "$(get_platform)" in
    x86_64) ARCH="x86_64" ;;
    arm) ARCH="armv7h" ;;
    arm_64) ARCH="aarch64" ;;
    *) ARCH="unsupported" ;;
    esac
fi

if [ -z "${SOURCE_PATH}" ]
then
    case "$(get_platform ${ARCH})" in
    x86_64) SOURCE_PATH="library/archlinux:base" ;;
    arm*) SOURCE_PATH="http://os.archlinuxarm.org/os/" ;;
    esac
fi

pacman_install()
{
    local packages="$@"
    [ -n "${packages}" ] || return 1
    (set -e
        #rm -f ${CHROOT_DIR}/var/lib/pacman/db.lck || true
        chroot_exec -u root pacman -Syu --needed --overwrite="*" --noconfirm ${packages}
        rm -f "${CHROOT_DIR}"/var/cache/pacman/pkg/* || true
    exit 0)
    return $?
}

pacman_repository()
{
    local conf="${CHROOT_DIR}/etc/pacman.conf"
    local mirrorlist="${CHROOT_DIR}/etc/pacman.d/mirrorlist"
    # no free space check on loop devices, no keyring initialization (needs entropy)
    sed -i "s|^[[:space:]]*\(CheckSpace\)|#\1|" "${conf}"
    sed -i "s|^[[:space:]]*SigLevel[[:space:]]*=.*$|SigLevel = Never|" "${conf}"
    # pacman >= 7 sandboxes downloads with Landlock/seccomp, which is not available in Android kernels
    if grep -qa "DisableSandbox" "${CHROOT_DIR}/usr/bin/pacman" 2>/dev/null; then
        sed -i "/^[[:space:]]*DisableSandbox/d" "${conf}"
        sed -i "s|^\[options\]|[options]\nDisableSandbox|" "${conf}"
    fi
    if [ "$(get_platform ${ARCH})" = "x86_64" ]; then
        if ! grep -q "^[[:space:]]*Server" "${mirrorlist}"; then
            echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> "${mirrorlist}"
        fi
    fi
}

do_install()
{
    is_archive "${SOURCE_PATH}" && return 0

    msg ":: Installing ${COMPONENT} ... "

    case "$(get_platform ${ARCH})" in
    x86_64)
        # settings of the old versions contain a URL of a mirror instead of the image name
        case "${SOURCE_PATH}" in
        ""|http*|ftp*) SOURCE_PATH="library/archlinux:base" ;;
        esac
        local image="${SOURCE_PATH%%:*}"
        local tag="base"
        case "${SOURCE_PATH}" in
        *:*) tag="${SOURCE_PATH##*:}" ;;
        esac
        docker_pull "${image}" "${tag}" "amd64" || return 1
    ;;
    arm*)
        local arch_name
        case "${ARCH}" in
        aarch64) arch_name="aarch64" ;;
        armv6h|arm) arch_name="armv6" ;;
        *) arch_name="armv7" ;;
        esac
        # only the host of Arch Linux ARM is supported here (an old package mirror is replaced)
        case "${SOURCE_PATH}" in
        http*/os/|http*/os) ;;
        *) SOURCE_PATH="http://os.archlinuxarm.org/os/" ;;
        esac
        msg -n "Retrieving rootfs archive ... "
        wget -q -O - "${SOURCE_PATH%/}/ArchLinuxARM-${arch_name}-latest.tar.gz" | tar xz -C "${CHROOT_DIR}"
        is_ok "fail" "done" || return 1
    ;;
    *)
        msg "Architecture ${ARCH} is not supported."
        return 1
    ;;
    esac

    component_exec core/emulator core/mnt core/net

    msg -n "Updating repository ... "
    pacman_repository
    is_ok "fail" "done"

    msg "Installing packages: "
    pacman_install sudo ${EXTRA_PACKAGES}
    is_ok || return 1

    return 0
}

do_help()
{
cat <<EOF
   --arch="${ARCH}"
     Architecture of Linux distribution, supported "armv6h", "armv7h", "aarch64" and "x86_64".

   --source-path="${SOURCE_PATH}"
     Installation source. For x86_64 it is a name of the Docker Hub image (e.g. "library/archlinux:base"),
     for ARM it is the address of Arch Linux ARM (e.g. "http://os.archlinuxarm.org/os/").
     It also can be a path to the rootfs archive.

   --extra-packages="${EXTRA_PACKAGES}"
     List of optional installation packages, separated by spaces.

EOF
}
