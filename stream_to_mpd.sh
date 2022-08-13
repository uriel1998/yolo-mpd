#!/bin/bash

##############################################################################
#  
#  stream_to_mpd
#  By Steven Saus 
#  (c) 2022; licensed under the MIT license
#
#  Feed an audio stream URL to MPD easily leveraging streamlink and parsing playlists
#
#  Requires streamlink, curl, wget, awk, grep, zenity. 
#
#  Inspired by 
#  https://www.gebbl.net/2013/10/playing-internet-radio-streams-mpdmpc-little-bash-python/
#
##############################################################################


show_help() {
    echo "stream_to_mpd [OPTIONS] STREAM"
    echo "For piping a stream into MPD or an MPD playlist."
    echo " "
    echo "Options are:"
    echo " "
    echo "--host PASSWORD@HOST : You can substitute --host "$MPD_HOST" if set"
    echo "--mpd : skip right to MPD output"
    echo "--playlist : skip right to adding stream URL to a file/playlist"
    echo "--native : Throw the result to streamlink (probably not needed, but hey)"
    echo "--bookmarks : use instead of a stream URL; they are hardcoded in at the moment"
    exit
}

URL=""
InvokedOpts="${@}"


for arg in "$@" 
do
    case "$arg" in 
        "--help" | "-h" )
            show_help
            exit
            ;;
        "--mpd")
            OutPut="MPD"
            shift
            ;;
        "--playlist")
            OutPut="Playlist"
            shift
            ;;        
        "--bookmarks")
            BookMarks="True"
            ;;
        "--host")
            HostString="--host ${2}"
            shift
            shift
            ;;
        "--native")
            OutPut="Local"
            ;;
    esac
done

InvokedOpts="${@}"

if [ -z "${OutPut}" ];then 
    OutPut=$(zenity  --list  --text "Where to send the stream to?" --checklist  --column "Pick" --column "options" TRUE "Local" FALSE "MPD" FALSE "Playlist" --separator=":")
fi

if [ "${BookMarks}" == "True" ];then
    InvokedOpts=$(zenity  --list  --text "Which stream to choose?" --radiolist  --column "Pick" --column "Stream" TRUE https://twitch.tv/biochili FALSE https://twitch.tv/lobsterdust FALSE https://twitch.tv/BootieMashup FALSE https://twitch.tv/VoxSinistra FALSE https://somafm.com/covers.pls FALSE https://somafm.com/metal.pls FALSE http://somafm.com/beatblender.pls FALSE http://somafm.com/groovesalad.pls FALSE http://somafm.com/dronezone.pls FALSE http://somafm.com/spacestation.pls)
fi

# See if streamlink can handle the url...
StreamLink=$(/usr/bin/streamlink --can-handle-url "${InvokedOpts}";echo $?)
if [ "$StreamLink" != "0" ];then
    # not streamlink; ensure content type
    MimeType=$(/usr/bin/curl -k -s --fail -m 2 --location -sS --head "${InvokedOpts}" | grep -i "content-type" | awk -F '/' '{print $2}')
    case "${MimeType}" in 
        *x-mpegurl*|*x-scpls*)  # playlists
            echo "${MimeType}"
            TempFile=$(mktemp)
            EvalString=$(printf "/usr/bin/wget \"%s\" -O %s" "${InvokedOpts}" "${TempFile}")
            eval "${EvalString}"
            # find matches with File[0-9]=(.*) in pls files
            URL=$(/usr/bin/grep -m 1 -e "^File.*" "${TempFile}" | awk -F '=' '{print $2}')
            if [ -z $URL ];then
                # find matches with ^http.*mp3$ in m3u files
                URL=$(/usr/bin/grep -m 1 -e "^http.*mp3??*" "${TempFile}")
                if [ -z $URL ];then
                    # find matches with ^http.*ogg$ in m3u files
                    URL=$(/usr/bin/grep -m 1 -e "^http.*ogg??*" "${TempFile}")
                    if [ -z $URL ];then
                        # find matches with ^http.*aac$ in m3u files
                        URL=$(/usr/bin/grep -m 1 -e "^http.*aac??*" "${TempFile}")
                    fi
                fi
            fi
            rm "${TempFile}"
        ;;
        *ogg*|*mpeg*|*mp4*|*aac*|*opus*|*webm*|*vorbis*)  # direct stream
            URL="${InvokedOpts}"
        ;;
    esac
else
    URL=$(/usr/bin/streamlink "${InvokedOpts}" audio_only --stream-url )
fi
    
if [ -n "${URL}" ];then 
    case "${OutPut}" in 
        *Local*) 
            # Passing to regular streamlink
            /usr/bin/streamlink "${URL}" 
            ;;
        *MPD*) 
            mpc ${HostString} insert "${URL}"            
            mpc ${HostString} mv 2 1            
            mpc ${HostString} play 1
            ;;
        *Playlist*)
            PlaylistPath=$(zenity --title "Name or select the playlist to ADD the stream to" --file-selection --save)
            echo "$URL" >> "${PlaylistPath}"
            ;;       
    esac
else
    echo "No valid URL parsed or direct stream found."
fi


