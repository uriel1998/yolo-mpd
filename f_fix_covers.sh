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

# TODO: start testing, lol.
# safety mode (report changes, do not do them.)


AUTOEMBED=0
TMPDIR=$(mktemp -d)
startdir="$PWD"
dirlist=$(mktemp)
songlist=$(mktemp)
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

    songdata=$(ffprobe "$SONGFILE" 2>&1)
    # big long grep string to avoid all the possible frakups I found, lol
    ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
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
    MBID=$(ffmpeg -i "$SongFile" 2>&1 | grep "MusicBrainz Album Id:" | awk -F ': ' '{print $2}')
    if [ "$MBID" = '' ] || [ "$MBID" = 'null' ];then
        API_URL="http://coverartarchive.org/release/$MBID/front"
        IMG_URL=$(curl "$API_URL" | awk -F ': ' '{print $2}')
    fi
        
    if [ "$IMG_URL" = '' ] || [ "$IMG_URL" = 'null' ];then
        echo "Not on CoverArt Archive."
    else
        wget -q "$IMG_URL" -O "$TMPDIR/dl_cl1.jpg"
    fi

    ##########################################################################
    # Attempt to find cover art via glyrc if it's in $PATH
    ##########################################################################
    glyrc_bin=$(which glyrc)
    if [ -f $glyrc_bin ];then
        glyrc cover --timeout 15 --artist "$ARTIST" --album "$ALBUM" --write "$TMPDIR/cover.tmp" --from "musicbrainz;discogs;coverartarchive;rhapsody;lastfm"
        if [ -f "$TMPDIR/cover.tmp" ];then
            convert "$TMPDIR/cover.tmp" "$TMPDIR/dl_cl2.jpg"
        fi
    fi
    
    ##########################################################################
    # Attempt to find cover art via sacad if it's in $PATH
    ##########################################################################
    
    sacad_bin=$(which sacad)
    if [ -f "${sacad_bin}" ];then 
        exec_string=$(printf "%s \"%s\" \"%s\" 512 %s/FRONT_COVER.jpeg" "${sacad_bin}" "${ARTIST}" "${ALBUM}" "$TMPDIR")
        eval "$exec_string"
        if [ -f "$TMPDIR/FRONT_COVER.jpeg" ];then
            convert "$TMPDIR/FRONT_COVER.jpeg" "$TMPDIR/dl_cl2.jpg"
        fi
    fi

    canon_cover=$(show_compare_images "$TMPDIR/dl_cl2.jpeg" "$TMPDIR/dl_cl2.jpeg" "$TMPDIR/dl_cl2.jpeg")
    echo "${canon_cover}"
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
    

mp3_check () {
    
    find "${MusicDir}" -name '*.mp3' -printf '%p\n' | xargs -I {} realpath {} > "${songlist}"
    CURRENTENTRY="0"
    ENTRIES=$(cat ${songlist} | wc -l)

    # read in line by line the $songlist file
    while read line; do
        cleanup

        echo "$CURRENTENTRY of $ENTRIES: ${line}"
        CURRENTENTRY=$(($CURRENTENTRY+1))
    
        SONGFILE=""
        SONGDIR=""
        CA_Embedded="" # fill with checksum if found
        CA_File_Folder=""
        CA_File_Cover=""
        SONGFILE="${line}"
        SONGDIR=$(dirname $(realpath ${line}))
    
        # does that MP3 have cover art?
        songdata=$(ffprobe "$SONGFILE" 2>&1)
        # big long grep string to avoid all the possible frakups I found, lol
        
        CA_Embedded=$(echo "$songdata" | grep Cover | grep -c "front")
        if [ $CA_Embedded -gt 0 ];then
            CA_Embedded=0
            # Double checking
            DATA=`eyeD3 "$SONGFILE" 2>/dev/null | sed 's/\x0//g' `
            CA_Embedded=$(echo "$DATA" | grep -c "FRONT_COVER" )
        fi

        # is there cover art in the directory?
        if [ -f ${SONGDIR}/cover.jpg ]; then
            CA_File_Cover=$(shasum "${SONGDIR}/cover.jpg" | awk '{print $1}')
        fi
        if [ -f ${SONGDIR}/folder.jpg ]; then
            CA_File_Folder=$(shasum "${SONGDIR}/folder.jpg" | awk '{print $1}')
        fi
        # extract the MP3 cover, if present.
        if [ CA_Embedded -eq 1 ];then
            extract_cover "${SONGFILE}" "${SONGDIR}"
            if [ -f "${TMPDIR}/FRONT_COVER.jpeg" ]; then
                CA_Embedded=$(shasum "${TMPDIR}/FRONT_COVER.jpeg" | awk '{print $1}')
            fi
        fi 
        
        # Compare cover files that are present.
        # any one of three not match, choose canon cover, go from there.
        
        # All three match
        if [[ "$CA_File_Folder" == "$CA_File_Cover" ]] && [[ "$CA_Embedded" == "$CA_File_Cover" ]];then
            echo "Everything matches!"
        else
            canon_cover=$(show_compare_images "${SONGDIR}/cover.jpg" "${SONGDIR}/folder.jpg" "$TMPDIR/FRONT_COVER.jpeg")
            if [ "${canon_cover}" == "ABORT" ];then
                canon_cover=""
            fi
            if [ "${canon_cover}" == "SEARCH" ];then
                cleanup
                canon_cover=search_for_cover
            fi
    
            if [ -f "${canon_cover}" ]; then # this will need to be specified when also testing for what was embedded cover
                # synchronizing files
                if [ "${canon_cover}" == "${SONGDIR}/folder.jpg" ];then
                    cp -f "${canon_cover}" "${SONGDIR}/cover.jpg"
                    eyeD3 --add-image="${canon_cover}":FRONT_COVER "$SONGFILE" 2>/dev/null
                fi
                if [ "${canon_cover}" == "${SONGDIR}/cover.jpg" ];then
                    cp -f "${canon_cover}" "${SONGDIR}/folder.jpg"
                    eyeD3 --add-image="${canon_cover}":FRONT_COVER "$SONGFILE" 2>/dev/null
                fi
                if [ "${canon_cover}" == "$TMPDIR/FRONT_COVER.jpeg" ];then
                    cp -f "$CA_Embed_Cover" "${SONGDIR}/folder.jpg"
                    cp -f "$CA_Embed_Cover" "${SONGDIR}/cover.jpg"
                fi
            fi
        fi
    done < "$songlist"
    
}


