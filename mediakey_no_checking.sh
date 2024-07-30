#!/bin/bash

## -- This script will imitate Gnome's Media Controls (Play/Pause, Next, Previous, Stop) -- ##
## -- It will assume you are using a media application that is compatible with MPRIS or  -- ##
## -- "Media Player Remote Interfacing Specification"                                    -- ##

# basically stripped out everything checking if a player was up, specialization 
# only for ones that have non-standard controls

if [ $# = 0 ]; then
    echo "This script is designed to use the MPRIS interface to interact with music players."
    echo "Usage is"
    echo "mediakey.sh [p|n|b|s|z] [PLAYER]"
    echo " "
    echo "Action may be:"
    echo "p = play, n = next, b = previous, s = stop, z = pause"
    echo " "
    exit
fi

ActivePlayers=$(qdbus | grep org.mpris.MediaPlayer2 | awk '{print $1}')

case "$1" in
    # Play/pause
    [Pp]*)
        while IFS= read -r player; do
            if [[ "$player" =~ "mpd" ]];then
                # creating play/pause functionality
                mpdcheck=$(mpc | tail -2 | head -1 | awk '{print $1}')
                if [[ "${mpdcheck}" =~ "[playing]" ]];then
                    qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                else
                    qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
                fi                
            else
                if [[ "$player" =~ "pithos" ]];then
                    qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
                else
                    Player_Status=$(qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus 2>/dev/null)
                    if [ "${Player_Status}" == "Playing" ];then
                        qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                    else
                        qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
                    fi
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
        while IFS= read -r player; do
            qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
        done <<< "${ActivePlayers}"        
        ;;        
    [Ss]*)
        while IFS= read -r player; do
            if [[ "$player" =~ "pithos" ]];then
                qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
            else
                qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
            fi
        done <<< "${ActivePlayers}"        
        ;;
    [Zz]*) 
        while IFS= read -r player; do
            if [[ "$player" =~ "mpd" ]];then
                # creating play/pause functionality
                mpdcheck=$(mpc | tail -2 | head -1 | awk '{print $1}')
                if [ "${mpdcheck}" == "[playing]" ];then
                    qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                else
                    qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
                fi                
            else
                if [[ "$player" =~ "pithos" ]];then
                    qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
                else
                    qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
                fi
            fi
        done <<< "${ActivePlayers}"        
        ;;
esac
