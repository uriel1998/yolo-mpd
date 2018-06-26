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
ALBUMARTIST=""
NEWTITLE=""
SONGFILE=""

SONGFILE="$file"

printf "." 

TITLE=`eyeD3 "$SONGFILE" 2>/dev/null | grep "title" | grep -v "UserTextFrame" | awk -F ': ' '{print $2}' | tr -d '\n'`

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
done
