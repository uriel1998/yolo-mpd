#!/bin/bash

################################################################################
#  A simple utility to allow playlist selection and playing from cli for MPD
#
#  by Steven Saus
#
#  Licensed under a Creative Commons BY-SA 3.0 Unported license
#  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/.
#
#  This is an example of how to utilize the script over SSH. In this example, keyfile
#  pairing is already set up.  steven is the username, wombat.local is the remote server
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
			artist=$(ssh steven@wombat.local 'mpc list artist' | pick)
			ssh steven@wombat.local "mpc clear -q; mpc findadd artist '$artist';mpc shuffle -q;mpc play"
		;;
		"l") 
			album=$(ssh steven@wombat.local 'mpc list album' | pick)
			ssh steven@wombat.local "mpc clear -q; mpc findadd album '$album';mpc random off ;mpc play"
		;;

		"g") 
			genre=$(ssh steven@wombat.local 'mpc list genre' | pick)
			ssh steven@wombat.local "mpc clear -q;mpc findadd genre '$genre';mpc shuffle -q;mpc play"
		;;
		"p")
			playlist=$(ssh steven@wombat.local 'mpc lsplaylists'| pick)
			ssh steven@wombat.local "mpc clear -q;mpc load '$playlist';mpc shuffle -q;mpc play"
		;;
		"q")
		;;
		*) echo "You have chosen poorly. Run without commandline input."
	esac
