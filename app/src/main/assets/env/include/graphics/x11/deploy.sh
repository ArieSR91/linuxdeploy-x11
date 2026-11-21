#!/bin/sh
# Linux Deploy Component
# (c) Anton Skshidlevsky <meefik@gmail.com>, GPLv3
#
# The X server is Termux:X11 (libXlorie.so + CmdEntryPoint), it is built into the Linux Deploy
# application. The server runs as root from the APK of the application and creates the unix socket
# ${CHROOT_DIR}/tmp/.X11-unix/X<N>, which is /tmp/.X11-unix/X<N> inside the container.
# The display is the "Termux X11" screen of the application.

[ -n "${X11_DISPLAY}" ] || X11_DISPLAY="0"
X11_APP_ID="ru.meefik.linuxdeploy"
X11_PID_FILE="/tmp/x11server.pid"
X11_LOG_FILE="/tmp/x11server.log"

do_install()
{
    msg ":: Installing ${COMPONENT} ... "
    # keyboard layouts are required by the X server
    case "${DISTRIB}:${ARCH}:${SUITE}" in
    debian:*|ubuntu:*|kali:*)
        apt_install xkb-data
    ;;
    archlinux:*)
        pacman_install xkeyboard-config
    ;;
    fedora:*)
        dnf_install xkeyboard-config
    ;;
    centos:*|rocky:*|almalinux:*)
        yum_install xkeyboard-config
    ;;
    alpine:*)
        apk_install xkeyboard-config
    ;;
    esac
    return 0
}

# Find the directory with the keyboard layouts inside of the container
x11_xkb_root()
{
    local dir
    for dir in /usr/share/X11/xkb /usr/share/xkb /usr/share/xkeyboard-config-2
    do
        if [ -d "${CHROOT_DIR}${dir}/rules" ]; then
            echo "${CHROOT_DIR}${dir}"
            return 0
        fi
    done
    return 1
}

# Start the X server and wait for its socket
x11_server_start()
{
    is_started ${X11_PID_FILE} && return 0

    local app_process="${X11_APP_PROCESS:-/system/bin/app_process}"
    [ -x "${app_process}" ] || { msg "app_process is not found."; return 1; }

    local apk=$(${X11_PM:-/system/bin/pm} path "${X11_APP_ID}" 2>/dev/null | sed -n 's/^package://p' | head -n 1)
    [ -f "${apk}" ] || { msg "APK of ${X11_APP_ID} is not found."; return 1; }

    local xkb_root=$(x11_xkb_root)
    [ -n "${xkb_root}" ] || { msg "Keyboard layouts (xkb-data/xkeyboard-config) are not installed in the container. Run the installation (Install) of the container again."; return 1; }

    local tmpdir="${CHROOT_DIR}/tmp"
    mkdir -p "${tmpdir}"
    chmod 1777 "${tmpdir}"
    rm -f "${tmpdir}/.X11-unix/X${X11_DISPLAY}" "${tmpdir}/.X${X11_DISPLAY}-lock" "${CHROOT_DIR}${X11_PID_FILE}"

    # sh writes its own PID to the file and replaces itself by the server (exec)
    local starter="echo \$\$ > \"\$1\"; shift; exec \"\$@\""
    local launcher=""
    command -v setsid >/dev/null 2>&1 && launcher="setsid"
    (
        unset LD_LIBRARY_PATH LD_PRELOAD
        export CLASSPATH="${apk}"
        export TMPDIR="${tmpdir}"
        export XDG_RUNTIME_DIR="${tmpdir}"
        export XKB_CONFIG_ROOT="${xkb_root}"
        ${launcher} sh -c "${starter}" sh "${CHROOT_DIR}${X11_PID_FILE}" \
            "${app_process}" -Xnoimage-dex2oat / --nice-name="termux-x11 ${X11_APP_ID} :${X11_DISPLAY}" \
            com.termux.x11.CmdEntryPoint ":${X11_DISPLAY}" \
            >"${CHROOT_DIR}${X11_LOG_FILE}" 2>&1 </dev/null &
    )

    local i=0
    while [ ${i} -lt 30 ]
    do
        [ -S "${tmpdir}/.X11-unix/X${X11_DISPLAY}" ] && return 0
        # the PID file is written by the background shell, give it a time to start
        if [ ${i} -ge 3 ]; then
            is_started ${X11_PID_FILE} || break
        fi
        sleep 1
        i=$((i+1))
    done
    msg "The X server did not start, see ${X11_LOG_FILE} in the container:"
    tail -n 5 "${CHROOT_DIR}${X11_LOG_FILE}" 2>/dev/null
    kill_pids ${X11_PID_FILE}
    return 1
}

do_start()
{
    msg -n ":: Starting ${COMPONENT} ... "
    is_stopped /tmp/xsession.pid
    is_ok "skip" || return 0
    x11_server_start
    is_ok "fail" || return 0
    # the runtime directory must be owned by the user and have 0700 permissions
    local runtime_dir="/tmp/runtime-${USER_NAME}"
    chroot_exec -u root "mkdir -p ${runtime_dir} && chown ${USER_NAME} ${runtime_dir} && chmod 700 ${runtime_dir}"
    # ~/.xinitrc (created by the desktop component) writes /tmp/xsession.pid and runs ~/.xsession,
    # so the selected desktop is used. The output is redirected, otherwise "su -c" waits for
    # the background process and never returns.
    local cmd="export DISPLAY=:${X11_DISPLAY} XDG_RUNTIME_DIR=${runtime_dir}; nohup ~/.xinitrc >/dev/null 2>&1 &"
    chroot_exec -u ${USER_NAME} ${cmd}
    is_ok "fail" "done"
    return 0
}

do_stop()
{
    msg -n ":: Stopping ${COMPONENT} ... "
    kill_pids /tmp/xsession.pid
    kill_pids ${X11_PID_FILE}
    rm -f "${CHROOT_DIR}${X11_PID_FILE}" "${CHROOT_DIR}/tmp/.X11-unix/X${X11_DISPLAY}"
    is_ok "fail" "done"
    return 0
}

do_status()
{
    msg -n ":: ${COMPONENT} ... "
    is_started ${X11_PID_FILE}
    is_ok "stopped" "started"
    return 0
}

do_help()
{
cat <<EOH
   --x11-display="${X11_DISPLAY}"
     Display number of the X server (Termux:X11), default 0.

EOH
}
