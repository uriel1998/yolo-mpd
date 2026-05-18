#!/bin/bash

set -u

usage() {
    echo "Usage: $0 [--dry-run] [ROOT_DIR]"
}

DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

ROOT_DIR="$1"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FIX_COVERS="${SCRIPT_DIR}/f_fix_covers.sh"
MATCHED_DIRS=0

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

while IFS= read -r -d '' cover_file; do
    width=$(identify -format '%w' "${cover_file}" 2>/dev/null)
    height=$(identify -format '%h' "${cover_file}" 2>/dev/null)

    if [ -z "${width}" ] || [ -z "${height}" ]; then
        echo "Skipping unreadable image: ${cover_file}"
        continue
    fi

    if [ "${width}" -ne "${height}" ]; then
        cover_dir=$(dirname "${cover_file}")
        MATCHED_DIRS=$((MATCHED_DIRS + 1))
        echo "Non-square cover found: ${cover_file} (${width}x${height})"
        if [ "${DRY_RUN}" -eq 1 ]; then
            printf 'Would run: %q %q %q %q %q %q %q %q\n' \
                "${FIX_COVERS}" "-l" "-c" "-e" "-r" "-a" "-d" "${cover_dir}"
        else
        	echo "## running on ${cover_dir}"
            "${FIX_COVERS}" -c -l -r -e -a -d "${cover_dir}"
        fi
    fi
done < <(find "${ROOT_DIR}" -type f -name 'cover.jpg' -print0)

echo "Matched directories: ${MATCHED_DIRS}"
