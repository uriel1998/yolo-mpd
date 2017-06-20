#!/bin/bash
# bc for calculation
# curl for unsplash images
# requires mpc to get song info
# Snagged mpc-based looping from http://www.hackerposse.com/~rozzin/mpdjay


########### Configuration
# TODO:  Sane defaults and autodetect
MUSICDIR=~/music
TMPDIR=~/tmp

########### Render Options
# aview
# img2text https://github.com/hit9/img2txt
# w3mimage - not put in here
# asciiart
# xseticon
# wmctrl

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
		curl -s https://unsplash.it/512/512/?random -o $TMPDIR/unsplash.jpg
		convert $TMPDIR/unsplash.jpg -blur 0x3 $TMPDIR/unsplash_blur.jpg
		COVERART="$TMPDIR/unsplash_blur.jpg"
	fi
}

function show_album_art {


	if [ ! -f "$COVERART" ]; then
		echo "### Something's horribly wrong"
	else

		clear
		#in case not automatically listed
		cols=$(tput cols)
		lines=$(tput lines)
		if [ "$cols" -gt "$lines" ]; then
			gvalue="$cols"
			lvalue="$lines"
		else
			gvalue="$lines"
			lvalue="$cols"
		fi
		bvalue=$(echo "scale=4; $gvalue-3" | bc)
		if [ "$bvalue" -gt 78 ];then
			bvalue=78
		fi

########SELECT WHICH VIEWER YOU WISH TO USE HERE
		#img2txt.py --ansi --targetAspect=0.5 --maxLen="$bvalue" "$COVERART"
		
		#asciiart -c -w "$bvalue" "$COVERART" 

		killall aview
		anytopnm "$COVERART" | aview -driver curses &	
		snark=$(echo $WINDOWID)
		wmctrl -i -r "$snark" -T "$DataString" 	
	fi
}


# Here's the main loop

	(echo qman-startup; mpc idleloop player) \
	| while read event
	do
		DataString=$(mpc --format "[[%artist% - ]%title%[ - %album%]"| head -1)
		ARTIST=$(mpc --format %artist% | head -1)
		ALBUM=$(mpc --format %album% | head -1)
		SONGFILE=$(mpc --format %file% | head -1)
		SONGFILE=$MUSICDIR/"$SONGFILE"
		SONGDIR=$(dirname "$SONGFILE")
		if [ -f "$SONGFILE" ]; then
			echo "Getting info for $ARTIST and $ALBUM"
			get_album_art
			show_album_art
		else
			echo "We're getting wrong information for some reason."
		fi
	done
fi
clear
