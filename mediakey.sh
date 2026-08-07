#!/usr/bin/env bash

## -- This script will imitate Gnome's Media Controls (Play/Pause, Next, Previous, Stop) -- ##
## -- It will assume you are using a media application that is compatible with MPRIS or  -- ##
## -- "Media Player Remote Interfacing Specification"                                    -- ##

#  TODO: import code from yadshow to more flexibly cascade media players


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

select_player() {
    case "$1" in
        [Pp]*) echo "org.mpris.MediaPlayer2.pithos" ;;
        [Aa]*) echo "org.mpris.MediaPlayer2.audacious" ;;
        [Mm]*) echo "org.mpris.MediaPlayer2.mpd" ;;
        [Cc]*) echo "org.mpris.MediaPlayer2.clementine" ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

for_each_active_player() {
    local player=""

    while IFS= read -r player; do
        [[ -n "${player}" ]] || continue
        "$@" "${player}"
    done <<< "${ActivePlayers}"
}

# Only triggered if a player is specified, then checks to make sure it's up.
if [ $# = 2 ]; then
    selected_player=$(select_player "$2") || {
        echo "Unknown player: $2"
        exit 1
    }
    if [[ "${ActivePlayers}" != *"${selected_player}"* ]]; then
        echo "${selected_player##*.} is not playing."
        exit
    fi
    ActivePlayers="${selected_player}"
fi

[[ -n "${ActivePlayers}" ]] || exit 0

handle_play_toggle() {
    local player="$1"

    if [[ "$player" == *"mpd" ]];then
        mpdcheck=$(mpc | tail -2 | head -1 | awk '{print $1}')
        if [[ "${mpdcheck}" == "[playing]" ]];then
            qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
        else
            qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
        fi
    else
        qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    fi
}

handle_next() {
    qdbus "$1" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
}

handle_previous() {
    qdbus "$1" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
}

handle_stop() {
    local player="$1"

    if [[ "$player" == *"pithos" ]];then
        qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    else
        qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
    fi
}

handle_pause() {
    local player="$1"

    if [[ "$player" == *"mpd" ]];then
        mpdcheck=$(mpc | tail -2 | head -1 | awk '{print $1}')
        if [[ "${mpdcheck}" == "[playing]" ]];then
            qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
        else
            qdbus org.mpris.MediaPlayer2.mpd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
        fi
    elif [[ "$player" == *"pithos" ]];then
        qdbus org.mpris.MediaPlayer2.pithos /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    else
        qdbus "${player}" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
    fi
}

case "$1" in
    # Play/pause
    [Pp]*)
        for_each_active_player handle_play_toggle
        ;;
    [Nn]*)
        for_each_active_player handle_next
        ;;
    [Bb]*)
        for_each_active_player handle_previous
        ;;        
    [Ss]*)
        for_each_active_player handle_stop
        ;;
    [Zz]*) 
        for_each_active_player handle_pause
        ;;
esac
