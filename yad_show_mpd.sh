#!/bin/bash

##############################################################################
#
#  Using YAD to show cover art
#  YAD = https://sourceforge.net/projects/yad-dialog/
#  (c) Steven Saus 2023
#  Licensed under the MIT license
#
##############################################################################


SONGSTRING=""
SONGFILE=""
SONGDIR=""
COVERFILE=""
MPD_MUSIC_BASE="${HOME}/Music"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_COVER="${SCRIPT_DIR}/defaultcover.jpg"

# checking if MPD_HOST is set or exists in .bashrc
# if neither is set, will just go with defaults (which will fail if 
# password is set.) 
if [ "$MPD_HOST" == "" ];then
    export MPD_HOST=$(cat ${HOME}/.bashrc | grep MPD_HOST | awk -F '=' '{print $2}')
fi

##############################################################################
# Create our cache
##############################################################################

if [ -z "${XDG_CACHE_HOME}" ];then
    export XDG_CACHE_HOME="${HOME}/.config"
fi

YADSHOW_CACHE="${XDG_CACHE_HOME}/yadshow"
if [ ! -d "${YADSHOW_CACHE}" ];then
    echo "Making cache directory"
    mkdir -p "${YADSHOW_CACHE}"
fi

# rounding rectangles:
# https://www.imagemagick.org/Usage/compose/
# https://legacy.imagemagick.org/Usage/thumbnails/#rounded_borde

function round_rectangles (){
    
    #NEED TO CLEAN UP FILE HANDLING AND OUTPUT AND SHIT
    
  convert "${1}" \
      -format 'roundrectangle 1,1 %[fx:w+4],%[fx:h+4] 15,15' \
      -write info:tmp.mvg \
      -alpha set -bordercolor none -border 3 \
      \( +clone -alpha transparent -background none \
         -fill white -stroke none -strokewidth 0 -draw @tmp.mvg \) \
      -compose DstIn -composite \
      \( +clone -alpha transparent -background none \
         -fill none -stroke black -strokewidth 3 -draw @tmp.mvg \
         -fill none -stroke white -strokewidth 1 -draw @tmp.mvg \) \
      -compose Over -composite               "${2}"
}



# Checking to see if currently playing/paused, otherwise exiting.
# checks local players like audacity first, since it's always a local player, as opposed to MPD

    aud_status=$(audtool playback-status)
    if [ "${aud_status}" == "playing" ];then
        SONGSTRING=$(audtool current-song)
        SONGFILE=$(audtool current-song-filename)
    fi
    if [ ! -f "${SONGFILE}" ];then
        Clementine_Status=$(qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus 2>/dev/null)
        if [ "${Clementine_Status}" == "Playing" ];then
            bob=$(qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)
            album=$(echo "${bob}" | grep ":album:" | cut -d ' ' -f 2-)
            artist=$(echo "${bob}" | grep ":artist:" | cut -d ' ' -f 2-)
            title=$(echo "${bob}" | grep ":title:" | cut -d ' ' -f 2-)
            coverurl=$(echo "${bob}" | grep ":artUrl:" | cut -d '/' -f 3- )
            SONGSTRING="${artist} - ${album} - ${title}"
            SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d '/' -f 3-)
        fi
    fi
    if [ ! -f "${SONGFILE}" ];then
        Strawberry_Status=$(qdbus org.mpris.MediaPlayer2.strawberry /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus 2>/dev/null)
        if [ "${Strawberry_Status}" == "Playing" ];then
            bob=$(qdbus org.mpris.MediaPlayer2.strawberry /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)
            album=$(echo "${bob}" | grep ":album:" | cut -d ' ' -f 2-)
            artist=$(echo "${bob}" | grep ":artist:" | cut -d ' ' -f 2-)
            title=$(echo "${bob}" | grep ":title:" | cut -d ' ' -f 2-)
            coverurl=$(echo "${bob}" | grep ":artUrl:" | cut -d '/' -f 3- )
            SONGSTRING="${artist} - ${album} - ${title}"
            SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d '/' -f 3-)
        fi
    fi
    if [ ! -f "${SONGFILE}" ];then
        # checking if MPD_HOST is set or exists in .bashrc
        # if neither is set, will just go with defaults (which will fail if 
        # password is set.) 
        if [ "$MPD_HOST" == "" ];then
            export MPD_HOST=$(cat ${HOME}/.bashrc | grep MPD_HOST | awk -F '=' '{print $2}')
        fi
        status=$(mpc | grep -c -e "\[")
        if [ $status -lt 1 ];then
            echo "Not playing or paused"            
        else
            SONGFILE="${MPD_MUSIC_BASE}"/$(mpc current --format %file%)
            SONGSTRING=$(mpc current --format "%artist% - %album% - %title%")
        fi
    fi


    if [ -f "$SONGDIR"/folder.jpg ];then
        COVERFILE="$SONGDIR"/folder.jpg
    else
        if [ -f "$SONGDIR"/cover.jpg ];then
            COVERFILE="$SONGDIR"/cover.jpg
        fi
    fi

    if [ "$COVERFILE" == "" ];then
        if [ -f "${coverurl}" ];then
            COVERFILE="${coverurl}"
            coverurl=""
        else
            COVERFILE=${DEFAULT_COVER}
        fi
    fi

    if [ "$COVERFILE" == "" ];then
        echo "No cover or default cover found."
        exit 99
    fi

    TEMPFILE3=$(mktemp)    
    convert "${COVERFILE}" -resize "600x600" "${TEMPFILE3}"
    round_rectangles "${TEMPFILE3}" "${YADSHOW_CACHE}/nowplaying.album.png"



##############################################################################
# Display what we have found
##############################################################################


yad --window-icon=musique --always-print-result --on-top --skip-taskbar --image-on-top --borders=5 --title "$SONGSTRING" --text-align=center --image "$YADSHOW_CACHE"/nowplaying.album.png --timeout=10 --no-buttons

read
