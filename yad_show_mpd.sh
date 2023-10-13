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

if [ "$1" == "--loud" ];then
    LOUD=1
else
    LOUD=0
fi

##############################################################################
# Create our cache
##############################################################################

if [ -z "${XDG_CACHE_HOME}" ];then
    export XDG_CACHE_HOME="${HOME}/.config"
fi

YADSHOW_CACHE="${XDG_CACHE_HOME}/yadshow"
if [ ! -d "${YADSHOW_CACHE}" ];then
    loud "Making cache directory"
    mkdir -p "${YADSHOW_CACHE}"
fi

##############################################################################
# functions
##############################################################################

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

function get_song_info(){
    SONGFILE="${MPD_MUSIC_BASE}"/$(mpc current --format %file%)
    echo "$SONGFILE"
    SONGDIR=$(dirname "$(readlink -f "$SONGFILE")")
    SONGSTRING=$(mpc current --format "%artist% - %title% - %album%")
}

function prep_cover(){
    loud "$SONGDIR"
    if [ -f "$SONGDIR"/folder.jpg ];then
        COVERFILE="$SONGDIR"/folder.jpg
    else
        loud "Not folder.jpg"
        if [ -f "$SONGDIR"/cover.jpg ];then
            COVERFILE="$SONGDIR"/cover.jpg
        fi
    fi

    if [ "$COVERFILE" == "" ];then
        COVERFILE=${DEFAULT_COVER}
    fi
    echo "${COVERFILE}"
    convert "${COVERFILE}" -resize "600x600" "${YADSHOW_CACHE}/nowplaying.album.jpg"
}

##############################################################################
# 
##############################################################################

get_song_info

prep_cover

yad --window-icon=musique --always-print-result --on-top --skip-taskbar --image-on-top --borders=5 --title "$SONGSTRING" --text-align=center --image "$YADSHOW_CACHE"/nowplaying.album.jpg --timeout=10 --no-buttons
