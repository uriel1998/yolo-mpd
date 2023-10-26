#!/bin/bash



TMPDIR=$(mktemp -d)
startdir="$PWD"
dirlist=$(mktemp)

function cleanup {
    # I use trash-cli here instead of rm
    # https://github.com/andreafrancia/trash-cli
    # Obviously, substitute rm -f for trash if you want to use it.
    find "$TMPDIR/" -iname "OTHER*"  -exec trash {} \;
    find "$TMPDIR/" -iname "FRONT_COVER*"  -exec trash {} \;
    find "$TMPDIR/" -iname "cover*"  -exec trash {} \;    
    find "$TMPDIR/" -iname "ICON*"  -exec trash {} \;  
    find "$TMPDIR/" -iname "ILLUSTRATION*"  -exec trash {} \;  
    
}

#https://www.reddit.com/r/bash/comments/8nau9m/remove_leading_and_trailing_spaces_from_a_variable/
trim() {
    local s=$1 LC_CTYPE=C
    s=${s#"${s%%[![:space:]]*}"}
    s=${s%"${s##*[![:space:]]}"}
    printf '%s' "$s"
}


    if [ -f "${CONFIGFILE}" ];then
        echo "[info] Reading configuration"
        while read -r line; do 
            key=$(echo "$line" | awk -F '=' '{print $1}')
            value=$(echo "$line" | cut -d'=' -f 2- )
           case $key in
                musicdir) MUSICDIR="${value}";;
                cachedir) CACHEDIR="${value}";;
                placeholder_img) placeholder_img="${value}";;
                placeholder_dir) placeholder_dir="${value}";;
                display_size) display_size="${value}";;
                XCoord) XCoord="${value}";;
                YCoord) YCoord="${value}";;
                ConkyFile) ConkyFile="${value}";; 
                LastfmAPIKey) LastfmAPIKey="${value}";;
                MPDHost1) MPDHost1="${value}";;
                MPDHost2) MPDHost2="${value}";;
                webcovers) webcovers="${value}";;
                interval) interval="${value}";;
                conkybin) conkybin="${value}";;
                *) ;;
            esac
        done < "${CONFIGFILE}"
        echo "[info] Finished reading configuration."
    fi
        
    if [ -z "$MusicDir" ] || [ ! d "$MusicDir" ]; then MusicDir="$HOME/music"; fi
    if [ -z "$display_size" ];then display_size=256; fi
    if [ -z "$XCoord" ];then XCoord=64; fi
    if [ -z "$YCoord" ];then YCoord=64; fi
    if [ -z "$interval" ];then interval=1; fi    
    if [ -z "$cachedir" ];then cachedir="$HOME/.cache/vindauga" ; fi
    if [ ! -d "$cachedir" ];then mkdir -p "$cachedir"; fi
    if [ -z "$conkybin" ];then conkybin=$(which conky); fi
    if [ -z "$ConkyFile" ];then 
        ConkyFile="$HOME/.conky/vindauga_conkyrc"
        if [ ! -f ${ConkyFile} ];then
            ConkyFile="${SCRIPT_DIR}/vindauga_conkyrc"
        fi
    fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
