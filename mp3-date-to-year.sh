#!/bin/bash

##############################################################################
# This script is designed as a way to change the MP3 date to *just* a year
##############################################################################
startdir="$PWD"

# find is not used here so that both operations can be done and so that
# the whole operation doesn't die if mp3gain throws an error ungracefully

IFS=$'\n'

for f in $(find "$startdir" -name '*.mp3' );do 
    rdate=$(eyeD3 -l critical "$f" | grep -E "^release date:" | awk -F ': ' '{ print $2 }' | awk -F '\n' '{print $1}' | awk -F '-' '{print $1}')
    ordate=$(eyeD3 -l critical "$f" | grep -E "^original release date:" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}')
    recdate=$(eyeD3 -l critical "$f" | grep -E "^recording date:" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}')

	if [ -n "${rdate}" ];then
        eyeD3 --quiet -l critical --release-date="${rdate}" "$f"
    fi
	if [ -n "${ordate}" ];then
        eyeD3 --quiet -l critical --orig-release-date="${ordate}" "$f"
    fi
	if [ -n "${recdate}" ];then
        eyeD3 --quiet -l critical --recording-date="${recdate}" "$f"
    fi
done

unset IFS
