#!/bin/bash

########################################################################
# This script is designed as a wrapper for mp3gain that handles errors
# gracefully, as well as automates the encoding of the replaygain info
# into the id3 tags from APE
# 
# As the direct id3 tag writing seems to be working again, this is just
# to simplify and speed up the process for me.
########################################################################

if [ "$1" == "" ]; then
    startdir="$PWD"
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

for f in $(find "$startdir" -name '*.mp3' );do 
    # exists=$(ffprobe "${f}" 2>&1 | grep -c -e "replaygain_.*_gain")
    # unneeded since direct writing to ID3v2 is working
    mp3gain -e -c -T -p -r -k -s r -s i "${f}"
    
    # add -a and list of files for albumgain
    # will need a whole separate pass for "album level" and then recurse into
    # lower levels.
done

unset IFS

#to ensure python2 compatibility for the moment
#source /home/steven/apps/ape2id3/bin/activate
#find . -type f -iname '*.mp3' -exec ape2id3.py -df {} \;
#deactivate
