#!/bin/bash

# requires mpc to get song info
# Snagged mpc-based looping from http://www.hackerposse.com/~rozzin/mpdjay


########### Configuration
# TODO:  Sane defaults and autodetect
MUSICDIR=~/music



function get_album_art {

	echo "### Finding cover for $ALBUM..."

	# existing file, from ID3 tag, from internet.  Always to cover.jpg
	# always prefer cover art stored in music directory, then mp3
	# presumption is that it's easier to just read jpg in directory... and to delete if wrong
	coverart1="$SONGDIR"
	#coverart1=$MUSICDIR/"$ALBUM"/"$ARTIST"
	# trimming characters that jack it up...
	coverart1=$(echo "$coverart1"| sed s/[:.]//g)
	# getting lowercase and removing final slash
	coverart="${coverart1,,}"
	coverart="${coverart%/}"

	if [ ! -f "$coverart/cover.jpg" ]; then
		echo "### Cover art not found in $coverart"
	else
####### OMIT THIS NEXT LINE IF YOU DO NOT USE AVIEW
####### aview doesn't have a render-and-done mode like img2txt, but it 
####### looks hella better
		killall aview
		
		echo "### Cover art found in music directory."
		#in case not automatically listed
		cols=$(tput cols)
		lines=$(tput lines)

########SELECT WHICH VIEWER YOU WISH TO USE HERE
		#img2txt -H $lines -f ansi "$coverart/cover.jpg"
		anytopnm "$coverart/cover.jpg" | aview -driver curses &
	fi
	# just in case there is STILL nothing, a last test.
}


# Here's the main loop

	(echo qman-startup; mpc idleloop) \
	| while read event
	do
		if [ "$event" = "mixer" ]
		then
			continue
		fi
		if [ "$event" = "update" ]
		then
			continue
		fi
		ARTIST=$(mpc --format %artist% | head -1)
		ALBUM=$(mpc --format %album% | head -1)
		SONGFILE=$(mpc --format %file% | head -1)
		SONGFILE=$MUSICDIR/"$SONGFILE"
		SONGDIR=$(dirname "$SONGFILE")
		if [ -f "$SONGFILE" ]; then
			echo "Getting info for $ARTIST and $ALBUM"
			get_album_art
		else
			echo "We're getting wrong information for some reason."
		fi
	done
fi
clear