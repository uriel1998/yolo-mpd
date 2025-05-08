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
    SONGSTRING=$(mpc --host "$MPD_HOST" current --format "%artist% : “%title%” from *%album%*")
    if [ "${SONGSTRING}" != "${SONGSTRING_PRIOR}" ];then
        loud "Posting to maubot"
#        Build the JSON safely with jq
        json_payload=$(jq -n \
          --arg title "${SONGSTRING}" \
          '{
            title: $title
          }')

        # Then send it with curl
        curl -X POST -H "Content-Type: application/json" -u abc:123 "${MATRIXSERVER}/_matrix/maubot/plugin/${MAUBOT_WEBHOOK_INSTANCE}/send" -d "$json_payload"
    fi
    loud "Posted to maubot, waiting"    
    mpc --host "$MPD_HOST" idle player
    
done
 
