#!/bin/bash




export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/maubot_vars.env"

echo $$ > "${SCRIPT_DIR}/nowplaying.pid"

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function round_rectangles (){


  convert "${1}" \
      -format 'roundrectangle 1,1 %[fx:w+4],%[fx:h+4] 15,15' \
      -write info:tmp.mvg \
      -alpha set -bordercolor none -border 3 \
      \( +clone -alpha transparent -background none \
         -fill white -stroke none -strokewidth 0 -draw @tmp.mvg \) \
      -compose DstIn -composite \
      \( +clone -alpha transparent -background none \
         -fill none -stroke black -strokewidth 3 -draw @tmp.mvg \
         -fill none -stroke white -strokewidth 1 -draw @tmp.mvg \) \
      -compose Over -composite               "${2}"
      if [ -f "${PWD}/tmp.mvg" ];then
        rm "${PWD}/tmp.mvg"
      fi
}

urlencode() {
  local string="$1"
  local encoded=""
  local i c

  for (( i = 0; i < ${#string}; i++ )); do
    c="${string:$i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      *) printf -v encoded '%s%%%02X' "$encoded" "'$c" ;;
    esac
  done

  echo "$encoded"
}


get_cover_url() {
  local media_path="${1}"
  local base_url="${COVERSERVER}"
  local dir_path
  dir_path=$(dirname "$media_path")

  local encoded_path=""
  IFS='/' read -ra parts <<< "$dir_path"
  for part in "${parts[@]}"; do
    encoded_part=$(urlencode "$part")
    encoded_path+="$encoded_part/"
  done
  encoded_path=${encoded_path%/}  # Remove trailing slash
    
  echo "$base_url/$encoded_path/cover.jpg"
}
 

function get_artist_url (){
    ARTIST_NAME="${1}"
    ENCODED_NAME=$(echo "$ARTIST_NAME" | jq -sRr @uri)
    # Query Deezer API
    RESPONSE=$(curl -s "https://api.deezer.com/search/artist?q=$ENCODED_NAME")
    # Extract the first image URL
    IMAGE_URL=$(echo "$RESPONSE" | jq -r '.data[0].picture_big')
    echo "${IMAGE_URL}"
}

function combine_images (){

    ARTIST="${1}"   # artist
    ALBUM="${2}"   # album 
    TEMPDIR=$(mktemp -d)
    IMG_A="${TEMPDIR}/artist.jpg"   # artist
    IMG_B="${TEMPDIR}/album.jpg"   # album
    IMG_C="${SCRIPT_DIR}/backdrop.jpg"   # background    
    IMG_D="${SCRIPT_DIR}/now_playing.jpg"   # output
    URL_ARTIST=$(get_artist_url "${ARTIST}")
    URL_ALBUM=$(get_cover_url "${ALBUM}")

    wget -q "${URL_ARTIST}" -O "${IMG_A}"
    if [ "$?" != "0" ];then
        loud "[warn] Artist image not found, using default."
        cp "${SCRIPT_DIR}/default_artist.jpg" "${IMG_A}"
    fi
    wget -q "${URL_ALBUM}" -O "${IMG_B}"
    if [ "$?" != "0" ];then
        loud "[warn] Cover not found, using default cover."
        cp "${SCRIPT_DIR}/default_album.jpg" "${IMG_B}"
    fi    
    #echo "${IMG_A}"
    #echo "${IMG_B}"

    convert "$IMG_A" -resize 600x600^ -gravity center -extent 600x600 "${TEMPDIR}/A_base.png"
    convert "$IMG_B" -resize 600x600^ -gravity center -extent 600x600 "${TEMPDIR}/B_base.png"

    round_rectangles "${TEMPDIR}/A_base.png" "${TEMPDIR}/A_final.png"
    round_rectangles "${TEMPDIR}/B_base.png" "${TEMPDIR}/B_final.png"
    # Step 4: Resize C to 1366x768 exactly
    convert "$IMG_C" -resize 1366x768\! "${TEMPDIR}/C_resized.png"
    # Step 5: Compute placement offsets
    read A_WIDTH A_HEIGHT < <(identify -format "%w %h" "${TEMPDIR}/A_final.png")
    read B_WIDTH B_HEIGHT < <(identify -format "%w %h" "${TEMPDIR}/B_final.png")

    A_X=41
    B_X=$((1366 - 41 - B_WIDTH))
    A_Y=$(( (768 - A_HEIGHT) / 2 ))
    B_Y=$(( (768 - B_HEIGHT) / 2 ))

    # Step 6: Composite everything
    composite -geometry +0+0 "${TEMPDIR}/C_resized.png" -size 1366x768 xc:none "${TEMPDIR}/D_temp.png"
    composite -geometry +$A_X+$A_Y "${TEMPDIR}/A_final.png" "${TEMPDIR}/D_temp.png" "${TEMPDIR}/D_temp2.png"
    composite -geometry +$B_X+$B_Y "${TEMPDIR}/B_final.png" "${TEMPDIR}/D_temp2.png" "$IMG_D"

    rm -rf "${TEMPDIR}"
    
}


while [ -f "${SCRIPT_DIR}/nowplaying.pid" ];do
    SONGSTRING_PRIOR="${SONGSTRING}"
    SONGSTRING=$(mpc --host "$MPD_HOST" current --format "%artist% : “%title%” from *%album%*")
    if [ "${SONGSTRING}" != "${SONGSTRING_PRIOR}" ];then
        loud "[info] Getting artist, cover images."
        ALBUMFILE=$(mpc --host "$MPD_HOST" current --format "%file%")
        ARTIST=$(mpc --host "$MPD_HOST" current --format "%albumartist%")
        combine_images "${ARTIST}" "${ALBUMFILE}"
        env DISPLAY=:0.0 feh --bg-fill --no-xinerama "${SCRIPT_DIR}/now_playing.jpg" 2>/dev/null
        
        loud "[info] Posting ${SONGSTRING} to maubot"
#        Build the JSON safely with jq
        json_payload=$(jq -n \
          --arg title "${SONGSTRING}" \
          '{
            title: $title
          }')

        # Then send it with curl
        curl -X POST -H "Content-Type: application/json" -u abc:123 "${MATRIXSERVER}/_matrix/maubot/plugin/${MAUBOT_WEBHOOK_INSTANCE}/send" -d "$json_payload"
    fi
    loud "[info] Posted to maubot, waiting"    
    # need a timeout script here maybe?
    mpc --host "$MPD_HOST" idle player
    
done
 