# This does NOT check the MP3 files *at all*.
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
        
        ####################################################################
        # Do cover files exist? If so, make sure both cover and folder exist.
        ####################################################################        
        if [ -f "${SONGDIR}/cover.jpg" ]; then
            CA_File_Cover=$(shasum "${SONGDIR}/cover.jpg" | awk '{print $1}')
        fi
        if [ -f "${SONGDIR}/folder.jpg" ]; then
            CA_File_Folder=$(shasum "${SONGDIR}/folder.jpg" | awk '{print $1}')
        fi
        if [[ "$CA_File_Folder" = "$CA_File_Cover" ]] && [[ "$CA_File_Folder" != "" ]];then
            loud "Both cover and folder jpg match!"
        else
            # If there are NO images in the directory, find embedded ones from all 
            # MP3s, compare them, and go from there.
            if [[ "$CA_File_Folder" == "" ]] && [[ "$CA_File_Cover" == "" ]];then
                loud "No cover files found; examining MP3s in directory."
                find "${SONGDIR}" -name '*.mp3' -printf '%p\n' | xargs -I {} realpath {} > "${songlist}"
                cleanup
                # Get all embedded front covers
                FOUND_COVERS=0
                while read line; do
                    SONGFILE="${line}"
                    songdata=$(ffprobe "$SONGFILE" 2>&1)
                    # big long grep string to avoid all the possible frakups I found, lol
                    CA_Embedded=$(echo "$songdata" | grep Cover | grep -c "front")
                    if [ $CA_Embedded -gt 0 ];then
                        extract_cover "${SONGFILE}" "${SONGDIR}"
                        if [ -f "${TMPDIR}/FRONT_COVER.jpeg" ];then 
                            FOUND_COVERS=$((FOUND_COVERS + 1))
                            loud "Found ${FOUND_COVERS} covers so far!"
                            mv "${TMPDIR}/FRONT_COVER.jpeg" "${TMPDIR}/${FOUND_COVERS}FOUND_COVER.jpeg"                    
                        fi
                    fi
                done < "${songlist}"
                
                # If one cover, only checks if AUTO is not on. 
                if [ $AUTOEMBED -eq 1 ] && [ $FOUND_COVERS -eq 1 ];then
                    canon_cover="${TMPDIR}/1FOUND_COVER.jpeg"
                else
                    if [ $FOUND_COVERS -gt 0 ];then
                        #find ${TMPDIR} -name '*FOUND_COVER.jpeg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g'
                        canon_cover=$(show_compare_images "$(find ${TMPDIR} -name '*FOUND_COVER.jpeg' -print0 | xargs -0 -I {} echo {} | sed 's@\ @\\ @g')")
                    fi
                fi
                canon_cover=$(trim "${canon_cover}")
                /usr/bin/ls "${canon_cover}"
                if [[ ! -s "${canon_cover}" ]];then 
                    cleanup
                    canon_cover=$(search_for_cover)
                fi
            else
                # compare the two cover images!
                canon_cover=$(show_compare_images "${SONGDIR}/cover.jpg" "${SONGDIR}/folder.jpg")
                if [ "${canon_cover}" == "ABORT" ];then
                    canon_cover=""
                fi
                if [ "${canon_cover}" == "SEARCH" ];then
                    cleanup
                    canon_cover=search_for_cover
                fi
            fi
            if [ -f "${canon_cover}" ]; then # this will need to be specified when also testing for what was embedded cover
                # synchronizing files
                if [ "${canon_cover}" != "${SONGDIR}/cover.jpg" ];then
                    cp -f "${canon_cover}" "${SONGDIR}/cover.jpg"
                fi
                if [ "${canon_cover}" != "${SONGDIR}/folder.jpg" ];then
                    cp -f "${canon_cover}" "${SONGDIR}/folder.jpg"
                fi
            fi
        fi
    done < "$dirlist"
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
        -f|--file) MODE="FILE"
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
if [ "$MODE" == "DIR" ];then
    loud "Checking files in directory."
    directory_check
fi
if [ "$MODE" == "FILE" ];then
    loud "Checking all MP3s and files in directory."
    mp3_check
fi
IFS=$SAVEIFS
cleanup_end
