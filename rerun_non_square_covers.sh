#!/bin/bash

set -u

if [ $# -ne 1 ]; then
    echo "Usage: $0 [ROOT_DIR]"
    exit 1
fi

ROOT_DIR="$1"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FIX_COVERS="${SCRIPT_DIR}/f_fix_covers.sh"

if [ ! -d "${ROOT_DIR}" ]; then
    echo "Not a directory: ${ROOT_DIR}"
    exit 1
fi

if [ ! -x "${FIX_COVERS}" ]; then
    echo "Missing or not executable: ${FIX_COVERS}"
    exit 1
fi

if ! command -v identify >/dev/null 2>&1; then
    echo "identify not found in PATH"
    exit 1
fi

find "${ROOT_DIR}" -type f -name 'cover.jpg' -print0 |
while IFS= read -r -d '' cover_file; do
    width=$(identify -format '%w' "${cover_file}" 2>/dev/null)
    height=$(identify -format '%h' "${cover_file}" 2>/dev/null)

    if [ -z "${width}" ] || [ -z "${height}" ]; then
        echo "Skipping unreadable image: ${cover_file}"
        continue
    fi

    if [ "${width}" -ne "${height}" ]; then
        cover_dir=$(dirname "${cover_file}")
        echo "Non-square cover found: ${cover_file} (${width}x${height})"
        "${FIX_COVERS}" -l -c -e -r -a -d "${cover_dir}"
    fi
done
