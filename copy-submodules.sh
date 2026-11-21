#!/bin/sh
# The sources of the X server (Termux:X11) use git submodules which are not included in a zip archive.
# Copy them from a complete checkout of Termux:X11 (cloned with --recurse-submodules).
#
# usage: ./copy-submodules.sh /path/to/termux-x11
set -e
SRC="$1"
[ -n "${SRC}" ] && [ -d "${SRC}/lorie/src/main/cpp" ] || { echo "usage: $0 /path/to/termux-x11 (a checkout with submodules)"; exit 1; }
DST="$(cd "$(dirname "$0")" && pwd)/lorie/src/main/cpp"
for path in $(sed -n 's|^[[:space:]]*path = lorie/src/main/cpp/||p' "$(dirname "$0")/.gitmodules"); do
    if [ -z "$(ls -A "${SRC}/lorie/src/main/cpp/${path}" 2>/dev/null)" ]; then
        echo "ERROR: ${SRC}/lorie/src/main/cpp/${path} is empty - run: git submodule update --init --recursive"
        exit 1
    fi
    rm -rf "${DST}/${path}"
    cp -a "${SRC}/lorie/src/main/cpp/${path}" "${DST}/${path}"
    echo "copied ${path}"
done
echo "done"
