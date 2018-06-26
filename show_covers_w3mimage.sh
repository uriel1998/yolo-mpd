#!/bin/bash

# requires mpc to get song info


########### Configuration
# TODO:  Sane defaults and autodetect
MUSICDIR=~/music
TMPDIR=~/tmp

function get_album_art {
	echo "### Finding cover for $ALBUM..."
	coverart1="$SONGDIR"
	#coverart1=$MUSICDIR/"$ALBUM"/"$ARTIST"
	# trimming characters that jack it up...
	coverart1=$(echo "$coverart1"| sed s/[:.]//g)
	# getting lowercase and removing final slash
	coverart="${coverart1,,}"
	coverart="${coverart%/}"

	if [ -f "$coverart/cover.jpg" ]; then
		COVERART="$coverart/cover.jpg"
	elif [ -f "$SONGDIR/folder.jpg" ]; then
		COVERART="$coverart/folder.jpg"
	else
		curl https://unsplash.it/512/512/?random -o $TMPDIR/unsplash.jpg
		convert $TMPDIR/unsplash.jpg -blur 0x3 $TMPDIR/unsplash_blur.jpg
		COVERART="${$TMPDIR/unsplash_blur.jpg}"
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
fi