ENTRIES=$(find -name '*.mp3' -printf '%h\n' | sort -u | grep -c / )
CURRENTENTRY=1
#find -H . -type f \( -name "*.bz2" -or -name "*.gz"  -or -name "*.iso" -or -name "*.tgz" -or -name "*.rar" -or -name "*.zip" \) -exec chmod 666 '{}' ';'
find -name '*.mp3' -printf '%h\n' | sort -u | realpath -p > "$dirlist"
while read line
do
    cleanup
    TITLE=""
    ALBUMARTIST=""
    NEWTITLE=""
    SONGFILE=""
    SONGDIR=""
    BOB=""
    LOOPEND="False"
    #SONGFILE="$file"
    #SongDir=$(dirname "${SONGFILE}")
    dir=$(echo "$line")
    SongDir=$(echo "$dir")
    fullpath=$(realpath "$dir")
    SONGFILE=$(find "$fullpath" -name '*.mp3' | head -1) 
    echo "$CURRENTENTRY of $ENTRIES $dir"
    CURRENTENTRY=$(($CURRENTENTRY+1))

    ####################################################################
    # Do cover files exist? If so, make sure both cover and folder exist.
    ####################################################################
    if [ -f "$fullpath/cover.png" ];then
        convert "$fullpath/cover.png" "$fullpath/cover.jpg"
        rm "$fullpath/cover.png"
    fi
    if [ -f "$fullpath/folder.png" ];then
        convert "$fullpath/folder.png" "$fullpath/folder.jpg"
        rm "$fullpath/folder.png"
    fi

    if [ ! -f "$fullpath/cover.jpg" ] && [ -f "$fullpath/folder.jpg" ];then
        cp "$fullpath/folder.jpg" "$fullpath/cover.jpg"
    fi
    if [ ! -f "$fullpath/folder.jpg" ] && [ -f "$fullpath/cover.jpg" ];then
        cp "$fullpath/cover.jpg" "$fullpath/folder.jpg"

    fi

    #read
    if [ ! -f "$fullpath/cover.jpg" ];then
        echo "Nothing found in directory $fullpath"
        ########################################################################
        # Getting data from song along with a 
        # sed one liner to remove any null bytes that might be in there
        # Also switching to ffmpeg for most of the data; speeds it up a LOT
        ######################################################################## awk '{for(i=2;i<=NF;++i)print $i}'
        songdata=$(ffprobe "$SONGFILE" 2>&1)
        # big long grep string to avoid all the possible frakups I found, lol
        ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
        ALBUM=$(echo "$songdata" | grep "album" | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}' | tr '\n' ' ')
        ARTIST=$(trim "$ARTIST")
        ALBUM=$(trim "$ALBUM")

        CoverExist=$(echo "$songdata" | grep -c "front")
        if [ $CoverExist -gt 0 ];then
            DATA=`eyeD3 "$SONGFILE" 2>/dev/null | sed 's/\x0//g' `
            COVER=$(echo "$DATA" |  grep "FRONT_COVER" )
        fi

        ####################################################################
        # Does the MP3 have a cover file?
        ####################################################################
        
        ####################################################################    
        # Albumart file, nothing in MP3
        # This adds the found album art INTO the mp3
        ####################################################################
        #if [[ ! -z "$FILTER" ]] && [[ -z "$COVER" ]];then
         #   echo "### Cover art retrieved from music directory!"
         #   echo "### Cover art being copied to MP3 ID3 tags!"
         #   if [ -f "$SongDir/cover.jpg" ]; then
         #       if [ ! -f "$SongDir/folder.jpg" ]; then
         #           convert "$SongDir/cover.jpg" "$SongDir/folder.jpg"
         #       fi
         #   else
         #       if [ -f "$SongDir/folder.jpg" ]; then
         #           convert "$SongDir/folder.jpg" "$SongDir/cover.jpg"
         #       fi
         #   fi
         #   echo "$fullpath/cover.jpg"
        #    eyeD3 --add-image="$SongDir/cover.jpg":FRONT_COVER "$SONGFILE" 2>/dev/null
        #fi

        ####################################################################
        # MP3 cover, no file
        ####################################################################    
        
        eyeD3 --write-images="$TMPDIR" "$SONGFILE" 1> /dev/null
        if [ -f "$TMPDIR/FRONT_COVER.png" ]; then
            echo "### Converting PNG into JPG"
            convert "$TMPDIR/FRONT_COVER.png" "$TMPDIR/FRONT_COVER.jpeg"
        fi
        # Catching when it's sometimes stored as "Other" tag instead of FRONT_COVER
        # but only when FRONT_COVER doesn't exist.
        if [ ! -f "$TMPDIR/FRONT_COVER.jpeg" ]; then
            if [ -f "$TMPDIR/OTHER.png" ]; then
                echo "converting PNG into JPG"
                convert "$TMPDIR/OTHER.png" "$TMPDIR/OTHER.jpeg"
            fi
            if [ -f "$TMPDIR/OTHER.jpg" ]; then
                cp "$TMPDIR/OTHER.jpg" "$TMPDIR/OTHER.jpeg"
            fi
            if [ -f "$TMPDIR/OTHER.jpeg" ]; then
                cp "$TMPDIR/OTHER.jpeg" "$TMPDIR/FRONT_COVER.jpeg"
            fi
            if [ -f "$TMPDIR/FRONT_COVER.jpg" ]; then
                cp "$TMPDIR/FRONT_COVER.jpg" "$TMPDIR/FRONT_COVER.jpeg"
            fi            
        fi  
        if [ -f "$TMPDIR/FRONT_COVER.jpeg" ]; then
            echo "### Cover art retrieved from MP3 ID3 tags!"
            echo "### Cover art being copied to music directory!"
            echo "$fullpath/cover.jpg"
            cp "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/cover.jpg"
            cp "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/folder.jpg"
                
        fi
        
        ####################################################################
        # No albumart file, nothing in MP3
        ####################################################################    

        ##########################################################################
        # Attempt to get coverart from CoverArt Archive or Deezer
        ##########################################################################
        MBID=""
        IMG_URL=""
        API_URL=""   
        
        if [ ! -f "$fullpath/folder.jpg" ];then
            MBID=$(ffmpeg -i "$SongFile" 2>&1 | grep "MusicBrainz Album Id:" | awk -F ': ' '{print $2}')
            if [ "$MBID" = '' ] || [ "$MBID" = 'null' ];then
                API_URL="http://coverartarchive.org/release/$MBID/front"
                IMG_URL=$(curl "$API_URL" | awk -F ': ' '{print $2}')
            fi
            
            if [ "$IMG_URL" = '' ] || [ "$IMG_URL" = 'null' ];then
                echo "Not on CoverArt Archive or Deezer"
            else
                # I don't know why curl hates me here.
                #curl -o "$tempcover" "$IMG_URL"
                wget -q "$IMG_URL" -O "$TMPDIR/FRONT_COVER.jpeg"
                if [ -f "$TMPDIR/FRONT_COVER.jpeg" ];then
                    convert "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/cover.jpg"
                    convert "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/folder.jpg"
                fi
            fi
        fi

        if [ ! -f "$fullpath/cover.jpg" ];then
            glyrc cover --timeout 15 --artist "$ARTIST" --album "$ALBUM" --write "$TMPDIR/cover.tmp" --from "musicbrainz;discogs;coverartarchive;rhapsody;lastfm"
            convert "$TMPDIR/cover.tmp" "$TMPDIR/cover.jpg"
        fi
        
        ##########################################################################
        # Attempt to find cover art via sacad if it's in $PATH
        # (no cache cover, no local art in directory
        ##########################################################################
        if [ ! -f "$fullpath/folder.jpg" ];then
            sacad_bin=$(which sacad)
            if [ -f "${sacad_bin}" ];then 
                "${sacad_bin}" -d "${Artist}" "${Album}" 512 "$TMPDIR/FRONT_COVER.jpeg"
                if [ -f "$TMPDIR/FRONT_COVER.jpeg" ];then
                    convert "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/cover.jpg"
                    convert "$TMPDIR/FRONT_COVER.jpeg" "$fullpath/folder.jpg"
                fi
            fi
        fi
        #tempted to be a hard stop here, because sometimes these covers are just wrong.
        if [ -f "$TMPDIR/cover.jpg" ]; then
            cp "$TMPDIR/cover.jpg" "$fullpath/cover.jpg"
            cp "$TMPDIR/cover.jpg" "$fullpath/folder.jpg"
            echo "Cover art found online; you may wish to check it before embedding it."
            
        else
            echo "No cover art found online or elsewhere."
        fi        
    fi
    
    ##########################################################################
    # Copy to vindauga cache, if exists And get artist image
    ##########################################################################

    if [ -d "$cachedir" ];then
        if [ -f "$fullpath/cover.jpg" ];then
            SONGFILE=$(find "$fullpath" -name '*.mp3' | head -1) 
            songdata=$(ffprobe "$SONGFILE" 2>&1)
            ARTIST=$(echo "$songdata" | grep "artist" | grep -v "mp3," | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}')
            ALBUM=$(echo "$songdata" | grep "album" | head -1 | awk -F ': ' '{for(i=2;i<=NF;++i)print $i}' | tr '\n' ' ')
            ARTIST=$(trim "$ARTIST")
            ALBUM=$(trim "$ALBUM")
            EscapedArtist=$(echo "$ARTIST" | sed -e 's/[/()&]//g')
            EscapedAlbum=$(echo "$ALBUM" | sed -e 's/[/()&]//g')
            cachecover=$(printf "%s/%s-%s-album.jpg" "$cachedir" "$EscapedArtist" "$EscapedAlbum")
            cacheartist=$(printf "%s/%s-artist.jpg" "$cachedir" "$EscapedArtist")
            
            #Adding in glyrc search for artist image...
            if [ ! -f "$cacheartist" ];then
                glyrc artistphoto --timeout 15 --artist "$ARTIST" --album "$ALBUM" --write "$TMPDIR/artist.tmp" --from "discogs;lastfm;bbcmusic;rhapsody;singerpictures"
                if [ -f "$TMPDIR/artist.tmp" ];then
                    convert "$TMPDIR/artist.tmp" "$cacheartist"
                    rm "$TMPDIR/artist.jpg"
                fi
            fi            


            if [ ! -f "$cacheartist" ];then
                echo "Trying deezer..."
                API_URL="https://api.deezer.com/search/artist?q=$EscapedArtist" && API_URL=${API_URL//' '/'%20'}
                IMG_URL=$(curl -s "$API_URL" | jq -r '.data[0] | .picture_big ')
                #deezer outputs a wonky url if there's no image match, this checks for it.
                # https://e-cdns-images.dzcdn.net/images/artist//500x500-000000-80-0-0.jpg
                check=$(awk 'BEGIN{print gsub(ARGV[2],"",ARGV[1])}' "$IMG_URL" "//")
                
                if [ "$check" != "1" ]; then
                    IMG_URL=""
                fi

                
                if [ ! -z "$LastfmAPIKey" ] && [ -z "$IMG_URL" ];then  # deezer first, then lastfm
                    echo "Trying lastfm..."
                    METHOD=artist.getinfo
                    API_URL="https://ws.audioscrobbler.com/2.0/?method=$METHOD&artist=$EscapedArtist&api_key=$LastfmAPIKey&format=json" && API_URL=${API_URL//' '/'%20'}
                    IMG_URL=$(curl -s "$API_URL" | jq -r ' .artist | .image ' | grep -B1 -w "extralarge" | grep -v "extralarge" | awk -F '"' '{print $4}')            
                fi  
                
                if [ ! -z "$IMG_URL" ];then         
                    tempartist=$(mktemp)
                    wget -q "$IMG_URL" -O "$tempartist"
                    bob=$(file "$tempartist" | head -1)  #It really is an image
                    sizecheck=$(wc -c "$tempartist" | awk '{print $1}')
                    # This test is because I *HATE* last.fm's default artist image
                    if [[ "$bob" == *"image data"* ]];then
                        if [ "$sizecheck" != "4195" ];then
                            convert "$tempartist" "$cacheartist"
                            rm "$tempartist"
                        fi
                    fi
                fi
            fi
            
            
             
            if [ ! -f "$cachecover" ];then
                ln -s "$fullpath/cover.jpg" "$cachecover"
            fi
            ARTIST=""
            if [ -f "$TMPDIR/artist.tmp" ];then
                rm "$TMPDIR/artist.tmp"
            fi
            if [ -f "$tempartist" ];then
                rm "$tempartist"
            fi
        fi
    fi  
done < "$dirlist"
IFS=$SAVEIFS
