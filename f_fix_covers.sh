#!/bin/bash


##############################################################################
#
#  f'in fix the covers
#  Using YAD and other things to finally frakking get cover art
#  properly sorted.
#
#  FIXES APPLIED:
#  - Improved embedded cover detection (more comprehensive pattern matching)
#  - Added ffmpeg fallback extraction when eyeD3 fails
#  - Added proper error checking and return codes to extract_cover()
#  - Added verification that extraction actually succeeded before counting covers
#  - Consistent use of improved detection pattern in both places
#
#  (c) Steven Saus 2023
#  Licensed under the MIT license
#
##############################################################################
# Ping sound from
# https://freesound.org/people/MATRIXXX_/sounds/444918/

# touch to restore original file dates when writing to MP3


TMPDIR=$(mktemp -d)
dirlist=$(mktemp)
songlist=$(mktemp)
testlist=$(mktemp)
MusicDir=""
# This is a dirty global variable hack.
SHOW_SONGSTRING=""

SAFETY=0    # output actions would have taken
AUTOEMBED=0 # embed images in mp3
REMOVE=0    # Remove images
LOUD=0      # verbose
ALERT=0     # play audible ping when user input needed
CHECKALL=0  # even if they all match, search & check anyway.
SONGDIR=""

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

function display_help {
    echo "f_fix_covers.sh [Music Directory]"
    echo " "
    echo "-h|--help         : This."
    echo "-a|--autoembed    : Embed found, selected covers into MP3s."
    echo "-p|--ping         : Play audible tone when user input needed."
    echo "-r|--remove       : Remove existing embedded images in MP3s when cover found."
    echo "-c|--checkall     : Manually verify all album covers, even if only one."
    echo "-e|--everything   : Check online for covers for every album."
    echo "-s|--safe         : Just say what it would do, do not actually do operations."
    echo "-l|--loud         : Verbose output."
    echo "-d|--dir [DIR]    : Specify the music directory to scan."
}

function cleanup {
    find "$TMPDIR/" -iname "OTHER*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "*FRONT_COVER*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "cover*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "ICON*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "ILLUSTRATION*"  -exec rm -f {} \;
    #find "$TMPDIR/" -iname "*FOUND_COVER*"  -exec rm -f {} \;
    rm "${TMPDIR}/out_montage.jpg" 2>/dev/null 1>/dev/null
}


function cleanup_end {
    rm -rf "${TMPDIR}"
    if [ -f "${dirlist}" ];then rm "${dirlist}"; fi
    if [ -f "${songlist}" ];then rm "${songlist}"; fi
    if [ -f "${testlist}" ];then rm "${testlist}"; fi
}

