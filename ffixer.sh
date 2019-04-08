#!/bin/bash

DRYRUN=""

if [ "$1" == "--dryrun" ];then
    DRYRUN="TRUE"
    echo "SONGFILE,NEWTITLE,ALBUMARTIST,ORIGINAL TITLE" > "$HOME/dryrun.csv"
else
    echo "SONGFILE,NEWTITLE,ALBUMARTIST,ORIGINAL TITLE" > "$HOME/changedlog.csv"
fi

startdir="$PWD"

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for file in $(find . -name '*.mp3') 
do
TITLE=""
ARTIST=""
ALBUMARTIST=""
NEWTITLE=""
SONGFILE=""
COMPOSER=""
ADATE=""
ODATE=""
ORDATE=""
SONGFILE="$file"
FILEDATE=""

echo "Checking $SONGFILE"

########################################################################
# getting current modification time so that this doesn't make all your 
# music files "new"
########################################################################
FILEDATE=$(stat "$SONGFILE" | grep "Modify" | awk '{print $2}')

########################################################################
# Getting data from song along with a 
# sed one liner to remove any null bytes that might be in there
########################################################################
DATA=`eyeD3 "$SONGFILE" 2>/dev/null | sed 's/\x0//g' `

########################################################################
# Checking for brackets and vs and such for mashups
# If so, copying mashup data to album artist
########################################################################
TITLE=$(echo -e "$DATA" | grep "title" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')

dobrackets=$([[ "$TITLE" == *[\[\]]* ]] && echo "yes" || echo "no")
if [ "$dobrackets" == "yes" ]; then
    ALBUMARTIST=$(echo "$TITLE" | awk -F"[][]" '{print $2}')
    NEWTITLE=$(echo "$TITLE" | awk -F"[][]" '{print $1}')
    if [[ "$ALBUMARTIST" != *"mix"* ]]; then
        if [[ "$ALBUMARTIST" =~ " vs" ]] || [[ "$ALBUMARTIST" =~ " Vs" ]] || [[ "$ALBUMARTIST" =~ " VS" ]] ; then
            if [ -z "$DRYRUN" ]; then
                eyeD3 "$SONGFILE" --title="$NEWTITLE" 2>/dev/null
                eyeD3 "$SONGFILE" --album-artist="$ALBUMARTIST" 2>/dev/null
                echo "\"$SONGFILE\",\"$NEWTITLE\",\"$ALBUMARTIST\",\"$TITLE\"" >> "$HOME/changedlog.csv"
            else
                echo "\"$SONGFILE\",\"$NEWTITLE\",\"$ALBUMARTIST\",\"$TITLE\"" >> "$HOME/dryrun.csv"
            fi
        fi  
    fi
else
    doparen=$([[ "$TITLE" == *[\(\)]* ]] && echo "yes" || echo "no")
    if [ "$doparen" == "yes" ]; then
        numparen=$(echo "$TITLE" | grep -c -e '(')
        # Not enough testing for multi paren yet
        if [ $numparen -lt 2 ]; then
            ALBUMARTIST=$(echo "$TITLE" | awk -F '[()]' '{print $(NF-1)}')
            NEWTITLE=$(echo "$TITLE" | awk -F '[()]' '{print $1}')
        else
            ALBUMARTIST=$(echo "$TITLE" | awk -F '[()]' '{print $(NF-1)}')
            NEWTITLE=$(echo "$TITLE" | awk -F '[()]' '{print $1}')
        fi
        if [[ "$ALBUMARTIST" != *"mix"* ]]; then
            if [[ "$ALBUMARTIST" =~ " vs" ]] || [[ "$ALBUMARTIST" =~ " Vs" ]] || [[ "$ALBUMARTIST" =~ " VS" ]] ; then
                if [ -z "$DRYRUN" ]; then
                    eyeD3 "$SONGFILE" --title="$NEWTITLE" 
                    eyeD3 "$SONGFILE" --album-artist="$ALBUMARTIST" 
                    echo "\"$SONGFILE\",\"$NEWTITLE\",\"$ALBUMARTIST\",\"$TITLE\"" >> "$HOME/changedlog.csv"
                else
                    echo "\"$SONGFILE\",\"$NEWTITLE\",\"$ALBUMARTIST\",\"$TITLE\"" >> "$HOME/dryrun.csv"
                fi
            fi
        fi
    fi
fi

########################################################################
# Filling in the album artist and composer fields if empty
# If album artist is null and composer is not null, copy composer to 
#    album artist (because that way it's sorting by composer)
# If album artist != artist AND composer is null, copy artist to 
#    composer (because of mashups so it's sorting by DJ)
# If album artist is null and composer is null, copy artist to album 
#    artist (because I really loathe various artist tags)
########################################################################

ARTIST=$(echo -e "$DATA" | grep 'artist' | grep -v "album artist" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')
ALBUMARTIST=$(echo -e "$DATA" | grep "album artist" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')
COMPOSER=$(echo -e "$DATA" | grep "composer" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')
if [ "$ALBUMARTIST" == "" ] && [ "$COMPOSER" != "" ];then
    eyeD3 "$SONGFILE" --album-artist="$COMPOSER" 2>/dev/null
fi

if [ "$ARTIST" != "$ALBUMARTIST" ] && [ "$COMPOSER" == "" ];then
    eyeD3 "$SONGFILE" --composer="$ARTIST" 2>/dev/null
fi

if [ "$COMPOSER" == "" ] && [ "$ALBUMARTIST" == "" ];then
    eyeD3 "$SONGFILE" --album-artist="$ARTIST" 2>/dev/null
fi

########################################################################
# Filling in all date fields (release year, original release date, 
# recording date) if empty
# Changing all dates to just year values
########################################################################

ADATE=$(echo -e "$DATA" | grep "release date" | grep -v "original" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')
RDATE=$(echo -e "$DATA" | grep "original release date" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')
ORDATE=$(echo -e "$DATA" | grep "recording date" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n')


if [ `echo "$ADATE" | grep -c '-' ` -gt 0 ] && [ "$ADATE" != "" ];then
    ADATE=$(echo "$ADATE" | awk -F '-' '{print $1}')
    eyeD3 "$SONGFILE" --release-year="$ADATE" 2>/dev/null
fi

if [ `echo "$RDATE" | grep -c '-' ` -gt 0 ] && [ "$RDATE" != "" ];then
    RDATE=$(echo "$RDATE" | awk -F '-' '{print $1}')
    eyeD3 "$SONGFILE" --orig-release-date="$RDATE" 2>/dev/null
fi
if [ `echo "$ORDATE" | grep -c '-' ` -gt 0 ] && [ "$ORDATE" != "" ];then
    ORDATE=$(echo "$ORDATE" | awk -F '-' '{print $1}' )
    eyeD3 "$SONGFILE" --recording-date="$ORDATE" 2>/dev/null
fi


if [ "$RDATE" != "" ] && [ "$ADATE" == "" ];then
    ADATE=$(echo "$RDATE")
    eyeD3 "$SONGFILE" --release-year="$ADATE" 2>/dev/null
elif [ "$ORDATE" != "" ] && [ "$ADATE" == "" ];then
    ADATE=$(echo "$ORDATE")
    eyeD3 "$SONGFILE" --release-year="$ADATE" 2>/dev/null
fi

if [ "$RDATE" != "" ] && [ "$ORDATE" == "" ];then
    ORDATE=$(echo "$RDATE")
    eyeD3 "$SONGFILE" --recording-date="$ORDATE" 2>/dev/null
elif [ "$ADATE" != "" ] && [ "$ORDATE" == "" ];then
    ORDATE=$(echo "$ADATE")
    eyeD3 "$SONGFILE" --recording-date="$ORDATE" 2>/dev/null
fi


if [ "$ORDATE" != "" ] && [ "$RDATE" == "" ];then
    RDATE=$(echo "$ORDATE")
    eyeD3 "$SONGFILE" --orig-release-date="$RDATE" 2>/dev/null    
elif [ "$ADATE" != "" ] && [ "$RDATE" == "" ];then
    RDATE=$(echo "$ADATE")
    eyeD3 "$SONGFILE" --orig-release-date="$RDATE" 2>/dev/null
fi

########################################################################
# Resetting file modification date
########################################################################
touch -mh --date="$FILEDATE" "$SONGFILE"

echo "$ADATE"
echo "$RDATE"
echo "$ORDATE"

echo "$TITLE"
echo "$ARTIST"
echo "$ALBUMARTIST"
echo "$COMPOSER"
done
