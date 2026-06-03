#!/bin/bash

########################################################################
# This script is designed as a wrapper for LOUDGAIN that handles errors
# gracefully while preserving each file's modification time.
#
# It batches work per directory for speed and uses null-delimited file
# handling throughout so unusual filenames are processed safely.
########################################################################

noclobber_mode=0
declare -a input_patterns startdirs

has_glob_chars() {
    [[ $1 == *[\*\?\[]* ]]
}

add_startdir_literal() {
    local path=$1

    if [[ -d $path ]]; then
        startdirs+=("$(realpath -- "$path")")
        return 0
    fi

    if [[ -e $path ]]; then
        printf 'Skipping non-directory path: %s\n' "$path" >&2
        return 0
    fi

    echo "Not a valid directory: $path" >&2
    return 1
}

add_startdirs_from_pattern() {
    local pattern=$1
    local base name
    local -a matches

    if [[ -e $pattern ]]; then
        add_startdir_literal "$pattern"
        return $?
    fi

    if ! has_glob_chars "$pattern"; then
        echo "Not a valid directory: $pattern" >&2
        return 1
    fi

    base=${pattern%/*}
    name=${pattern##*/}

    if [[ $base == "$pattern" ]]; then
        base=.
    elif [[ -z $base ]]; then
        base=/
    fi

    if [[ ! -d $base ]]; then
        echo "Wildcard base directory does not exist: $base" >&2
        return 1
    fi

    mapfile -d '' -t matches < <(
        find "$base" -mindepth 1 -maxdepth 1 -type d -iname "$name" -print0 | sort -z
    )

    if (( ${#matches[@]} == 0 )); then
        echo "No matching directories for pattern: $pattern" >&2
        return 1
    fi

    local match
    for match in "${matches[@]}"; do
        startdirs+=("$(realpath -- "$match")")
    done
}

while (( $# > 0 )); do
    case $1 in
        --noclobber)
            noclobber_mode=1
            shift
            ;;
        --help|-h)
            cat <<'EOF'
Usage: mp3gainhelper.sh [--noclobber] [DIRECTORY ...]

  --noclobber  Skip a directory when every MP3 in it already has both
               ReplayGainTrackGain and ReplayGainAlbumGain tags.
  DIRECTORY     One or more directories or wildcard patterns. Patterns are
                matched case-insensitively against directories.
EOF
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            input_patterns+=("$1")
            shift
            ;;
    esac
done

if (( $# > 0 )); then
    input_patterns+=("$@")
fi

if (( ${#input_patterns[@]} == 0 )); then
    startdirs+=("$(realpath -- "$PWD")")
else
    for pattern in "${input_patterns[@]}"; do
        add_startdirs_from_pattern "$pattern" || exit 1
    done
fi

mapfile -t startdirs < <(printf '%s\n' "${startdirs[@]}" | sort -u)
printf '%s\n' "${startdirs[@]}"

max_jobs=${MAX_JOBS:-$(nproc 2>/dev/null || echo 8)}
if ! [[ $max_jobs =~ ^[1-9][0-9]*$ ]]; then
    max_jobs=8
fi

max_jobs=$((max_jobs-4))

process_dir() {
    local dir=$1
    local -a files stamp_files
    local file stamp_dir stamp_file loudgain_status=0
    local missing_replaygain

    mapfile -d '' -t files < <(find "$dir" -maxdepth 1 -type f -iname '*.mp3' -print0)
    (( ${#files[@]} > 0 )) || return 0

    if (( noclobber_mode )); then
        missing_replaygain=$(
            exiftool -q -q \
                -if 'not defined $replaygaintrackgain or not defined $replaygainalbumgain' \
                -p 1 -- "${files[@]}"
        )

        if [[ -z $missing_replaygain ]]; then
            printf 'Skipping already tagged directory: %s\n' "$dir" >&2
            return 0
        fi
    fi

    stamp_dir=$(mktemp -d) || return 1

    for file in "${files[@]}"; do
        stamp_file=$(mktemp "$stamp_dir/stamp.XXXXXX") || {
            rm -rf -- "$stamp_dir"
            return 1
        }
        touch -r "$file" -- "$stamp_file"
        stamp_files+=("$stamp_file")
    done

    loudgain -I3 -S -L -a -k -s e -- "${files[@]}"
    loudgain_status=$?

    for i in "${!files[@]}"; do
        touch -r "${stamp_files[$i]}" -- "${files[$i]}"
    done

    rm -rf -- "$stamp_dir"
    return "$loudgain_status"
}

watchcount=0
while IFS= read -r -d '' dir; do
    process_dir "$dir" &
    ((watchcount += 1))

    if (( watchcount >= max_jobs )); then
        wait -n
        ((watchcount -= 1))
    fi
done < <(
    find "${startdirs[@]}" -type f -iname '*.mp3' -printf '%h\0' | sort -zu
)

wait
