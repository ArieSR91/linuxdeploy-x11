#!/bin/sh
# Linux Deploy Component
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3

. "${INCLUDE_DIR}/bootstrap/docker/rpm.sh"

[ -n "${SUITE}" ] || SUITE="9"

if [ -z "${ARCH}" ]
then
    case "$(get_platform)" in
    x86_64) ARCH="x86_64" ;;
    arm_64) ARCH="aarch64" ;;
    *) ARCH="unsupported" ;;
    esac
fi

[ -n "${SOURCE_PATH}" ] || SOURCE_PATH="library/almalinux"

do_install()
{
    rpm_bootstrap "library/almalinux"
}

do_help()
{
cat <<EOF
   --arch="${ARCH}"
     Architecture of Linux distribution, supported "aarch64" and "x86_64".

   --suite="${SUITE}"
     Major version of Linux distribution, supported "8", "9" and "10".

   --source-path="${SOURCE_PATH}"
     Docker Hub image name, e.g. "library/almalinux", or path to the rootfs archive.

   --extra-packages="${EXTRA_PACKAGES}"
     List of optional installation packages, separated by spaces.

EOF
}
