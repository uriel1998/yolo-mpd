#!/bin/bash

##############################################################################
#
#  A script to show album art covers in the terminal 
#  Supports multiple players (through qdbus) and MPD
#  Supports multiple terminal image viewers
#  (c) Steven Saus 2024
#  Licensed under the MIT license
#
##############################################################################

YAD_NOTIFY=""
SONGSTRING=""
SONGFILE=""
SONGDIR=""
COVERFILE=""
MPD_MUSIC_BASE="${HOME}/Music"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_COVER="${SCRIPT_DIR}/defaultcover.jpg"
SAME_SONG=0
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
      if [ -f "${PWD}/tmp.mvg" ];then
        rm "${PWD}/tmp.mvg"
      fi
}



function show_album_art {

    if [ ! -f "${COVERFILE}" ]; then
        echo "### Something's horribly wrong"
    else

        clear
        cat "${YADSHOW_CACHE}/songshort"
        #in case not automatically listed
        cols=$(tput cols)
        lines=$(tput lines)
        if [ "$cols" -gt "$lines" ]; then
            gvalue="$cols"
            lvalue="$lines"
        else
            gvalue="$lines"
            lvalue="$cols"
        fi
        bvalue=$(echo "scale=4; $gvalue-3" | bc)
        if [ "$bvalue" -gt 78 ];then
            bvalue=78
        fi
        if [ -f $(which timg) ];then
            timg -U -pq "${COVERFILE}"
        else
            if [ -f $(which jp2a) ];then
                # if it looks bad, try removing invert
                jp2a --colors --width=${cols} --invert "${COVERFILE}"
            else
                if [ -f $(which img2txt.py) ];then
                    img2txt.py --ansi --targetAspect=0.5 --maxLen="$bvalue" "${COVERFILE}"
                else
                    if [ -f $(which asciiart) ];then
                        asciiart -c -w "$bvalue" "${COVERFILE}" 
                    else
                        echo "No viewer available on $PATH"
                        exit 99
                    fi
                fi
            fi
        fi
    fi
}

find_playing_song (){
    # Checking to see if currently playing/paused, otherwise exiting.
    # checks local players like audacity first, since it's always a local player, as opposed to MPD
    IF_URL=0
    SONGFILE=""
    SONGSTRING=""
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
            IF_URL==$(echo "${bob}" | grep ":url:" | grep -c "http")
            if [ "$IF_URL" == "0" ];then
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d '/' -f 3-)
            else
                #is internet stream
                echo "internet"
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 2)
                echo "#${album}#"
                if [ "${album}" == "" ];then
                    
                    album=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 3)
                    echo "$album"
                fi
            fi
            SONGSTRING="${artist} - ${album} - ${title}"
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
            IF_URL==$(echo "${bob}" | grep ":url:" | grep -c "http")
            if [ "$IF_URL" == "0" ];then
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d '/' -f 3-)
            else
                #is internet stream
                echo "internet"
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 2)
                echo "#${album}#"
                if [ "${album}" == "" ];then
                    
                    album=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 3)
                    echo "$album"
                fi
            fi
            SONGSTRING="${artist} - ${album} - ${title}"
        fi
    fi
   if [ ! -f "${SONGFILE}" ];then
        Plexamp_Status=$(qdbus org.mpris.MediaPlayer2.Plexamp /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus 2>/dev/null)
        if [ "${Plexamp_Status}" == "Playing" ];then
            bob=$(qdbus org.mpris.MediaPlayer2.Plexamp /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)
            album=$(echo "${bob}" | grep ":album:" | cut -d ' ' -f 2-)
            artist=$(echo "${bob}" | grep ":artist:" | cut -d ' ' -f 2-)
            title=$(echo "${bob}" | grep ":title:" | cut -d ' ' -f 2-)
            coverurl=$(echo "${bob}" | grep ":artUrl:" | cut -d '/' -f 3- )
            if [ -f "${coverurl}" ];then 
                COVERFILE="${coverurl}"
            fi
            IF_URL==$(echo "${bob}" | grep ":url:" | grep -c "http")
            if [ "$IF_URL" == "0" ];then
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d '/' -f 3-)
            else
                #is internet stream
                #echo "internet"
                SONGFILE=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 2)
                #echo "#${album}#"
                if [ "${album}" == "" ];then
                    
                    album=$(echo "${bob}" | grep ":url:" | cut -d ' ' -f 3)
                    echo "$album"
                fi
            fi
            SONGSTRING="${artist} - ${album} - ${title}"
        fi
    fi
    if [ ! -f "${SONGFILE}" ] && [ "${IF_URL}" == "0" ];then
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
    SONGDIR=$(dirname "${SONGFILE}")
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
    bob=$(cat "${YADSHOW_CACHE}/songinfo")
    # TEST HERE; if it's the same, then bounce back
    if [[ "${SONGSTRING}" != "${bob}" ]]; then 
        SAME_SONG=0
        echo "${SONGSTRING}" > "${YADSHOW_CACHE}/songinfo"
        if [ ${#SONGSTRING} -gt 60 ]; then
            SONGSTRING=$(echo "${SONGSTRING}" | awk -F ' - ' '{print $1" - "$3}')
            if [ ${#SONGSTRING} -gt 60 ]; then
                SONGSTRING=$(echo "${SONGSTRING}" | awk -F ' - ' '{print $2}')
                if [ ${#SONGSTRING} -gt 60 ]; then
                    # taking out any "feat etc in parentheses"
                    SONGSTRING=$(echo "${SONGSTRING}" | sed -e 's/([^)]*)//g' )
                fi
            fi
        fi
        echo "${SONGSTRING}" > "${YADSHOW_CACHE}/songshort"
        
        if [ "$COVERFILE" == "" ];then
            # use the default cover in the script directory
            COVERFILE=$(echo "No cover or default cover found.")
        fi
    else
        SAME_SONG=1
    fi
}

main () {

    SAME_SONG=0
    find_playing_song
    if [[ $SAME_SONG -eq 0 ]];then
        # global var COVERFILE should be set now
        # do we have imagemagick?
        if [ -f $(which convert) ];then
            TEMPFILE3=$(mktemp)    
            convert "${COVERFILE}" -resize "600x600" "${TEMPFILE3}"
            round_rectangles "${TEMPFILE3}" "${YADSHOW_CACHE}/nowplaying.album.png"
            rm "${TEMPFILE3}"
        else
            cp -f "${COVERFILE}" "${YADSHOW_CACHE}/nowplaying.album.png"
        fi

        if [ $YAD_NOTIFY -eq 1 ];then
            notify-send --icon=${YADSHOW_CACHE}/nowplaying.album.png "$(cat ${YADSHOW_CACHE}/songinfo)" --urgency=low
        fi
        ##############################################################################
        # Display what we have found
        ##############################################################################

        show_album_art "${COVERFILE}"
    fi
}

# reset songinfo for startup
echo "" > "${YADSHOW_CACHE}/songinfo"
if [ "$1" == "--notify" ];then
    YAD_NOTIFY=1
else 
    YAD_NOTIFY=0
fi

while true; do

    main
    sleep 2
done
