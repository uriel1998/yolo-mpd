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

# checking to see if currently playing/paused, otherwise exiting.

status=$(mpc | grep -c -e "\[")
if [ $status -lt 1 ];then
    echo "Not playing or paused"
    exit 88
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

##############################################################################
# functions
##############################################################################


function get_song_info(){
    SONGFILE="${MPD_MUSIC_BASE}"/$(mpc current --format %file%)
    SONGDIR=$(dirname "$(readlink -f "$SONGFILE")")
    SONGSTRING=$(mpc current --format "%artist% - %title% - %album%")
}

function prep_cover(){
    if [ -f "$SONGDIR"/folder.jpg ];then
        COVERFILE="$SONGDIR"/folder.jpg
    else
        if [ -f "$SONGDIR"/cover.jpg ];then
            COVERFILE="$SONGDIR"/cover.jpg
        fi
    fi

    if [ "$COVERFILE" == "" ];then
        COVERFILE=${DEFAULT_COVER}
    fi
    if [ "$COVERFILE" == "" ];then
        echo "No cover or default cover found."
        exit 99
    fi
    
    convert "${COVERFILE}" -resize "600x600" "${YADSHOW_CACHE}/nowplaying.album.jpg"
}

##############################################################################
# 
##############################################################################

get_song_info

prep_cover

yad --window-icon=musique --always-print-result --on-top --skip-taskbar --image-on-top --borders=5 --title "$SONGSTRING" --text-align=center --image "$YADSHOW_CACHE"/nowplaying.album.jpg --timeout=10 --no-buttons

read