#https://www.reddit.com/r/bash/comments/8nau9m/remove_leading_and_trailing_spaces_from_a_variable/
trim() {
    local s=$1 LC_CTYPE=C
    s=${s#"${s%%[![:space:]]*}"}
    s=${s%"${s##*[![:space:]]}"}
    printf '%s' "$s"
}


function extract_cover () {


    SONGFILE="${1}"
    SONGDIR="${2}"
    cleanup
    loud "Extracting cover from ${SONGFILE}"

    # Try eyeD3 extraction first with error checking
    if ! eyeD3 --quiet --write-images="${TMPDIR}" "$SONGFILE" 2>/dev/null; then
        loud "eyeD3 extraction failed, trying ffmpeg fallback for ${SONGFILE}"
        # Fallback to ffmpeg extraction
        ffmpeg -i "$SONGFILE" -an -vcodec copy "${TMPDIR}/FRONT_COVER_ffmpeg.jpg" 2>/dev/null
        if [ -f "${TMPDIR}/FRONT_COVER_ffmpeg.jpg" ]; then
            mv "${TMPDIR}/FRONT_COVER_ffmpeg.jpg" "${TMPDIR}/FRONT_COVER.jpeg"
        fi
    fi
    if [ -f "$TMPDIR/FRONT_COVER.png" ]; then
        loud "### Converting PNG into JPG"
        convert "$TMPDIR/FRONT_COVER.png" "$TMPDIR/FRONT_COVER.jpeg"
        rm "$TMPDIR/FRONT_COVER.png" 1>/dev/null 2>/dev/null
    fi
    # Catching when it's sometimes stored as "Other" tag instead of FRONT_COVER
    # but only when FRONT_COVER doesn't exist.
    if [ ! -f "$TMPDIR/FRONT_COVER.jpeg" ]; then
        if [ -f "$TMPDIR/OTHER.png" ]; then
            loud "### Converting PNG into JPG"
            convert "$TMPDIR/OTHER.png" "$TMPDIR/OTHER.jpeg"
        fi
        if [ -f "$TMPDIR/OTHER.jpg" ]; then
            cp "$TMPDIR/OTHER.jpg" "$TMPDIR/OTHER.jpeg"
        fi
        if [ -f "$TMPDIR/OTHER.jpeg" ]; then
            cp "$TMPDIR/OTHER.jpeg" "$TMPDIR/FRONT_COVER.jpeg"
            rm "$TMPDIR/OTHER.jpeg"
        fi
        if [ -f "$TMPDIR/FRONT_COVER.jpg" ]; then
            cp "$TMPDIR/FRONT_COVER.jpg" "$TMPDIR/FRONT_COVER.jpeg"
            rm "$TMPDIR/FRONT_COVER.jpg"
        fi
    fi
    if [ -f "$TMPDIR/FRONT_COVER.jpeg" ]; then
        loud "### Cover art retrieved from MP3 ID3 tags!"
        return 0
    else
        loud "### Warning: Cover detected but extraction failed for ${SONGFILE}"
        return 1
    fi
}


function search_for_cover () {


    rm -rf "${TMPDIR}/*FOUND_COVER.jpeg"
    FOUND_COVERS=0
    searchsonglist=$(mktemp)
    ARTIST=""
    ALBUM=""

    # put it all into another list to manage
    if [ -d "${1}" ];then
        find "${1}" -name '*.mp3' -printf '%p\n' > "${searchsonglist}"
        while read -r line; do
            tempstring=$(basename ${line})
        done < "${searchsonglist}"
    else
        echo "${1}" > "${searchsonglist}"
    fi

    while read -r line; do
        SONGFILE="${line}"
        if [ -s "${SONGFILE}" ];then
            songdata=$(ffprobe "$SONGFILE" 2>&1)
            # big long grep string to avoid all the possible frakups I found, lol
            tARTIST=$(echo "$songdata" | grep "album_artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
            if [ "$ARTIST" == "" ];then
                ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
            fi
            tALBUM=$(echo "$songdata" | grep "album" | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}' | tr '\n' ' ')

            if [[ "${tALBUM}" != "${ALBUM}" ]] || [[ "${tARTIST}" != "${ARTIST}" ]];then
                # there were unequal values found, re-attempt search.
                ALBUM="${tALBUM}"
                ARTIST="${tARTIST}"

                ##########################################################################
                # Attempt to get coverart from CoverArt Archive
                ##########################################################################
                MBID=""
                IMG_URL=""
                API_URL=""

                # MusicBrainz ID
                MBID=$(echo "$songdata" | grep "MusicBrainz Album Id:" | awk -F ': ' '{print $2}')
                if [ "$MBID" != '' ] && [ "$MBID" != 'null' ];then
                    API_URL="https://coverartarchive.org/release/$MBID/front"
                    IMG_URL=$(curl "$API_URL" | awk -F ': ' '{print $2}')
                    wget_bin=$(which wget)
                    if [ -f "${timeout_bin}" ];then
                        wget_bin=$(echo "${timeout_bin} 15 --kill-after=30 ${wget_bin}")
                    fi
                    if [ $LOUD -eq 1 ];then

                        "${wget_bin}" --timeout=15 --quiet "${IMG_URL}" -O "$TMPDIR/MusicBrains_DL.jpg"
                    else
                        "${wget_bin}" --timeout=15 --quiet "${IMG_URL}" -O "$TMPDIR/MusicBrains_DL.jpg" 2>/dev/null 1>/dev/null
                    fi

                    if [ ! -s "$TMPDIR/MusicBrains_DL.jpg" ];then
                        rm "$TMPDIR/MusicBrains_DL.jpg"
                    else
                        FOUND_COVERS=$((FOUND_COVERS+1))
                        mv "$TMPDIR/MusicBrains_DL.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
                    fi
                fi


                ##########################################################################
                # Attempt to find cover art via glyrc if it's in $PATH
                # Escaping album names here suuuuucks
                ##########################################################################
                glyrc_bin=$(which glyrc)
                if [ -f "${glyrc_bin}" ];then
                    if [ $LOUD -eq 1 ];then
                        glyrc cover --timeout 15 --artist "${ARTIST}" --album "${ALBUM}" --write "${TMPDIR}/cover.tmp" --from "discogs;rhapsody;lastfm"
                    else
                        glyrc cover --timeout 15 --artist "${ARTIST}" --album "${ALBUM}" --write "${TMPDIR}/cover.tmp" --from "discogs;rhapsody;lastfm" 2>/dev/null 1>/dev/null
                    fi

                    if [ -f "$TMPDIR/cover.tmp" ];then
                        FOUND_COVERS=$((FOUND_COVERS+1))
                        convert "$TMPDIR/cover.tmp" "$TMPDIR/Glyrc_DL.jpg"
                        mv "$TMPDIR/Glyrc_DL.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
                        rm "$TMPDIR/cover.tmp" 2>/dev/null 1>/dev/null
                    fi
                fi
                ##########################################################################
                # Attempt to find cover art via sacad if it's in $PATH
                ##########################################################################
                rm "$TMPDIR/FRONT_COVER.jpeg" 2>/dev/null 1>/dev/null
                sacad_bin=$(which sacad)
                if [ -f "${sacad_bin}" ];then
                    timeout_bin=$(which timeout)  # sacad doesn't have a timeout...
                    if [ -f "${timeout_bin}" ];then
                        sacad_bin=$(echo "${timeout_bin} 15 ${sacad_bin}")
                    fi
                    exec_string=$(printf "%s \"%s\" \"%s\" 512 %s/FRONT_COVER.jpeg" "${sacad_bin}" "${ARTIST}" "${ALBUM}" "${TMPDIR}")
                    if [ $LOUD -eq 1 ];then
                        eval "$exec_string"
                    else
                        eval "$exec_string" 2>/dev/null 1>/dev/null
                    fi
                    if [ -f "$TMPDIR/FRONT_COVER.jpeg" ];then
                        FOUND_COVERS=$((FOUND_COVERS+1))
                        convert "$TMPDIR/FRONT_COVER.jpeg" "$TMPDIR/Sacad_DL.jpg"
                        mv "$TMPDIR/Sacad_DL.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
                        rm "$TMPDIR/FRONT_COVER.jpeg" 2>/dev/null 1>/dev/null
                    fi
                fi
            fi
        fi
    done < "${searchsonglist}"

    #Dirty horrible global variable hack
    SHOW_SONGSTRING=$(echo "${ALBUM} -- ${ARTIST}")

    if [ $AUTOEMBED -eq 1 ] && [ $FOUND_COVERS -eq 1 ];then
        #there's only one....
        canon_cover=$(find "${TMPDIR}" -name '*FOUND_COVER.jpeg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')
    else
        if [ $FOUND_COVERS -gt 0 ];then
            canon_cover=$(show_compare_images "$(find ${TMPDIR} -name '*FOUND_COVER.jpeg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')")
        else
            canon_cover=""
        fi
    fi
    echo "${canon_cover}"
}

function show_compare_images () {
    # The images are ALREADY compared and unequal; we are just comparing them!
    # returns the chosen image filename
    # do make sure to quote variables coming into this!


    # user input is needed; alert them if asked for.
    if [ $ALERT -eq 1 ];then

        if [ ! -f "${SCRIPT_DIR}/444918__matrixxx__ping.mp3" ];then
            # if the ping soundfile doesn't exist, skip further checks.
            ALERT=0
        else
            if [ -f $(which mpg123) ];then
                mpg123 -q "${SCRIPT_DIR}/444918__matrixxx__ping.mp3" 2>/dev/null 1>/dev/null &
            else
                if [ -f $(which mplayer) ];then
                    mplayer "${SCRIPT_DIR}/444918__matrixxx__ping.mp3" 2>/dev/null 1>/dev/null &
                else
                    if [ -f $(which mpv) ];then
                        mpv "${SCRIPT_DIR}/444918__matrixxx__ping.mp3" 2>/dev/null 1>/dev/null &
                    fi
                fi
                # None of the players are found, no sense going through all this again.
                ALERT=0
            fi
        fi
    fi

    show_list=$(mktemp)
    test_list=$(mktemp)
    echo "${@}" > "${show_list}"
    # Note -- this was set at the beginning of the script. Leaving this here
    # as a warning to myself if I try to pull this out and forget. :)

    # set up layout?
    feh --preload --fullindex --thumb-width 200 --thumb-height 200 --stretch --draw-filename --filelist "${show_list}" --output-only "${TMPDIR}/out_montage.jpg"

    #Which of the images should be canonical?

    buttonstring=""
    i=1
    while read -r line; do
        tempstring=$(basename ${line})
        buttonstring=$(echo ${buttonstring} --button="${tempstring}:${i}")
        echo "${line}ϑ${i}" >> "${test_list}"
        i=$((i+1))
    done < "${show_list}"
    evalstring=$(printf "yad --window-icon=musique --always-print-result --on-top --skip-taskbar --image-on-top --borders=5 --title \"Choose for %s\" --text-align=center --image \"%s\" --button=\"None:99\" %s" "${SHOW_SONGSTRING}" "${TMPDIR}/out_montage.jpg" "${buttonstring}")

    eval ${evalstring}
    result="$?"
    if [ ${result} -eq 99 ];then
        echo ""
    else
        result=$(echo "ϑ${result}")
        grep -e "${result}" "${test_list}" | awk -F 'ϑ' '{print $1}'
        # return the filename of the chosen cover.
        canon_cover=$(realpath $(grep -e "${result}" "${test_list}" | awk -F 'ϑ' '{print $1}'))
        echo "${canon_cover}"
    fi
    #clean up after ourselves, don't delete the found ones yet tho.
    rm "${show_list}"
    rm "${test_list}"

}


function directory_check () {
    find "${MusicDir}" -name '*.mp3' -printf '"%h"\n' | sort -u | xargs -I {} realpath {} > "${dirlist}"
    CURRENTENTRY="0"
    ENTRIES=$(cat "${dirlist}" | wc -l)
    while read -r line; do
        cleanup
        SONGFILE=""
        SONGDIR=""
        SONGDIR=$(realpath "${line}")
        CURRENTENTRY=$((CURRENTENTRY+1))
        loud "$CURRENTENTRY of $ENTRIES ${SONGDIR}"
        CA_Embedded=""
        canon_cover=""
        ####################################################################
        # Do cover files exist? If so, make sure both cover and folder exist.
        ####################################################################
        # get all embedded album art, compare to each other.
        echo "" > "${songlist}"
        find "${SONGDIR}" -name '*.mp3' -printf '%p\n' > "${songlist}"
        #find "${SONGDIR}" -name '*.mp3' -printf '"%p"\n' | xargs -I {} realpath {} >> "${songlist}"
        cleanup
        # Get all embedded front covers
        #rm -rf "${TMPDIR}/*.jpeg" 2>/dev/null 1>/dev/null
        rm -rf "${TMPDIR}/*.jpg" 2>/dev/null 1>/dev/null
        FOUND_COVERS=0
        EmbeddedChecksums=""
        while read -r line; do
            loud "Examining ${line}"

            SONGFILE="${line}"
            songdata=$(ffprobe "$SONGFILE" 2>&1)
            ARTIST=$(echo "$songdata" | grep "album_artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
            if [ "$ARTIST" == "" ];then
                ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
            fi
            ALBUM=$(echo "$songdata" | grep "album" | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}' | tr '\n' ' ')
            ARTIST=$(trim "$ARTIST")
            ALBUM=$(trim "$ALBUM")
            # big long grep string to avoid all the possible frakups I found, lol
            # Improved detection to catch more cover types
            CA_Embedded=$(echo "$songdata" | grep -i "attached.*pic\|cover\|artwork\|front_cover\|album.*art" | wc -l)
            if [ "${CA_Embedded}" -gt 0 ];then
                # Extract cover and verify success
                if extract_cover "${SONGFILE}" "${SONGDIR}"; then
                    if [ -f "${TMPDIR}/FRONT_COVER.jpeg" ];then
                        tmpchecksum=$(shasum "${TMPDIR}/FRONT_COVER.jpeg" | awk '{print $1}')
                        if [[ ${EmbeddedChecksums} == *${tmpchecksum}* ]]; then
                            loud "Duplicate cover found."
                        else
                            EmbeddedChecksums=$(echo "${EmbeddedChecksums}${tmpchecksum}")
                            FOUND_COVERS=$((FOUND_COVERS + 1))
                            loud "Found ${FOUND_COVERS} covers so far!"
                            mv "${TMPDIR}/FRONT_COVER.jpeg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
                        fi
                    else
                        loud "### Warning: Extraction reported success but no file found for ${SONGFILE}"
                    fi
                else
                    loud "### Warning: Failed to extract embedded cover from ${SONGFILE}"
                fi
            fi
        done < "${songlist}"
        if [ -f "${SONGDIR}/cover.jpg" ]; then
            FOUND_COVERS=$((FOUND_COVERS + 1))
            cp "${SONGDIR}/cover.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
        fi
        if [ -f "${SONGDIR}/cover (1).jpg" ]; then
            FOUND_COVERS=$((FOUND_COVERS + 1))
            cp "${SONGDIR}/cover (1).jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
        fi
        if [ -f "${SONGDIR}/folder.jpg" ]; then
            FOUND_COVERS=$((FOUND_COVERS + 1))
            cp "${SONGDIR}/folder.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
        fi
        #Dirty horrible global variable hack
        SHOW_SONGSTRING=$(echo "${ALBUM} -- ${ARTIST}")
        canon_cover=""

        if [ $FOUND_COVERS -eq 1 ];then
            if [ $CHECKALL -eq 0 ];then
                if [ $AUTOEMBED -eq 1 ];then
                    canon_cover="${TMPDIR}/1FOUND_COVER.jpeg"
                else
                    canon_cover=$(show_compare_images "${TMPDIR}/1FOUND_COVER.jpeg")
                    canon_cover=$(echo "${canon_cover}" | head -n 1)
                fi
                if [ ! -f "${canon_cover}" ]; then
                    canon_cover=$(search_for_cover "${SONGDIR}")
                    canon_cover=$(echo "${canon_cover}" | head -n 1)
                fi
            else
                # so that the comparing dialogue is kicked in
                FOUND_COVERS=$((FOUND_COVERS+1))
                canon_cover=""
            fi
        fi

        if [[ $FOUND_COVERS -eq 0 ]] || [[ $EVERYTHING -eq 1 ]];then
            loud "${SONGDIR}"
            online_cover=$(search_for_cover "${SONGDIR}")
            online_cover=$(echo "${online_cover}" | head -n 1)
            # Only use online cover if we don't have embedded covers or if online search succeeded
            if [[ $FOUND_COVERS -eq 0 ]] || [[ -s "$online_cover" ]];then
                canon_cover="$online_cover"
                if [[ $FOUND_COVERS -eq 0 ]];then
                    FOUND_COVERS=0
                fi
            fi
        fi

        # comparing the hash of found covers; if all are equal, then...
        if [ $FOUND_COVERS -gt 1 ] && [ ! -s "${canon_cover}" ];then
            find "${TMPDIR}" -name '*FOUND_COVER.jpeg' -printf '%p\n' | xargs -I {} realpath {} > "${testlist}"
            testsha=$(shasum $(cat ${testlist}|shuf) | awk '{print $1}')
            testsha=$(echo "${testsha}" | head -n 1 )

            # If compareall is on, it will automatically kick in the comparison
            COMPAREFAIL=$CHECKALL
            while read -r line; do
                testingsha=$(shasum ${line} | awk '{print $1}')
                testingsha=$(echo "${testingsha}" | head -n 1)
                if [[ "${testingsha}" != "${testsha}" ]];then
                    COMPAREFAIL=$((COMPAREFAIL+1))
                fi
            done < "${testlist}"
            if [ $COMPAREFAIL -gt 0 ];then
                canon_cover=$(show_compare_images "$(find ${TMPDIR} -name '*FOUND_COVER.jpeg'| xargs -I {} echo {} | sed 's@\ @\\ @g')")
                # failing to recognize the file here.  Not sure why.
                # it's returning two lines. WHY???
                # the head line below fixes it, anyway...
                canon_cover=$(echo "${canon_cover}" | head -n 1)
                if [ ! -s "${canon_cover}" ]; then
                    canon_cover=$(search_for_cover "${SONGDIR}")
                    canon_cover=$(echo "${canon_cover}" | head -n 1)
                fi
            else
                # all of the covers there are equal
                canon_cover=$(find "${TMPDIR}" -name '*FOUND_COVER.jpeg' -printf '%p\n' | head -n 1)
            fi
        fi
        if [ -s "${canon_cover}" ]; then # this will need to be specified when also testing for what was embedded cover
            # synchronizing files
            if [ "${canon_cover}" != "${SONGDIR}/cover.jpg" ];then
                if [ $SAFETY -eq 0 ];then
                    cp -f "${canon_cover}" "${SONGDIR}/cover.jpg"
                else
                    echo "### SAFETY: cp -f ${canon_cover} ${SONGDIR}/cover.jpg"
                fi
            fi
            if [ "${canon_cover}" != "${SONGDIR}/folder.jpg" ];then
                if [ $SAFETY -eq 0 ];then
                    cp -f "${canon_cover}" "${SONGDIR}/folder.jpg"
                else
                    echo "### SAFETY: cp -f ${canon_cover} ${SONGDIR}/folder.jpg"
                fi
            fi
            COMPAREFAIL=0

            if [ $AUTOEMBED -eq 1 ];then
                find "${SONGDIR}" -name '*.mp3' -printf '"%p"\n' | xargs -I {} realpath {} > "${songlist}"
                while read -r line; do
                    # if comparefail was not tripped, the only possible way the cover is
                    # different is if it's missing, to avoid extra writes.
                    if [ $COMPAREFAIL -eq 0 ];then
                        songdata=$(ffprobe "${line}" 2>&1)
                        CA_Embedded=$(echo "$songdata" | grep -i "attached.*pic\|cover\|artwork\|front_cover\|album.*art" | wc -l)
                    else
                        CA_Embedded=0
                    fi

                    if [ $REMOVE -eq 1 ]; then
                        if [ $SAFETY -eq 1 ];then
                            echo "### SAFETY: eyeD3 --quiet --remove-all-images ${line}"
                        else
                            if [ $LOUD -eq 1 ];then
                                eyeD3 --quiet --remove-all-images "${line}"
                            else
                                eyeD3 --quiet --remove-all-images "${line}" 2>/dev/null 1>/dev/null
                            fi
                        fi
                        CA_Embedded=0
                    fi

                    if [ $CA_Embedded -eq 0 ];then
                        # either comparefail failed or there is no embedded cover.
                        if [ $SAFETY -eq 0 ];then
                            filetime=$(stat -c '%y' "${line}")
                            if [ $LOUD -eq 1 ];then
                                eyeD3 --to-v2.3 --quiet --add-image="${canon_cover}":FRONT_COVER:Cover "${line}"
                            else
                                if [ $REMOVE -eq 1 ];then eyeD3 --quiet --remove-all-images "${line}" 2>/dev/null 1>/dev/null ; fi
                                eyeD3 --to-v2.3 --quiet --add-image="${canon_cover}":FRONT_COVER:Cover "${line}"
                            fi
                            touch -d "${filetime}" "${line}"
                        else
                            if [ $REMOVE -eq 1 ];then echo "### SAFETY: eyeD3 --quiet --remove-all-images ${line}";fi
                            echo "### SAFETY: eyeD3 --quiet --add-image=${canon_cover}:FRONT_COVER ${line}"
                        fi
                    fi
                    if [ -f "${SONGDIR}/cover (1).jpg" ]; then
                        rm "${SONGDIR}/cover (1).jpg"
                    fi
                done < "${songlist}"
                rm "${songlist}" 2>/dev/null 1>/dev/null
                rm -rf "${TMPDIR}/*.jpeg" 2>/dev/null 1>/dev/null
                rm -rf "${TMPDIR}/*.jpg" 2>/dev/null 1>/dev/null
            fi
            rm "${songlist}" 2>/dev/null 1>/dev/null
            rm -rf "${TMPDIR}/*.jpeg" 2>/dev/null 1>/dev/null
            rm -rf "${TMPDIR}/*.jpg" 2>/dev/null 1>/dev/null
        fi
        rm -rf "${TMPDIR}/*.jpeg" 2>/dev/null 1>/dev/null
        rm -rf "${TMPDIR}/*.jpg" 2>/dev/null 1>/dev/null
        find "$TMPDIR/" -iname "*FOUND_COVER*"  -exec rm -f {} \;

    done < "${dirlist}"
    rm "${dirlist}"
}

    while [ $# -gt 0 ]; do
    option="$1"
        case $option in
        -h|--help) display_help
            exit
            shift ;;
        -a|--autoembed) AUTOEMBED=1
            shift ;;
        -p|--ping) ALERT=1
            shift ;;
        -s|--safe) SAFETY=1
            shift ;;
        -e|--everything) EVERYTHING=1
            shift ;;
        -l|--loud) LOUD=1
            shift ;;
        -r|--remove) REMOVE=1
            shift ;;
        -c|--checkall) CHECKALL=1
            shift ;;
        -d|--dir)
            shift
            if [ -d "${1}" ];then
                MusicDir="${1}"
            fi
            shift;;
        *)  if [ -d "${1}" ];then
                MusicDir="${1}"
            fi
            shift;;
        esac
    done

if [ ! -d "$MusicDir" ]; then
    echo "No music directory specified."
    exit 99
    #MusicDir="$HOME/music";
fi

loud "Using ${MusicDir}"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

loud "Checking files in directory."
directory_check "${MusicDir}"

IFS=$SAVEIFS

cleanup_end
