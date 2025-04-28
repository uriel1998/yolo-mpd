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


SONGSTRING=$(mpc current --format "%artist% - %album% - %title%")
SONGFILE=$(mpc current --format %file%)
SONGFILE=$(dirname "${SONGFILE}")
echo "${SONGFILE}"

COVERSTRING="${COVERSERVER}/covers/${SONGFILE}/cover.jpg"                   
loud "${SONGSTRING}"
loud "${COVERSTRING}"
imagecheck=$(wget -q --spider "${COVERSTRING}"; echo $?)
if [ "${imagecheck}" -ne 0 ];then
    loud "[warn] Stored image no longer available."
    COVERSTRING=""
fi
loud "Posting to maubot"
loud "${MATRIXSERVER},${MAUBOT_WEBHOOK_INSTANCE},${SONGSTRING},${COVERSTRING}"


curl -X POST -H "Content-Type: application/json" -u abc:123 ${MATRIXSERVER}/_matrix/maubot/plugin/${MAUBOT_WEBHOOK_INSTANCE}/send -d '
{
    "title": "${SONGSTRING}",
    "image": [ "${COVERSTRING}" ]
}'



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
