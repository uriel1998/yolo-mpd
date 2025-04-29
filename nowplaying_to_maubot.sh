#!/bin/bash

# get song title, etc, as well as filename.
# get (relative) url for cover
# test for existence of cover, replace with default if none (URL wise, that is)
# emit 

LOUD=1
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/maubot_vars.env"


function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


while true
do
    SONGSTRING_PRIOR="${SONGSTRING}"
    SONGSTRING=$(mpc current --format "%artist% : %title% (%album%) ")
    if [ "${SONGSTRING}" != "${SONGSTRING_PRIOR}" ];then
        SONGFILE=$(mpc current --format %file%)
        SONGFILE=$(dirname "${SONGFILE}")
        SONGFILE=$(urlencode "${SONGFILE}")
        COVERSTRING="${COVERSERVER}/covers/${SONGFILE}/cover.jpg"
        imagecheck=$(wget -q --spider "${COVERSTRING}"; echo $?)
        if [ "${imagecheck}" -ne 0 ];then
            loud "[warn] Stored image no longer available."
            COVERSTRING=""
        fi
        FULLIMAGE=$(printf "![cover](%s)  " "${COVERSTRING}")
        echo "${FULLIMAGE}"
        loud "Posting to maubot"
        # Build the JSON safely with jq
        json_payload=$(jq -n \
          --arg title "${SONGSTRING}" \
          --arg image "${FULLIMAGE}" \
          '{
            title: $title,
            image: $image
          }')

        # Then send it with curl
        curl -X POST -H "Content-Type: application/json" -u abc:123 "${MATRIXSERVER}/_matrix/maubot/plugin/${MAUBOT_WEBHOOK_INSTANCE}/send" -d "$json_payload"
    fi
    mpc idle player
    
done

 
# Okay, so this works, sorta, except HTML switches to notify, so I can't see the image. :/  

# 
# this might work so I don't have to parse it separately outside of the thing???
################################################################################
# path: /send
# method: POST
# room: '!AAAAAAAAAAAAAAAAAA:example.com'
# message: |
#    <h4>{{ json.title }}</h4>
#    {% for text in json.image %}
#    <img src="{{ text }}" />
#    {% endfor %}
# message_format: html
# message_type: m.notice
# auth_type: Basic
# auth_token: abc:123
# force_json: false
# ignore_empty_messages: true


################################################################################
#$ curl -X POST -H "Content-Type: application/json" -u abc:123 https://your.maubot.instance/_matrix/maubot/plugin/<instance ID>/send -d '
#{
#    "title": "${SONGSTRING}",
#    "image": [ "${COVERSTRING}" ]
#}'
