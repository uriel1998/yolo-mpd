#!/usr/bin/env bash

##############################################################################
#
#  I am so so SO tired of lyrics being an issue.
#  (c) Steven Saus 2026
#  Licensed under the MIT license
#
##############################################################################

set -u
set -o pipefail

# Runtime configuration. The script defaults to incremental behavior and only
# broadens scope when `--force` is explicitly requested.
MPD_MUSIC_BASE="${MPD_MUSIC_BASE:-${HOME}/Music}"
LOUD=0
REQUEST_DELAY="0.5"
MAX_RETRIES=4
FORCE=0
LRCLIB_API="https://lrclib.net/api"
LRCLIB_USER_AGENT="f_fix_lyrics/1.0 (local personal music-library tool)"
LYRICTMP=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# This queue persists across runs so an interrupted scan can resume where it
# left off instead of rebuilding state from scratch every time.
QUEUE_FILE="${SCRIPT_DIR}/f_fix_lyrics.queue"
# These indexes are built once at startup to cheaply prune files that already
# have lyric sidecars before the script touches individual MP3 metadata.
declare -A KNOWN_TXT_STEMS=()
declare -A KNOWN_LRC_STEMS=()

##############################################################################
# Output
##############################################################################

loud() {
    # Diagnostic output stays on stderr so stdout can remain clean if the
    # script is ever wrapped or consumed by another tool.
    if (( LOUD == 1 )); then
        printf '%s\n' "$*" >&2
    fi
}

usage() {
    loud "Usage: $(basename "$0") [OPTIONS]"
    loud
    loud "Recursively find MP3 files and create missing lyric sidecars."
    loud
    loud "Options:"
    loud "  -l, --loud             Enable diagnostic output on stderr"
    loud "  -b, --base DIRECTORY   MPD music root (default: \$MPD_MUSIC_BASE or ~/Music)"
    loud "  -f, --force            Recheck files even when lyric sidecars already exist"
    loud "      --delay SECONDS    Delay between LRCLIB requests (default: ${REQUEST_DELAY})"
    loud "  -h, --help             Show this help"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    # Temporary state is disposable; the persistent queue file is intentionally
    # left alone because it is part of the resume mechanism.
    [[ -n "${LYRICTMP}" ]] && rm -rf -- "${LYRICTMP}"
}

trap cleanup EXIT
trap 'loud "Interrupted."; exit 130' INT TERM HUP

##############################################################################
# Utility functions
##############################################################################

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

