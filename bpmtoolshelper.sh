#!/bin/bash

########################################################################
# This script is designed as a wrapper for bpm-tag and eyeD3 that both
# tags with BPM but also preserves file date
########################################################################
Quiet=0

if [[ "$@" =~ "--save" ]]; then
    SaveExisting=1
else
    SaveExisting=0
fi
if [[ "$@" =~ "--skip" ]]; then
    SkipExisting=1
else
    SkipExisting=0
fi
if [[ "$@" =~ "--quiet" ]]; then
    Quiet=1
else
    Quiet=0
fi

startdir="$PWD"

# find is not used here so that both operations can be done and so that
# the whole operation doesn't die if mp3gain throws an error ungracefully

IFS=$'\n'
watchcount=0
for f in $(find "${startdir}/" -name '*.mp3' );do 
    
    if [ $Quiet = 0 ]; then
        echo "Analyzing ${f}"
    fi
    re='^[0-9]+$'
    existingbpm=`eyeD3  "${f}" 2>/dev/null  | grep BPM | awk -F ':' '{ print $2 }' | awk '{print $2}'`
    if ! [[ $existingbpm =~ $re ]] && [[ "$existingbpm" != "" ]]; then
        echo "Existing BPM jacked up!!" >&2
    elif [ $SkipExisting = 0 ];then
        if [ $watchcount -gt 3 ];then
            wait
            watchcount=0
        fi
        watchcount=$(( watchcount + 1 ))
        (
        filetime=$(stat -c '%y' "${f}")
        bpmtemp=$(bpm-tag -f -n "${f}" 2>&1| grep -v "not found" | awk -F ': ' '{ print $2}' | awk -F '.' '{print $1}')
        if ! [[ $bpmtemp =~ $re ]] ; then
            echo "No valid BPM detected!" >&2
        else
            if [ $SaveExisting = 1 ];then
                if [[ "$bmptemp" =~ "$existingbpm" ]];then
                    echo "Warning: BPMs differ for ${f}!"
                fi
            else
                eyeD3 --quiet --bpm="$bpmtemp" "${f}" 2>/dev/null 1>/dev/null
                touch -d "${filetime}" "${f}"
            fi
        fi
        ) &
    fi

done
wait
unset IFS
