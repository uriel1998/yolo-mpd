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
LYRICSFILE=""
MPD_MUSIC_BASE="${HOME}/Music"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
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


function show_lyrics {

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

    bob=$(cat "${YADSHOW_CACHE}/songinfo")
    # TEST HERE; if it's the same, then bounce back
    if [[ "${SONGSTRING}" != "${bob}" ]]; then 
        SAME_SONG=0

        # find lyrics
        # using SONGFILE not dir

        if [ "$LYRICSFILE" == "" ];then
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
        # global var LYRICSFILE should be set now
        cp -f "${LYRICSFILE}" "${YADSHOW_CACHE}/nowplaying.lyrics.md"
        ##############################################################################
        # Display what we have found
        ##############################################################################
        show_lyrics "${LYRICSFILE}"

    fi
}

# reset songinfo for startup
echo "" > "${YADSHOW_CACHE}/songinfo"


while true; do
    #$TMUX_PANE is the pane 
#    (rich ./sidebar &)  ;notify-send "hi";sleep 5;notify-send "hsitl";sleep 5;tmux send-keys '';ls

    main
    sleep 2
done