trim() {
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

normalize() {
    printf '%s' "$1" |
        tr '[:upper:]' '[:lower:]' |
        sed -E \
            -e 's/&/and/g' \
            -e 's/[^[:alnum:]]+/ /g' \
            -e 's/^[[:space:]]+//' \
            -e 's/[[:space:]]+$//' \
            -e 's/[[:space:]]+/ /g'
}

has_lrc_timestamps() {
    # LRC lines begin with timestamps like `[01:23.45]`; this keeps synced and
    # plain lyrics from being mixed up later in the pipeline.
    grep -Eq '^\[[0-9]{1,3}:[0-9]{2}([.:][0-9]{1,3})?\]' "$1"
}

write_nonempty_file() {
    local source_file="$1"
    local destination_file="$2"
    local temporary_file="${destination_file}.tmp.$$"

    # Refuse to overwrite a destination with an empty extraction result.
    [[ -s "${source_file}" ]] || return 1

    # Normalize CRLF while staging, then replace the real file atomically.
    sed 's/\r$//' "${source_file}" > "${temporary_file}"

    if [[ ! -s "${temporary_file}" ]]; then
        rm -f -- "${temporary_file}"
        return 1
    fi

    mv -- "${temporary_file}" "${destination_file}"
}

needs_processing() {
    local song_file="$1"
    local song_base="${song_file%.*}"
    local lrc_file="${song_base}.lrc"
    local txt_file="${song_base}.txt"

    # Force mode intentionally reconsiders every MP3 regardless of sidecars.
    if (( FORCE == 1 )); then
        return 0
    fi

    # Only skip fully satisfied tracks. If either sidecar is missing, the track
    # still has remaining work.
    if [[ -f "${txt_file}" && -f "${lrc_file}" ]]; then
        return 1
    fi
    return 0
}

count_lines() {
    local file_path="$1"

    [[ -f "${file_path}" ]] || {
        echo 0
        return 0
    }

    awk 'END { print NR + 0 }' "${file_path}"
}

count_pending_operations() {
    local song_file="$1"
    local song_base="${song_file%.*}"
    local lrc_file="${song_base}.lrc"
    local txt_file="${song_base}.txt"
    local operations=0

    # Force mode rechecks both artifacts for every track in scope.
    if (( FORCE == 1 )); then
        echo 2
        return 0
    fi

    [[ -f "${lrc_file}" ]] || ((operations++))
    [[ -f "${txt_file}" ]] || ((operations++))

    echo "${operations}"
}

count_operations_in_list() {
    local list_file="$1"
    local song_file=""
    local total=0
    local operations=0

    [[ -f "${list_file}" ]] || {
        echo 0
        return 0
    }

    while IFS= read -r song_file; do
        [[ -n "${song_file}" ]] || continue
        operations=$(count_pending_operations "${song_file}")
        ((total += operations))
    done < "${list_file}"

    echo "${total}"
}

index_existing_sidecars() {
    local lyric_file=""
    local stem=""

    KNOWN_TXT_STEMS=()
    KNOWN_LRC_STEMS=()

    # Pre-indexing sidecars front-loads the cost of `find` once and avoids many
    # repeated filesystem checks during queue construction.
    loud "Indexing existing .txt lyric sidecars under ${MPD_MUSIC_BASE}"
    while IFS= read -r -d '' lyric_file; do
        stem="${lyric_file%.*}"
        KNOWN_TXT_STEMS["${stem}"]=1
    done < <(
        find "${MPD_MUSIC_BASE}" -type f -iname '*.txt' -print0
    )

    loud "Indexing existing .lrc lyric sidecars under ${MPD_MUSIC_BASE}"
    while IFS= read -r -d '' lyric_file; do
        stem="${lyric_file%.*}"
        KNOWN_LRC_STEMS["${stem}"]=1
    done < <(
        find "${MPD_MUSIC_BASE}" -type f -iname '*.lrc' -print0
    )
}

should_queue_song() {
    local song_file="$1"
    local song_base="${song_file%.*}"

    if (( FORCE == 1 )); then
        return 0
    fi

    # Skip only when both sidecar forms already exist for the same stem.
    if [[ -n "${KNOWN_TXT_STEMS[${song_base}]+x}" &&
          -n "${KNOWN_LRC_STEMS[${song_base}]+x}" ]]; then
        return 1
    fi

    return 0
}

remove_first_queue_entry() {
    local queue_file="$1"
    local song_file="$2"
    local temp_queue

    [[ -f "${queue_file}" ]] || return 0

    temp_queue="${queue_file}.tmp.$$"
    # Remove only the first matching queue item so duplicate paths, while not
    # expected, still preserve stable resume semantics.
    awk -v target="${song_file}" '
        BEGIN { removed = 0 }
        {
            if (!removed && $0 == target) {
                removed = 1
                next
            }
            print
        }
    ' "${queue_file}" > "${temp_queue}" && mv -- "${temp_queue}" "${queue_file}"
}

build_queue_file() {
    local song_file=""

    loud "Building queue file: ${QUEUE_FILE}"
    : > "${QUEUE_FILE}"

    # The persistent queue only stores work that is still relevant right now.
    while IFS= read -r -d '' song_file; do
        if should_queue_song "${song_file}" && needs_processing "${song_file}"; then
            printf '%s\n' "${song_file}" >> "${QUEUE_FILE}"
        fi
    done < <(
        find "${MPD_MUSIC_BASE}" -type f -iname '*.mp3' -print0
    )
}

build_work_list() {
    local output_file="$1"
    local song_file=""

    : > "${output_file}"

    # This mirrors queue filtering for the live-scan fallback path used only if
    # the persisted queue is deleted during a run.
    while IFS= read -r -d '' song_file; do
        if should_queue_song "${song_file}" && needs_processing "${song_file}"; then
            printf '%s\n' "${song_file}" >> "${output_file}"
        fi
    done < <(
        find "${MPD_MUSIC_BASE}" -type f -iname '*.mp3' -print0
    )
}

##############################################################################
# ExifTool metadata and embedded lyrics
##############################################################################

read_metadata() {
    local song_file="$1"

    # ExifTool handles mixed tag formats reliably; jq normalizes the shape into
    # a compact object with a rounded duration in seconds.
    exiftool -j -charset ID3=UTF8 \
        -Title -Artist -Album -Duration# \
        -- "${song_file}" 2>/dev/null |
        jq -c '.[0] | {
            title: (.Title // ""),
            artist: (.Artist // ""),
            album: (.Album // ""),
            duration: ((.Duration // 0) | tonumber? // 0 | round)
        }'
}

extract_embedded_synced() {
    local song_file="$1"
    local output_file="$2"
    local extracted="${LYRICTMP}/embedded-synced"

    # Reuse one temp file and try the most specific synced-lyrics tags first.
    : > "${extracted}"

    # Native ID3 SYLT frame. ExifTool prefixes each item with an LRC-like
    # timestamp when SynchronizedLyricsText is extracted.
    exiftool -b -charset ID3=UTF8 \
        -SynchronizedLyricsText \
        -- "${song_file}" > "${extracted}" 2>/dev/null || true

    if [[ -s "${extracted}" ]] && has_lrc_timestamps "${extracted}"; then
        write_nonempty_file "${extracted}" "${output_file}"
        return
    fi

    # Some taggers misuse the generic Lyrics field for timestamped LRC data, so
    # accept it only if it actually looks synchronized.
    # Some tagging programs put timestamped LRC content in USLT/Lyrics.
    exiftool -b -charset ID3=UTF8 \
        -Lyrics \
        -- "${song_file}" > "${extracted}" 2>/dev/null || true

    if [[ -s "${extracted}" ]] && has_lrc_timestamps "${extracted}"; then
        write_nonempty_file "${extracted}" "${output_file}"
        return
    fi

    return 1
}

extract_embedded_plain() {
    local song_file="$1"
    local output_file="$2"
    local extracted="${LYRICTMP}/embedded-plain"

    exiftool -b -charset ID3=UTF8 \
        -Lyrics \
        -- "${song_file}" > "${extracted}" 2>/dev/null || true

    # If there is no embedded lyric payload at all, stop quickly.
    [[ -s "${extracted}" ]] || return 1

    # Timestamped content belongs in .lrc, never in the plain-text sidecar.
    has_lrc_timestamps "${extracted}" && return 1

    write_nonempty_file "${extracted}" "${output_file}"
}

convert_lrc_to_plaintext() {
    local lrc_file="$1"
    local output_file="$2"
    local extracted="${LYRICTMP}/converted-plain"

    # Stage the stripped lyrics in a real temp file so downstream size checks
    # behave consistently; process substitution here was too brittle.
    sed 's/^\[[0-9][0-9]*:[0-9][0-9]\([.:][0-9][0-9]*\)\?\][[:space:]]*//g' \
        "${lrc_file}" > "${extracted}"

    write_nonempty_file "${extracted}" "${output_file}"
}

##############################################################################
# LRCLIB
##############################################################################

lrclib_request() {
    local endpoint="$1"
    shift

    local body_file="${LYRICTMP}/lrclib-body"
    local header_file="${LYRICTMP}/lrclib-headers"
    local attempt=1
    local status=""
    local retry_after=""

    # Centralize LRCLIB retry and pacing logic so exact and search queries use
    # identical transport behavior.
    while (( attempt <= MAX_RETRIES )); do
        : > "${body_file}"
        : > "${header_file}"

        status=$(
            curl --silent --show-error \
                --connect-timeout 15 \
                --max-time 90 \
                --user-agent "${LRCLIB_USER_AGENT}" \
                --dump-header "${header_file}" \
                --output "${body_file}" \
                --write-out '%{http_code}' \
                --get "${LRCLIB_API}/${endpoint}" \
                "$@" 2>/dev/null
        ) || status="000"

        case "${status}" in
            200)
                # Emit the successful body on stdout so callers can redirect it
                # straight into the temp file they want to inspect.
                cat "${body_file}"
                sleep "${REQUEST_DELAY}"
                return 0
                ;;
            404)
                # "Not found" is terminal for this exact request, but still not
                # treated as a script-level failure.
                sleep "${REQUEST_DELAY}"
                return 4
                ;;
            429)
                # Respect server-advertised pacing when present.
                retry_after=$(
                    awk 'BEGIN{IGNORECASE=1}
                         /^Retry-After:/ {
                             gsub("\r", "", $2);
                             print $2;
                             exit
                         }' "${header_file}"
                )
                [[ "${retry_after}" =~ ^[0-9]+$ ]] || retry_after=$(( attempt * 3 ))
                loud "LRCLIB rate limit reached; retrying after ${retry_after}s."
                sleep "${retry_after}"
                ;;
            500|502|503|504|000)
                # Retry transient server and transport failures with backoff.
                loud "LRCLIB request failed with HTTP ${status}; retry ${attempt}/${MAX_RETRIES}."
                sleep $(( attempt * 3 ))
                ;;
            *)
                loud "LRCLIB returned HTTP ${status}; not retrying."
                sleep "${REQUEST_DELAY}"
                return 1
                ;;
        esac

        ((attempt++))
    done

    loud "LRCLIB request failed after ${MAX_RETRIES} attempts."
    return 1
}

