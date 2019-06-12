#!/bin/bash

TMPDIR=$(mktemp -d)
#TMPDIR="/home/steven/tmp/ffixer_tmp"
startdir="$PWD"

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

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
ENTRIES=$(find -name '*.mp3' -printf '%h\n' | sort -u | grep -c / )
CURRENTENTRY=1
for dir in $(find -name '*.mp3' -printf '%h\n' | sort -u)
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
    
    SongDir=$(echo "$dir")
    fullpath=$(realpath "$dir")
    SONGFILE=$(find "$fullpath" -name '*.mp3' | head -1) 
    echo "$CURRENTENTRY of $ENTRIES $dir"
    CURRENTENTRY=$(($CURRENTENTRY+1))

    ####################################################################
    # Do cover files exist? If so, make sure both cover and folder exist.
    ####################################################################

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
        ########################################################################
        DATA=`eyeD3 "$SONGFILE" 2>/dev/null | sed 's/\x0//g' `
        COVER=$(echo "$DATA" |  grep "FRONT_COVER" )
        ARTIST=$(echo "$DATA" | grep "artist" | grep -v "album" | awk -F ': ' '{print $2}' | sed -e 's/[[:space:]]*$//' | tr -d '\n')
        ALBUM=$(echo "$DATA" | grep "album" | grep -v "artist" | grep -v "Frame"  | awk -F ': ' '{print $2}' | awk 'BEGIN {FS="\t"}; {print $1}' | sed -e 's/[[:space:]]*$//' | tr -d '\n')

        ####################################################################
        # Does the MP3 have a cover file?
        ####################################################################
        
        ####################################################################    
        # Albumart file, nothing in MP3
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
        if [ ! -f "$fullpath/cover.jpg" ];then
            glyrc cover --artist "$ARTIST" --album "$ALBUM" --formats jpeg --write "$TMPDIR/cover.jpg" --from "musicbrainz;discogs;coverartarchive"

            #tempted to be a hard stop here, because sometimes these covers are just wrong.
            if [ -f "$TMPDIR/cover.jpg" ]; then
                cp "$TMPDIR/cover.jpg" "$fullpath/cover.jpg"
                cp "$TMPDIR/cover.jpg" "$fullpath/folder.jpg"
                echo "Cover art found online; you may wish to check it before embedding it."
                
            else
                echo "No cover art found online or elsewhere."
            fi        
        fi
    fi

done
IFS=$SAVEIFS
