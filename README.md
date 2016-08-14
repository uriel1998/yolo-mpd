yolo-mpd
========

Various MPD tweaks and tips and tools and scripts I've put together or found and tweaked.


#mp3gainhelper.sh

Performs mp3gain analysis and writes to id3 tags. The MP3Gain utility apparently writes by default to APE tags, which aren't used by MPD. But apparently mp3gain has issues corrupting ID3 data if you write directly to ID3 tags, and will just crash and abort if it runs into an error instead of continuing onward.

Dependencies: 
* [mp3gain](http://mp3gain.sourceforge.net/)
* ape2id3 from [MPD Wiki](http://mpd.wikia.com/wiki/Hack:ape2id3.py) or [this gist](https://gist.github.com/uriel1998/6333da780d44e59abbc1761700104329)

#webserver.covers.sh

Very simple script to make your album covers accessible by MPoD or other remote clients without exposing your entire music directory by copying the cover files to the webserver root. (You need to edit this, obvs.)

Dependencies:
* [rsync](https://en.wikipedia.org/wiki/Rsync)

#mpdcontrol.sh

Select whether you want to choose a playlist, or by album, artist, or genre. Clears playlist, adds what you chose, starts playing. The SSH version is for exactly that, especially if you don't have *pick* on that machine.

Dependencies: 
* [pick](https://github.com/thoughtbot/pick)
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)

![output](out.gif?raw=true "What it looks like")

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
