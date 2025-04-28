#!/bin/bash

########################################################################
# This script is designed as a wrapper for LOADGAIN that handles errors
# gracefully, as well as automates the encoding of the replaygain info
# into the id3 tags from APE
# 
# As the direct id3 tag writing seems to be working again, this is just
# to simplify and speed up the process for me.

# Also preserves file date which loadgain doesn't do.
########################################################################

if [ "$1" == "" ]; then
    startdir=$(realpath "${PWD}")
else
    if [ -d "$1" ]; then
        startdir="$1"
    else
        echo "Not a valid directory; exiting."
        exit 1
    fi
fi


# find is not used here so that both operations can be done and so that
# the whole operation doesn't die if mp3gain throws an error ungracefully

IFS=$'\n'
    echo "${startdir}"
    dirlist=$(find "${startdir}" -name '*.mp3' -printf '"%h"\n' | xargs -I {} realpath {} | sort -u)
    watchcount=0
    while read -r line; do  
        if [ $watchcount -gt 6 ];then
            wait
            watchcount=0
        fi
        watchcount=$(( watchcount + 1 ))    
        (
        SONGDIR=$(realpath "${line}")
        filetime=$(stat -c '%y' $(find "${line}" -maxdepth 1 -iname "*.mp3" -type f -printf '%p\n' | shuf |  head -n 1))
        find "${line}" -maxdepth 1 -iname "*.mp3" -type f -exec loudgain -I3 -S -L -a -k -s e {} +
        for f in $(find "${line}" -maxdepth 1 -iname "*.mp3" -type f); do
            touch -d "${filetime}" "${f}"
        done
        ) &

    done < <(find "${startdir}" -name '*.mp3' -printf '"%h"\n' | xargs -I {} realpath {} | sort -u)
    wait
    # strip other than idv2
    # write tags + extended
    # album (and track) gain
    # noclip 
    # lowercase
    # id3v2.3 tags
    

unset IFS
