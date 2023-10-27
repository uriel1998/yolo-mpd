#!/bin/bash


##############################################################################
#
#  f'in fix the covers
#  Using YAD and other things to finally frakking get cover art 
#  properly sorted. 
#  YAD = https://sourceforge.net/projects/yad-dialog/
#  (c) Steven Saus 2023
#  Licensed under the MIT license
#
##############################################################################

# You will always need MP3 mode for those times where a cover doesn't match...
# hm - maybe call mp3 mode for the files IN dir mode?
# safety mode (report changes, do not do them.)


AUTOEMBED=0
TMPDIR=$(mktemp -d)
startdir="$PWD"
dirlist=$(mktemp)
songlist=$(mktemp)
testlist=$(mktemp)
MusicDir=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# Change back after testing.
#SAFETY=""
SAFETY="True"
MODE="DIR"
LOUD=1

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

function display_help {
    echo "f_fix_covers.sh [Music Directory]"
    echo " "
    echo "-h|--help         : This."
    echo "-a|--autoembed    : Do operations without asking user. Don't use this."
    echo "-s|--safe         : Just say what it would do, do not actually do operations."
    echo "-q|--quiet        : Minimal output."    
    echo "-f|--file         : Examine *every* MP3 individually instead of images in the file folder."
    echo "-d|--dir [DIR]    : Specify the music directory to scan."
}

function cleanup {
    find "$TMPDIR/" -iname "OTHER*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "FRONT_COVER*"  -exec rm -f {} \;
    find "$TMPDIR/" -iname "cover*"  -exec rm -f {} \;    
    find "$TMPDIR/" -iname "ICON*"  -exec rm -f {} \;  
    find "$TMPDIR/" -iname "ILLUSTRATION*"  -exec rm -f {} \;  
}


function cleanup_end {
    rm -rf ${TMPDIR}
    rm ${dirlist}
    rm ${songlist}
    rm ${testlist}    
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
    
    eyeD3 --write-images="$TMPDIR" "$SONGFILE" 1> /dev/null
    if [ -f "$TMPDIR/FRONT_COVER.png" ]; then
        loud "### Converting PNG into JPG"
        convert "$TMPDIR/FRONT_COVER.png" "$TMPDIR/FRONT_COVER.jpeg"
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
        fi
        if [ -f "$TMPDIR/FRONT_COVER.jpg" ]; then
            cp "$TMPDIR/FRONT_COVER.jpg" "$TMPDIR/FRONT_COVER.jpeg"
        fi            
    fi  
    if [ -f "$TMPDIR/FRONT_COVER.jpeg" ]; then
        loud "### Cover art retrieved from MP3 ID3 tags!"
        loud "### Cover art being copied to music directory!"
        echo "${SONGDIR}/cover.jpg"
        #cp "$TMPDIR/FRONT_COVER.jpeg" "${SONGDIR}/cover.jpg"
        #cp "$TMPDIR/FRONT_COVER.jpeg" "${SONGDIR}/folder.jpg"
    fi
}


