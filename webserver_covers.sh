#!/bin/bash

# This is a very simple script to aid with the use of MPOD and other MPD 
# controllers that utilize your local webserver to find and serve up album 
# covers. Problem is, of course, that you probably don't want to make your
# entire music directory readable by the internet at large. Sooooooo 
#
# Requisites: rsync, available at https://rsync.samba.org/ 
#
# Reference: https://unix.stackexchange.com/questions/83593/copy-specific-file-type-keeping-the-folder-structure
#

rsync -a --prune-empty-dirs --include '*/' --include '*.jpg' --include '*.png' --exclude '*' $HOME/music/ $HOME/www/covers/