save_lrclib_result() {
    local response_file="$1"
    local lrc_file="$2"
    local txt_file="$3"
    local synced_file="${LYRICTMP}/lrclib-synced"
    local plain_file="${LYRICTMP}/lrclib-plain"

    # Prefer synchronized lyrics when the API provides them.
    jq -r '.syncedLyrics // empty' "${response_file}" > "${synced_file}"
    if [[ -s "${synced_file}" ]]; then
        write_nonempty_file "${synced_file}" "${lrc_file}"
        return
    fi

    # Preserve a valid unsynchronized LRCLIB result as the plain-text sidecar.
    # This also prevents an unnecessary embedded-lyrics extraction attempt.
    if [[ ! -e "${txt_file}" ]]; then
        jq -r '.plainLyrics // empty' "${response_file}" > "${plain_file}"
        if [[ -s "${plain_file}" ]]; then
            write_nonempty_file "${plain_file}" "${txt_file}"
            return
        fi
    else
        # A metadata match is still useful even when the plain-text sidecar is
        # already present and LRCLIB has no synced lyrics to save.
        jq -e '(.plainLyrics // "") != ""' "${response_file}" >/dev/null 2>&1 && return 0
    fi

    return 1
}

query_lrclib() {
    local title="$1"
    local artist="$2"
    local album="$3"
    local duration="$4"
    local lrc_file="$5"
    local txt_file="$6"

    local response="${LYRICTMP}/lrclib-response.json"
    local search_response="${LYRICTMP}/lrclib-search.json"
    local selected="${LYRICTMP}/lrclib-selected.json"

    : > "${response}"

    # Start with the exact endpoint because duration-aware matches are the most
    # trustworthy result LRCLIB can return.
    # First try LRCLIB's exact-signature endpoint.
    if lrclib_request get \
        --data-urlencode "track_name=${title}" \
        --data-urlencode "artist_name=${artist}" \
        --data-urlencode "album_name=${album}" \
        --data-urlencode "duration=${duration}" > "${response}"; then

        if jq -e 'type == "object" and (.id != null)' "${response}" >/dev/null 2>&1; then
            loud "LRCLIB exact match found."
            save_lrclib_result "${response}" "${lrc_file}" "${txt_file}"
            return
        fi
    fi

    # Fallback: search and accept a record whose normalized title, artist,
    # and album all match, even when duration does not.
    : > "${search_response}"
    if ! lrclib_request search \
        --data-urlencode "track_name=${title}" \
        --data-urlencode "artist_name=${artist}" \
        --data-urlencode "album_name=${album}" > "${search_response}"; then
        return 1
    fi

    jq \
        --arg title "$(normalize "${title}")" \
        --arg artist "$(normalize "${artist}")" \
        --arg album "$(normalize "${album}")" \
        --argjson duration "${duration}" '
        def norm:
            ascii_downcase
            | gsub("&"; "and")
            | gsub("[^[:alnum:]]+"; " ")
            | gsub("^ +| +$"; "")
            | gsub(" +"; " ");

        map(select(
            ((.trackName // "") | norm) == $title and
            ((.artistName // "") | norm) == $artist and
            ((.albumName // "") | norm) == $album
        ))
        | sort_by(((.duration // 0) - $duration) | fabs)
        | .[0] // empty
    ' "${search_response}" > "${selected}"

    if ! jq -e 'type == "object" and (.id != null)' "${selected}" >/dev/null 2>&1; then
        return 1
    fi

    # If text metadata matches cleanly, duration drift is acceptable.
    loud "LRCLIB metadata match found; accepting duration mismatch."
    save_lrclib_result "${selected}" "${lrc_file}" "${txt_file}"
}

##############################################################################
# Per-file processing
##############################################################################

process_mp3() {
    local song_file="$1"
    local song_base="${song_file%.*}"
    local lrc_file="${song_base}.lrc"
    local txt_file="${song_base}.txt"

    local metadata
    local title
    local artist
    local album
    local duration

    loud
    loud "Examining: ${song_file}"

    # Existing plain lyrics only suppress `.txt` creation work; the track may
    # still need a missing `.lrc` unless both artifacts are already present.
    if [[ -f "${txt_file}" ]]; then
        if (( FORCE == 1 )); then
            loud "Plain-text sidecar already exists, but force is enabled: ${txt_file}"
        else
            loud "Plain-text sidecar already exists: ${txt_file}"
        fi
    fi

    if [[ -f "${lrc_file}" ]] && (( FORCE == 1 )); then
        loud "Synchronized sidecar already exists, but force is enabled: ${lrc_file}"
    fi

    if [[ -f "${lrc_file}" ]]; then
        # Existing synced lyrics suppress LRCLIB and synced-tag extraction, but
        # the file may still need `.txt` generated from the `.lrc`.
        loud "Synchronized sidecar already exists: ${lrc_file}"
    else
        metadata=$(read_metadata "${song_file}") || metadata=""

        if [[ -n "${metadata}" ]]; then
            title=$(jq -r '.title' <<< "${metadata}")
            artist=$(jq -r '.artist' <<< "${metadata}")
            album=$(jq -r '.album' <<< "${metadata}")
            duration=$(jq -r '.duration' <<< "${metadata}")

            loud "Metadata: artist='${artist}' title='${title}' album='${album}' duration=${duration}s"

            # Only query LRCLIB when the metadata is specific enough to be
            # useful and duration is available.
            if [[ -n "${title}" && -n "${artist}" && -n "${album}" &&
                  "${duration}" =~ ^[0-9]+$ && "${duration}" -gt 0 ]]; then
                if query_lrclib \
                    "${title}" "${artist}" "${album}" "${duration}" \
                    "${lrc_file}" "${txt_file}"; then
                    if [[ -f "${lrc_file}" ]]; then
                        loud "Saved synchronized lyrics: ${lrc_file}"
                    elif [[ -f "${txt_file}" ]]; then
                        loud "LRCLIB had only plain lyrics; saved: ${txt_file}"
                    fi
                else
                    loud "No acceptable LRCLIB match."
                fi
            else
                loud "Metadata is incomplete; skipping LRCLIB lookup."
            fi
        else
            loud "Could not read metadata; skipping LRCLIB lookup."
        fi

        if [[ ! -f "${lrc_file}" ]]; then
            # Embedded synced lyrics are the local fallback when LRCLIB did not
            # produce a synchronized result.
            if extract_embedded_synced "${song_file}" "${lrc_file}"; then
                loud "Extracted embedded synchronized lyrics: ${lrc_file}"
            else
                loud "No embedded synchronized lyrics found."
            fi
        fi
    fi

    if [[ -f "${txt_file}" ]] && (( FORCE == 0 )); then
        loud "Plain-text sidecar already exists: ${txt_file}"
    else
        # Prefer a true unsynced embedded lyric payload if one exists.
        if extract_embedded_plain "${song_file}" "${txt_file}"; then
            loud "Extracted embedded unsynchronized lyrics: ${txt_file}"
        elif [[ -f "${lrc_file}" ]]; then
            # If we only have synced lyrics, strip timestamps to produce the
            # missing plain-text sidecar rather than leaving the track partial.
            if convert_lrc_to_plaintext "${lrc_file}" "${txt_file}"; then
                loud "Converted synchronized lyrics to plain text: ${txt_file}"
            else
                loud "Synchronized lyrics exist, but plain-text conversion produced nothing."
            fi
        else
            loud "No embedded unsynchronized lyrics found."
        fi
    fi
}

##############################################################################
# Command-line parsing
##############################################################################

# Keep parsing simple and explicit: mutate globals in place, then let `main`
# consume the finalized runtime configuration.
while (( $# > 0 )); do
    case "$1" in
        -l|--loud|--verbose)
            LOUD=1
            ;;
        -f|--force)
            FORCE=1
            ;;
        -b|--base)
            shift
            (( $# > 0 )) || die "--base requires a directory."
            MPD_MUSIC_BASE="$1"
            ;;
        --delay)
            shift
            (( $# > 0 )) || die "--delay requires a number of seconds."
            REQUEST_DELAY="$1"
            ;;
        -h|--help)
            LOUD=1
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
    shift
done

##############################################################################
# Main
##############################################################################

main() {
    local count=0
    local completed_operations=0
    local song_operations=0
    local song_file=""
    local using_queue=0
    local fallback_live_scan=0
    local queue_total=0
    local queue_remaining=0
    local live_list_file=""
    local live_total=0
    local live_index=0

    require_command exiftool
    require_command curl
    require_command jq
    require_command find
    require_command sed
    require_command grep
    require_command awk

    # Fail early on obviously bad runtime configuration before building queue
    # state or touching the library.
    [[ -d "${MPD_MUSIC_BASE}" ]] ||
        die "MPD music base does not exist: ${MPD_MUSIC_BASE}"

    [[ "${REQUEST_DELAY}" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
        die "--delay must be a non-negative number."

    LYRICTMP=$(mktemp -d) || die "Could not create temporary directory."

    loud "Scanning recursively: ${MPD_MUSIC_BASE}"
    loud "LRCLIB delay: ${REQUEST_DELAY}s"
    loud "Queue file: ${QUEUE_FILE}"
    loud "Force mode: ${FORCE}"

    if (( FORCE == 0 )); then
        # In normal mode, pre-index sidecars first so queue construction can
        # skip already-satisfied tracks with a cheap stem lookup.
        index_existing_sidecars
    else
        loud "Skipping initial sidecar index because force mode is enabled."
    fi

    if [[ -f "${QUEUE_FILE}" ]]; then
        # Existing queue means a prior run left resumable state behind.
        using_queue=1
        loud "Using existing queue file."
    else
        # No queue means either first run or a previously completed run.
        build_queue_file
        using_queue=1
    fi

    if (( using_queue == 1 )); then
        queue_total=$(count_operations_in_list "${QUEUE_FILE}")
        loud "Queue contains ${queue_total} lyric operation(s) needing work."

        while [[ -f "${QUEUE_FILE}" ]]; do
            # Read the current head before mutating the queue so interrupts leave
            # the active file in place for the next invocation.
            song_file=$(head -n 1 "${QUEUE_FILE}")
            [[ -n "${song_file}" ]] || break
            queue_remaining=$(count_operations_in_list "${QUEUE_FILE}")
            song_operations=$(count_pending_operations "${song_file}")
            loud "Progress [queue]: ${completed_operations}/${queue_total} complete; current file has ${song_operations} operation(s); ${queue_remaining} remaining including current"

            process_mp3 "${song_file}"
            # Only drop a queue item after its processing path returned.
            remove_first_queue_entry "${QUEUE_FILE}" "${song_file}"
            ((completed_operations += song_operations))
            ((count++))
        done

        if [[ ! -f "${QUEUE_FILE}" ]]; then
            # Deleting the queue during runtime is treated as an operator choice
            # to abandon persisted state and continue against a fresh live view.
            loud "Queue file was deleted; falling back to live scan."
            fallback_live_scan=1
        elif [[ ! -s "${QUEUE_FILE}" ]]; then
            # Empty queue is the normal completed state, so remove it.
            rm -f -- "${QUEUE_FILE}"
            loud "Queue file exhausted and removed."
        fi
    fi

    if (( fallback_live_scan == 1 )); then
        live_list_file="${LYRICTMP}/live-scan.queue"
        # This fallback list is ephemeral on purpose; only the main queue is
        # durable across runs.
        build_work_list "${live_list_file}"
        live_total=$(count_operations_in_list "${live_list_file}")

        while IFS= read -r song_file; do
            [[ -n "${song_file}" ]] || continue
            song_operations=$(count_pending_operations "${song_file}")
            loud "Progress [live scan]: ${completed_operations}/${live_total} complete; current file has ${song_operations} operation(s)"
            process_mp3 "${song_file}"
            ((completed_operations += song_operations))
            ((count++))
        done < "${live_list_file}"
    fi

    loud
    loud "Finished. Examined ${count} MP3 file(s) across ${completed_operations} lyric operation(s)."
}

main
