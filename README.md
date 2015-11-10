yolo-mpd
========

Various MPD tweaks and tips and tools and scripts I've put together or found and tweaked.

#mpdcontrol.sh

Select whether you want to choose a playlist, or by album, artist, or genre. Clears playlist, adds what you chose, starts playing.

Dependencies: 
* [pick](https://github.com/thoughtbot/pick)
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)


#terminalcovers.sh

A kind of hack-y way to show terminal covers in the terminal.  Uses either AA-lib or libcaca.  AA-lib looks MUCH better, but doesn't automatically exit, so requires killall (yeah, that sucks).

Dependencies: 
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)
* [AA-lib](http://aa-project.sourceforge.net/aview/)
* [libcaca](http://caca.zoy.org/wiki/libcaca)

###AA-lib output
![AA-lib](aaview_output.png?raw=true "AA-lib output")
###libcaca output
![LibCaca](libcaca_output.png?raw=true "libcaca output")

#mediakey.sh

This script uses the MPRIS interface to control your media players.  Currently supported players include MPD, Pithos, Audacious, and Clementine

#simple_covers

fetch covers from files and the interwebs.  Can now not only find the current playing song from MPD, but can walk a directory tree.

The albumdir variant works better if you have your library simply divided by albums.

Dependencies:

* [glyr](https://github.com/sahib/glyr)
* [eye3D](http://eyed3.nicfit.net/)
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)

#mpdjay

Small tweaks and changes to the script by rozzin;  you probably want to use that instead
http://www.hackerposse.com/~rozzin/mpdjay