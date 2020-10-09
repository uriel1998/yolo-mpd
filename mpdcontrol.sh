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


	if [ "$1" == "" ]; then
		echo -e "\E[0;32m(\E[0;37mg\E[0;32m)enre, (\E[0;37ma\E[0;32m)rtist, a(\E[0;37ml\E[0;32m)bum, (\E[0;37mp\E[0;32m)laylist, or (\E[0;37mq\E[0;32m)uit? "; tput sgr0
		read CHOICE
	else
		CHOICE=$(echo "$1")
	fi

        
    
	case "$CHOICE" in
		"a") 
            if [ -f $(which fzf) ];then 
                result=$(mpc list artist | fzf --multi)
            else
                result=$(mpc list artist | pick)
            fi
            mpc clear -q
            while IFS= read -r artist; do
                mpc findadd artist "${artist}" 
                mpc shuffle -q
                mpc play
            done <<< "$result"
		;;
		"l") 

            if [ -f $(which fzf) ];then 
                result=$(mpc list album | fzf --multi)
            else
                result=$(mpc list album | pick)
            fi
            mpc clear -q
            while IFS= read -r album; do
                mpc findadd album "$album"
                mpc random off
                mpc play
            done <<< "$result"
		;;

		"g") 
            if [ -f $(which fzf) ];then 
                result=$(mpc list genre | fzf --multi)
            else
                result=$(mpc list genre | pick)
            fi
            mpc clear -q
            while IFS= read -r genre; do
                mpc findadd genre "$genre" 
                mpc shuffle -q
                mpc play
            done <<< "$result"
		;;
		"p")
            if [ -f $(which fzf) ];then 
                result=$(mpc lsplaylists | fzf --multi)
            else
                result=$(mpc lsplaylists | pick)
            fi
            while IFS= read -r playlist; do
                mpc load "$playlist" 
                mpc shuffle -q
                mpc play
            done <<< "$result"
		;;
		"q")
		;;
		*) echo "You have chosen poorly. Run without commandline input."
	esac
