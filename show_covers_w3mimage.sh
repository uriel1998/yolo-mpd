#!/usr/bin/env bash

# requires mpc to get song info


########### Configuration
# TODO:  Sane defaults and autodetect
MUSICDIR="${HOME}/Music"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_COVER="${SCRIPT_DIR}/defaultcover.jpg"

function get_album_art {
	echo "### Finding cover for $ALBUM..."
	if [ -f "$SONGDIR/cover.jpg" ]; then
		COVERART="$SONGDIR/cover.jpg"
	elif [ -f "$SONGDIR/folder.jpg" ]; then
		COVERART="$SONGDIR/folder.jpg"
	else
		COVERART="${DEFAULT_COVER}"
	fi
}

	# uses xseticon, wmctrl, and transset to make its little terminal 
	# window all pretty.  Feel free to delete these lines.

#	snark=$(echo $WINDOWID)
#	xseticon -id $snark ~/.icons/Faenza-Like/iKamasutra.png
#	wmctrl -i -r "$snark" -T "Album Art Downloader" 
#	transset 0.7 -i "$snark"


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
			echo "$COVERART"
			w3mimg.sh "$COVERART"
		else
			echo "We're getting wrong information for some reason."
		fi
		done
