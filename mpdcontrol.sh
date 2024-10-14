#!/bin/bash

################################################################################
#  A simple utility to allow playlist selection and playing from cli for MPD
#
#  by Steven Saus
#
#  Licensed under a Creative Commons BY-SA 3.0 Unported license
#  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/.
#
################################################################################
ADDMODE="1"    
    
    if [ -z "$MPD_HOST" ];then
        MPD_HOST=localhost
    fi
    
    if [ "$1" == "-c" ];then
        ADDMODE="0"
    fi

clearmode (){
    
        if [ "$ADDMODE" = "0" ];then
            mpc --host "$MPD_HOST" clear -q
        fi
}
    
    echo -e "\E[0;32m(\E[0;37mc\E[0;32m)ustom, \E[0;32m(\E[0;37mg\E[0;32m)enre, (\E[0;37mA\E[0;32m)lbumartist, (\E[0;37ma\E[0;32m)rtist, a(\E[0;37ml\E[0;32m)bum, (\E[0;37ms\E[0;32m)ong, (\E[0;37mp\E[0;32m)laylist, or (\E[0;37mq\E[0;32m)uit? "; tput sgr0
    read -r CHOICE

    
    case "$CHOICE" in
        "c") 
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list genre | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list genre | pick)
            fi
            
            selection=""
            while IFS= read -r genre; do
                bob=$(mpc --host "$MPD_HOST" -f "%title% ‡ %artist%" search genre "$genre")
                selection=$(echo "$selection $bob")
            done <<< "$result"        
        ### TODO
        ### THIS IS IT - WE CAN ACTUALLY PUT IN A SHORTCUT MATCH FOR OTHER FIELDS HERE TOO!
        ### EG g:${genre} so if you want to limit what you're seeing, you can type g:Rock
        ### I THINK if FZF does each term separately
        
            if [ -f "$(which fzf)" ];then 
                result=$(echo "$selection" | fzf --multi | awk -F ' ‡' '{print $1}')
            else
                result=$(echo "$selection" | pick | awk -F ' ‡' '{print $1}')
            fi            
            clearmode
            while IFS= read -r title; do
                mpc --host "$MPD_HOST" findadd title "${title}" 
            done <<< "$result"
            mpc --host "$MPD_HOST" play
        ;;


        "s") 
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list title | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list title | pick)
            fi            
            clearmode
            while IFS= read -r title; do
                mpc --host "$MPD_HOST" findadd title "${title}" 
            done <<< "$result"
            mpc --host "$MPD_HOST" play
        ;;

        "A") 
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list albumartist | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list albumartist | pick)
            fi            
            clearmode
            while IFS= read -r albumartist; do
                mpc --host "$MPD_HOST" findadd albumartist "${albumartist}" 
                mpc --host "$MPD_HOST" shuffle -q
                mpc --host "$MPD_HOST" play
            done <<< "$result"
        ;;
        "a") 
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list artist | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list artist | pick)
            fi
            clearmode
            while IFS= read -r artist; do
                mpc --host "$MPD_HOST" findadd artist "${artist}" 
                mpc --host "$MPD_HOST" shuffle -q
                mpc --host "$MPD_HOST" play
            done <<< "$result"
        ;;
        "l") 

            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list album | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list album | pick)
            fi
            clearmode
            while IFS= read -r album; do
                mpc --host "$MPD_HOST" findadd album "$album"
                mpc --host "$MPD_HOST" random off
                mpc --host "$MPD_HOST" play
            done <<< "$result"
        ;;

        "g") 
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" list genre | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" list genre | pick)
            fi
            clearmode
            while IFS= read -r genre; do
                mpc --host "$MPD_HOST" findadd genre "$genre" 
                mpc --host "$MPD_HOST" shuffle -q
                mpc --host "$MPD_HOST" play
            done <<< "$result"
        ;;
        "p")
            if [ -f "$(which fzf)" ];then 
                result=$(mpc --host "$MPD_HOST" lsplaylists | fzf --multi)
            else
                result=$(mpc --host "$MPD_HOST" lsplaylists | pick)
            fi
            clearmode            
            while IFS= read -r playlist; do
                mpc --host "$MPD_HOST" load "$playlist" 
                mpc --host "$MPD_HOST" play
            done <<< "$result"
        ;;
        "q")
        ;;
        "h") echo "Use -c to clear before adding.  Export your MPD_HOST as PASS@HOST; localhost is default";;
        *)            echo "You have chosen poorly. Run without commandline input.";;
    esac
