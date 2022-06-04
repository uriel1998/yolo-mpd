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

ActivePlayers=$(qdbus | grep org.mpris.MediaPlayer2 | awk '{print $1}')

# Only triggered if a player is specified, then checks to make sure it's up.
if [ $# = 2 ]; then
    case "$2" in
        [Pp]*)
            if [[ "$ActivePlayers" != *"pithos"* ]]; then
                echo "Pithos is not playing."
                exit
            else
                ActivePlayers="org.mpris.MediaPlayer2.pithos"
            fi          
            ;;
        [Aa]*)
            if [[ "$ActivePlayers" != *"audacious"* ]]; then
                echo "Audacious is not playing."
                exit
            else
                ActivePlayers="org.mpris.MediaPlayer2.audacious"
            fi          
            ;;
        [Mm]*)
            if [[ "$ActivePlayers" != *"mpd"* ]]; then
                echo "MPD is not playing."
                exit
            else
                ActivePlayers="org.mpris.MediaPlayer2.mpd"
            fi          
            ;;
        [Cc]*)
            if [[ "$ActivePlayers" != *"clementine"* ]]; then
                echo "Clementine is not playing."
                exit
            else
                ActivePlayers="org.mpris.MediaPlayer2.clementine"
            fi          
            ;;
    esac
fi


case "$1" in
        # Play/pause
        [Pp]*)
            while IFS= read -r player; do
                if [ "$player" == *"mpd"* ];then
                    # creating play/pause functionality
                    mpdcheck=$(mpc --host 4TmUAFS4TQsC@localhost | tail -2 | head -1 | awk '{print $1}')
                    if [ "${mpdcheck}" == "[playing]" ];then
                        qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                    else
                        qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
                    fi                
                else
                    if [[ "$player" =~ "pithos" ]];then
                        qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
                    else
                        qdbus "${player}" org.mpris.MediaPlayer2.Player.Play
                    fi
                fi
            done <<< "${ActivePlayers}"        
            ;;
        [Nn]*)
            while IFS= read -r player; do
                qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
            done <<< "${ActivePlayers}"        
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
            case ${DSTRING} in
                audacious) qdbus org.mpris.MediaPlayer2.audacious /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause ;;
                clementine) qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause;;
                pithos) qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause;;
                mpd)                 # creating play/pause functionality for MPD
                    mpdcheck=$(mpc --host 4TmUAFS4TQsC@localhost | tail -2 | head -1 | awk '{print $1}')                
                    if [ "${mpdcheck}" == "[playing]" ];then
                        qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                    else
                        qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
                    fi                
                    ;;
                *) qdbus $DSTRING /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause ;;
            esac
        ;;
esac