function search_for_cover (){
    
    rm -rf "${TMPDIR}/*DL.jpg"  
    FOUND_COVERS=0
    # currently just going to pick one in the directory, as even if the *covers* 
    # are different, the *album* and *artist* (or album artist) should be the same.
    if [ -d "${1}" ];then
        SONGFILE=$(find "${SONGDIR}" -name '*.mp3' -printf '%p\n' | sort -u | xargs -I {} realpath {} )
    else
        SONGFILE="${1}"
    fi

    if [ -s "${SONGFILE}" ];then 
        songdata=$(ffprobe "$SONGFILE" 2>&1)
        # big long grep string to avoid all the possible frakups I found, lol
        ARTIST=$(echo "$songdata" | grep "album_artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
        if [ "$ARTIST" == "" ];then
            ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
        fi
        ALBUM=$(echo "$songdata" | grep "album" | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}' | tr '\n' ' ')
        ARTIST=$(trim "$ARTIST")
        ALBUM=$(trim "$ALBUM")

        ##########################################################################
        # Attempt to get coverart from CoverArt Archive
        ##########################################################################
        MBID=""
        IMG_URL=""
        API_URL=""   
        
        # MusicBrainz ID
        MBID=$(echo "$songdata" | grep "MusicBrainz Album Id:" | awk -F ': ' '{print $2}')
        if [ "$MBID" != '' ] || [ "$MBID" != 'null' ];then
            API_URL="https://coverartarchive.org/release/$MBID/front"
            IMG_URL=$(curl "$API_URL" | awk -F ': ' '{print $2}')
            wget --quiet "${IMG_URL}" -O "$TMPDIR/MusicBrains_DL.jpg" 2>&1
            if [ ! -s "$TMPDIR/MusicBrains_DL.jpg" ];then
                rm "$TMPDIR/MusicBrains_DL.jpg"
            else
                FOUND_COVERS=$((FOUND_COVERS+1))
            fi
        fi


        ##########################################################################
        # Attempt to find cover art via glyrc if it's in $PATH
        # Escaping album names here suuuuucks
        ##########################################################################
        glyrc_bin=$(which glyrc)
        if [ -f $glyrc_bin ];then
            glyrc cover --timeout 15 --artist "${ARTIST}" --album "${ALBUM}" --write "${TMPDIR}/cover.tmp" --from "discogs;rhapsody;lastfm"
            if [ -f "$TMPDIR/cover.tmp" ];then
                FOUND_COVERS=$((FOUND_COVERS+1))
                convert "$TMPDIR/cover.tmp" "$TMPDIR/Glyrc_DL.jpg"
                rm "$TMPDIR/cover.tmp"
            fi
        fi
        ##########################################################################
        # Attempt to find cover art via sacad if it's in $PATH
        ##########################################################################
        rm "$TMPDIR/FRONT_COVER.jpeg"
        sacad_bin=$(which sacad)
        if [ -f "${sacad_bin}" ];then 
            exec_string=$(printf "%s \"%s\" \"%s\" 512 %s/FRONT_COVER.jpeg" "${sacad_bin}" "${ARTIST}" "${ALBUM}" "$TMPDIR")
            eval "$exec_string"
            if [ -f "$TMPDIR/FRONT_COVER.jpeg" ];then
                FOUND_COVERS=$((FOUND_COVERS+1))
                convert "$TMPDIR/FRONT_COVER.jpeg" "$TMPDIR/Sacad_DL.jpg"
                rm "$TMPDIR/FRONT_COVER.jpeg"
            fi
        fi
        if [ $AUTOEMBED -eq 1 ] && [ $FOUND_COVERS -eq 1 ];then
            #there's only one....
            canon_cover=$(find ${TMPDIR} -name '*DL.jpg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')
        else
            if [ $FOUND_COVERS -gt 0 ];then
                canon_cover=$(show_compare_images "$(find ${TMPDIR} -name '*DL.jpg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')")
            else
                canon_cover=""
            fi
        fi
        echo "${canon_cover}"
    fi
}

function show_compare_images () {
    # The images are ALREADY compared and unequal; we are just comparing them!
    # returns the chosen image filename
    # do make sure to quote variables coming into this!

    rm -rf "${TMPDIR}/*FOUND.jpeg"    
    show_list=$(mktemp)
    echo "${@}" > "${show_list}"
    # Note -- this was set at the beginning of the script. Leaving this here 
    # as a warning to myself if I try to pull this out and forget. :)
    
    # set up layout? 
    feh --preload --fullindex --thumb-width 200 --thumb-height 200 --stretch --draw-filename --filelist $show_list --output-only "${TMPDIR}/out_montage.jpg"
    
    #Which of the images should be canonical?
    # These filenames should be properly escaped
    
    single_line_list=$(cat $show_list | tr '\n' ' ' )
    
    #IFS=$SAVEIFS
    buttonstring=""
    i=1
    while read line; do
        tempstring=$(basename ${line})
        buttonstring=$(echo ${buttonstring} --button="${tempstring}:${i}")
        i=$((i+1))
    done < "${show_list}"
    evalstring=$(printf "yad --window-icon=musique --always-print-result --on-top --skip-taskbar --image-on-top --borders=5 --title \"Choose the appropriate image\" --text-align=center --image \"%s\" --button=\"None:99\" %s" "${TMPDIR}/out_montage.jpg" "${buttonstring}")
    
    eval ${evalstring}
    result=$(echo "$?")
    if [ $result -eq 99 ];then
        echo ""
    else
        # return the filename of the chosen cover.
        outstring=$(realpath $(sed "${result}!d" ${show_list}))
        echo "${outstring}"
    fi
    #IFS=$(echo -en "\n\b")
    #clean up after ourselves, don't delete the found ones yet tho.
    rm "${show_list}"    
    
}
    

function directory_check () {

    find "${MusicDir}" -name '*.mp3' -printf '%h\n' | sort -u | xargs -I {} realpath {} > "${dirlist}"
    CURRENTENTRY="0"
    ENTRIES=$(cat ${dirlist} | wc -l)
    while read line
    do
        cleanup
        TITLE=""
        ALBUMARTIST=""
        SONGFILE=""
        SONGDIR=""
        SONGDIR=$(realpath ${line})
        CURRENTENTRY=$(($CURRENTENTRY+1))
        echo "$CURRENTENTRY of $ENTRIES ${SONGDIR}"
        CA_File_Cover=""
        CA_File_Folder=""
        CA_File_Embedded=""
        canon_cover=""
        ####################################################################
        # Do cover files exist? If so, make sure both cover and folder exist.
        ####################################################################        
        # get all embedded album art, compare to each other.
        find "${SONGDIR}" -name '*.mp3' -printf '%p\n' | xargs -I {} realpath {} > "${songlist}"
        cleanup
        # Get all embedded front covers
        FOUND_COVERS=0
        EmbeddedChecksums=""
        while read line; do
            SONGFILE="${line}"
            songdata=$(ffprobe "$SONGFILE" 2>&1)
            # big long grep string to avoid all the possible frakups I found, lol
            CA_Embedded=$(echo "$songdata" | grep Cover | grep -c "front")
            if [ $CA_Embedded -gt 0 ];then
                extract_cover "${SONGFILE}" "${SONGDIR}"
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
                fi
            fi
        done < "${songlist}"
        if [ -f "${SONGDIR}/cover.jpg" ]; then
            CA_File_Cover=$(shasum "${SONGDIR}/cover.jpg" | awk '{print $1}')
            FOUND_COVERS=$((FOUND_COVERS + 1))
            cp "${SONGDIR}/cover.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
        fi
        if [ -f "${SONGDIR}/folder.jpg" ]; then
            CA_File_Folder=$(shasum "${SONGDIR}/folder.jpg" | awk '{print $1}')
            FOUND_COVERS=$((FOUND_COVERS + 1))
            cp "${SONGDIR}/folder.jpg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"
        fi
        if [ $FOUND_COVERS -gt 1 ];then        
            find "${TMPDIR}" -name '*FOUND_COVER.jpeg' -printf '%p\n' | xargs -I {} realpath {} > "${testlist}"
            testsha=$(shasum $(cat ${testlist}|shuf) | awk '{print $1}')
            COMPAREFAIL=0
            while read line do
                testingsha=$(shashum ${line} | awk '{print $1}')
                if [ "$testingsha" != "$testsha" ];then
                    COMPAREFAIL=$((COMPAREFAIL+1))
                fi
            done < "${testlist}"
            if [ $COMPAREFAIL -gt 0 ];then
                canon_cover=$(show_compare_images "$(find ${TMPDIR} -name '*FOUND_COVER.jpeg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')")
                if [ ! -f "${canon_cover}" ]; then
                    canon_cover=$(search_for_cover "${SONGDIR}")
                fi
            fi
        else
            if [ $FOUND_COVERS -eq 1 ];then
                if [ $AUTOEMBED -eq 1 ];then
                    canon_cover="${TMPDIR}/1FOUND_COVER.jpeg"
                else
                    canon_cover=$(show_compare_images "${TMPDIR}/1FOUND_COVER.jpeg")
                fi
                if [ ! -f "${canon_cover}" ]; then
                    canon_cover=$(search_for_cover "${SONGDIR}")
                fi
            else
                # no cover found
                canon_cover=$(search_for_cover "${SONGDIR}")
            fi
        fi


        if [ -s "${canon_cover}" ]; then # this will need to be specified when also testing for what was embedded cover
                # synchronizing files
            if [ "${canon_cover}" != "${SONGDIR}/cover.jpg" ];then
                cp -f "${canon_cover}" "${SONGDIR}/cover.jpg"
            fi
            if [ "${canon_cover}" != "${SONGDIR}/folder.jpg" ];then
                cp -f "${canon_cover}" "${SONGDIR}/folder.jpg"
            fi
            if [ $AUTOEMBED -eq 1 ];then
                find "${SONGDIR}" -name '*.mp3' -printf '%p\n' | xargs -I {} realpath {} > "${songlist}"
                while read line; do
                    eyeD3 --add-image="${canon_cover}":FRONT_COVER "$SONGFILE" 2>/dev/null
                done < "${songlist}"
                rm "${songlist}"
            fi
        fi
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
        -s|--safe) SAFETY="TRUE"
            shift ;;      
        -q|--quiet) LOUD="0"
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
directory_check

IFS=$SAVEIFS

cleanup_end
