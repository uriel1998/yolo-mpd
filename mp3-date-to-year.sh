#!/bin/bash

##############################################################################
# This script is designed as a way to change the MP3 date to *just* a year
##############################################################################
startdir="$PWD"

# find is not used here so that both operations can be done and so that
# the whole operation doesn't die if mp3gain throws an error ungracefully

IFS=$'\n'



for f in $(find "$startdir" -name '*.mp3' );do 
    
    scratch=$(ffprobe "${f}" 2>&1 )
    o_rdate=$(echo "${scratch}" | grep -E "^    date" | awk -F ': ' '{ print $2 }'  | tr -d [:cntrl:])
    o_ordate=$(echo "${scratch}" | grep -E "^    originalyear" | awk -F ': ' '{ print $2 }'  | tr -d [:cntrl:])
    o_recdate=$(echo "${scratch}" | grep -E "^    TDOR"| awk -F ': ' '{ print $2 }'  | tr -d [:cntrl:])

    rdate=$(echo "${scratch}" | grep -E "^    date" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}' | tr -d [:cntrl:])
    ordate=$(echo "${scratch}" | grep -E "^    originalyear" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}' | tr -d [:cntrl:])
    recdate=$(echo "${scratch}" | grep -E "^    TDOR" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}' | tr -d [:cntrl:])
    
    # scratch=$(eyeD3 -l critical "${f}")
    
    # o_rdate=$(echo "${scratch}" | grep -E "^release date:" | awk -F ': ' '{ print $2 }' )
    # o_ordate=$(echo "${scratch}" | grep -E "^original release date:" | awk -F ': ' '{ print $2 }' )
    # o_recdate=$(echo "${scratch}" | grep -E "^recording date:" | awk -F ': ' '{ print $2 }' )

    # rdate=$(echo "${scratch}" | grep -E "^release date:" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}')
    # ordate=$(echo "${scratch}" | grep -E "^original release date:" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}')
    # recdate=$(echo "${scratch}" | grep -E "^recording date:" | awk -F ': ' '{ print $2 }' | awk -F '-' '{print $1}')

	if [ -n "${rdate}" ];then
        if [ "${o_rdate}" != "${rdate}" ];then
            echo "### Changing release date for ${f} from ${o_rdate} ${rdate}"
            eyeD3 --quiet -l critical --release-date="${rdate}" "$f"
        else
            echo "No change needed with release date for ${f}"
        fi
    fi
	if [ -n "${ordate}" ];then
        if [ "${o_ordate}" != "${ordate}" ];then
            echo "### Changing original release date for ${f}"
            eyeD3 --quiet -l critical --orig-release-date="${ordate}" "$f"
        else
            echo "No change needed with original release date for ${f}"
        fi
    fi
	if [ -n "${recdate}" ];then
        if [ "${o_recdate}" != "${recdate}" ];then
            echo "### Changing recording date for ${f} from ${o_recdate} to ${recdate}"
            eyeD3 --quiet -l critical --recording-date="${recdate}" "$f"
        else
            echo "No change needed with recording date for ${f}"
        fi
    fi
done

unset IFS
