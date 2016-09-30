#!/bin/bash

########################################################################
# This script is designed as a wrapper for mp3gain that handles the 
# problem that bpm-tools (or bpm-tag) has with obliterating the coverart
# and genre tags (apparently because it writes old versions of the tags)
########################################################################

if [[ "$@" =~ "save-existing" ]]; then
	SaveExisting=1
else
	SaveExisting=0
fi
if [[ "$@" =~ "skip-existing" ]]; then
	SkipExisting=1
else
	SkipExisting=0
fi
if [[ "$@" =~ "quiet" ]]; then
	Quiet=1
else
	Quiet=0
fi

startdir="$PWD"

# find is not used here so that both operations can be done and so that
# the whole operation doesn't die if mp3gain throws an error ungracefully

IFS=$'\n'

for f in $(find "$startdir" -name '*.mp3' );do 
	if [ Quiet = 0 ]; then
		echo "Analyzing $f"
	fi
	re='^[0-9]+$'
	existingbpm=`eyeD3  "$f"  | grep BPM | awk -F ':' '{ print $2 }' | awk '{print $2}'`
	sleep 1
	if ! [[ $existingbpm =~ $re ]] && [[ "$existingbpm" != "" ]]; then
		echo "Existing BPM jacked up!!" >&2
	elif [ $SkipExisting = 0 ];then
		sleep 1
		bpmtemp=$(bpm-tag -f -n "$f" 2>&1| awk -F ': ' '{ print $2}' | awk -F '.' '{print $1}')
		if ! [[ $bpmtemp =~ $re ]] ; then
			echo "No valid BPM detected!" >&2
		else
			#echo "$bpmtemp"
			#echo "$existingbpm"
			if [ $SaveExisting = 1 ];then
				if [[ "$bmptemp" =~ "$existingbpm" ]];then
					echo "Warning: BPMs differ for $f!"
				fi
			else
				eyeD3 --quiet --bpm="$bpmtemp" "$f"
			fi
		fi
	fi
done

unset IFS