#!/bin/bash

## -- This script will imitate Gnome's Media Controls (Play/Pause, Next, Previous, Stop) -- ##
## -- It will assume you are using a media application that is compatible with MPRIS or  -- ##
## -- "Media Player Remote Interfacing Specification"                                    -- ##

if [ $# = 0 ]; then
	echo "This script is designed to use the MPRIS interface to interact with music players."
	echo "Usage is"
	echo "mediakey.sh [p|n|b|s|z] [PLAYER]"
	echo " "
	echo "Action may be:"
	echo "p = play, n = next, b = previous, s = stop, z = pause"
	echo " "
	echo "PLAYER is optional (otherwise it triggers ALL supported players)"
	echo "p = Pithos"
	echo "a = Audacious"
	echo "m = MPD"
	echo "c = Clementine"
	echo " "
	exit
fi

if [ $# = 2 ]; then
	case "$2" in
		[Pp]*)
			if [ `qdbus | grep org.mpris.MediaPlayer2.pithos -c` == "0" ]; then
				echo "Pithos is not playing."
				exit
			else
				DSTRING="org.mpris.MediaPlayer2.pithos"
			fi			
		;;
		[Aa]*)
			if [ `qdbus | grep org.mpris.MediaPlayer2.audacious -c` == "0" ]; then
				echo "Audacious is not playing."
				exit
			else
				DSTRING="org.mpris.MediaPlayer2.audacious"
			fi			

		;;
		[Mm]*)
			if [ `qdbus | grep org.mpris.MediaPlayer2.mpd -c` == "0" ]; then
				echo "MPD is not playing."
				exit
			else
				DSTRING="org.mpris.MediaPlayer2.mpd"
			fi			

		;;
		[Cc]*)
			if [ `qdbus | grep org.mpris.MediaPlayer2.clementine -c` == "0" ]; then
				echo "Clementine is not playing."
				exit
			else
				DSTRING="org.mpris.MediaPlayer2.clementine"
			fi			
		;;
	esac
else
	DSTRING="ALL"
fi




case "$1" in
		[Pp]*)
			if [ "$DSTRING" == "ALL" ]; then
				qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
				qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
				qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
				qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
			else
				if [[ "$DSTRING" =~ "pithos" ]];then
					qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
				else
					qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
				fi
			fi
		;;
		[Nn]*)
			if [ "$DSTRING" = "ALL" ]; then
				qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
				qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
				qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
				qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
			else
				qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
			fi
		;;
		[Bb]*)
			if [ "$DSTRING" = "ALL" ]; then
				qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
				qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
				qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
				qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous						
			else
				qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
			fi
		;;
		[Ss]*)
			if [ "$DSTRING" = "ALL" ]; then
				qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
				qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
				qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
				qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
			else
				if [[ "$DSTRING" =~ "pithos" ]];then
					qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
				else
					qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
				fi
			fi

		;;
		[Zz]*) 
			if [ "$DSTRING" = "ALL" ]; then
				qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
				qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
				qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
				qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
			else
				if [[ "$DSTRING" =~ "pithos" ]];then
					qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
				else
					qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
				fi
			fi
		;;
esac
