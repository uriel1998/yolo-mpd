yolo-mpd
========

Various MP3 and MPD tweaks, tips, tools, and scripts I've put together or found and tweaked.

## Contents
  1. [stream_to_mpd](stream_to_mpd)

  2. [f_fix_covers](f_fix_covers)

  3. [yad_show_mpd](yad_show_mpd)

  4. [mpdcontrol.sh](mpdcontrol.sh)

  5. [terminal-multiplexer](terminal-multiplexer)

  6. [bpmhelper](bpmhelper)

  7. [mp3gainhelper](mp3gainhelper)

  8. [terminal_multiplexer](terminal_multiplexer)

  9. [bpmhelper.sh](bpmhelper.sh)

  10. [mp3gainhelper.sh](mp3gainhelper.sh)

  11. [webserver.covers.sh](webserver.covers.sh)

  12. [terminalcovers.sh](terminalcovers.sh)

  13. [mediakey.sh](mediakey.sh)

# stream_to_mpd  

Dependencies:  

* [streamlink](https://streamlink.github.io/)  
* `grep`, `awk`,`curl`,`wget`, and `zenity`, all likely included in your distro packaging.  

Feed this utility a stream (including anything `streamlink` can handle, such as twitch music streamers) and it will pipe it through to your MPD server or save the stream URL in a file (such as an MPD playlist).  Uses `zenity` for gui dialogs if you do not specify elements on the commandline. Originally inspired by [this blog post](https://www.gebbl.net/2013/10/playing-internet-radio-streams-mpdmpc-little-bash-python/)

Usage: `stream_to_mpd [OPTIONS] [STREAM_URL]`  

`--host PASSWORD@HOST`: Needed if your MPD server is not on localhost or you have a password set  
`--mpd` : skip right to MPD output  
`--playlist` : skip right to adding stream URL to a file/playlist  
`--native` : Throw the result to streamlink (probably not needed, but hey)  
`--bookmarks` : use `zenity` to choose a hardcoded bookmark instead of a stream URL  

# f_fix_covers

This is to finally fix those f'in covers in your music directory and to 
synchronize them between `cover.jpg`, `folder.jpg` and what's embedded in the file. 
If the `cover.jpg`, `folder.jpg`, or embedded cover differ, it will present them
to you (with an audible alarm) so that you can select the correct one. If you 
choose none of them, it will search online for cover art.  

If you use `--checkall`, it will prompt you to confirm each album cover, even if
it all matches.

You can also force it to search with each music directory using `--everything`. 
Implies `--checkall` in practice, as the checksum of a downloaded cover *probably* 
is slightly different than what you have. 

You can point it at your *entire* music collection, or just at a *specific* album 
directory.

**This assumes that each directory contains the same album, even if the artists are different.**

## Usage

    `f_fix_covers.sh -d [PATH/TO/MUSIC] [OPTIONS]`

### Options:
    
* `-h|--help         : This.`
* `-a|--autoembed    : Embed found, selected covers into MP3s.`
* `-p|--ping         : Play audible tone when user input needed.`
* `-r|--remove       : Remove existing embedded images in MP3s when cover found.`
* `-c|--checkall     : Manually verify all album covers, even if only one.`
* `-e|--everything   : Check online for covers for every album.`
* `-s|--safe         : Just say what it would do, do not actually do operations.`
* `-l|--loud         : Verbose output.`
* `-d|--dir [DIR]    : Specify the music directory to scan.`

## Dependencies
 * [eye3D](http://eyed3.nicfit.net/)
 * [glyr](https://github.com/sahib/glyr)
 * [eyeD3](http://eyed3.nicfit.net/)
 * [sacad](https://github.com/desbma/sacad)
 * [YAD](https://sourceforge.net/projects/yad-dialog/) 
 
 The following can be installed on Debian/Ubuntu based systems by:
 `sudo apt install feh mpg123 imagemagick ffmpeg grep sed wget curl coreutils`.
 
 * `feh` 
 * `mpg123` or `mplayer` or `mpv`
 * `imagemagick` 
 * `ffprobe` from `ffmpeg`
 * `grep` 
 * `sed` 
 * `wget` 
 * `curl` 
 * `timeout` from `coreutils`
 
 
# yad_show_mpd

# yad_show_mpd.sh

This script -- which should also have an image file named `defaultcover.jpg` in 
its directory -- requires [mpc](http://git.musicpd.org/cgit/master/mpc.git/), 
[imagemagick](https://imagemagick.org/), and [YAD](https://sourceforge.net/projects/yad-dialog/) to 
create a popup with the albumart and trackname of the currently playing song from 
[MPD, the music player daemon](https://www.musicpd.org/).

It assumes your music directory is in `${HOME}/Music`, that your album art is 
named either `cover.jpg` or `folder.jpg` and that `mpc` is already 
set up correctly. The window will auto-close after 10 seconds.

It will attempt to use the environment variable `MPD_HOST`, and 
if it is not found, will examine ${HOME}/.bashrc to see if it is set there (if a 
non-login shell) and set it for the program. If you have a password set for MPD, 
you *must* use `MPD_HOST=Password@host` for it to work.


![output](https://github.com/uriel1998/yolo-mpd/raw/master/yad_show_mpd.png "What it looks like")



# mpdcontrol.sh

Select whether you want to choose a playlist, or by album, artist, or genre. Clears playlist, adds what you chose, starts playing. The SSH version is for exactly that, especially if you don't have `pick` on that machine.

Optionally, if `fzf` is installed on the system, it will seamlessly substitute that program in, with the option to select multiple entries at once (use TAB). 

The `mpdcontrol_add.sh` file does *not* clear the queue so that you can add to the existing playlist.

Dependencies: 
* [pick](https://github.com/thoughtbot/pick)
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)

Optional Dependency
* [fzf](https://github.com/junegunn/fzf)

![output](https://github.com/uriel1998/yolo-mpd/raw/master/out.gif "What it looks like")


# terminal_multiplexer

Uses tmux, xterm, ncmpcpp, cava, and [terminal covers](https://github.com/uriel1998/yolo-mpd#terminalcoverssh) to provide a nice layout. Title set to screen by wmctrl.  No tmux.conf file needed.  Inspired by [this reddit post](https://www.reddit.com/r/unixporn/comments/3q4y1m/openbox_music_now_with_tmux_and_album_art/).

Dependencies: 
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)  
* [tmux](https://tmux.github.io/)  
* [ncmpcpp](https://github.com/arybczak/ncmpcpp)  
* [wmctrl](https://linux.die.net/man/1/wmctrl)  

One or more of the following:  

* [AA-lib](http://aa-project.sourceforge.net/aview/)
* [libcaca](http://caca.zoy.org/wiki/libcaca)
* [img2text](https://github.com/hit9/img2txt)

![AA-lib](https://github.com/uriel1998/yolo-mpd/raw/master/aaview_layout.jpg)
![asciiart](https://github.com/uriel1998/yolo-mpd/raw/master/asciiart_layout.jpg "asciiart output")
![img2txt](https://github.com/uriel1998/yolo-mpd/raw/master/img2txt_layout.jpg "img2txt output")


# bpmhelper.sh

Uses the bpm-tools package, which analyzes BPM quite nicely on linux, 
but then writes tags that overwrite album and genre tags. So this 
wrapper uses eyeD3 to determine if a BPM is already written, then 
analyzes the file, then uses eyeD3 to do the writing to the file. 
I already have eyeD3 for the album art script; a solution 
that does not rely on that dependency can be found 
at [bpmwrap](https://github.com/meridius/bpmwrap).

`bpm-tools` outputs error messages if you do not have id3v2 and sox with mp3 
headers already installed and thus makes the script fail. You can either tweak 
the script or install the packages `sox`, `libsox-fmt-mp3`, and `id3v2`.

Accepts two command line arguments (optional)

Use --save-existing to save existing data.  
Use --skip-existing to skip further analysis of those that have existing BPM
Use --quiet to suppress output (eyeD3 may still output to the screen)

Analyzes the current directory *and all subdirectories*.

Dependencies
* [bpm-tools](http://www.pogo.org.uk/~mark/bpm-tools/)
* [eye3D](http://eyed3.nicfit.net/)

# mp3gainhelper.sh

Performs mp3gain analysis and writes to id3 tags. The MP3Gain utility apparently writes by default to APE tags, which aren't used by MPD. While `mp3gain` no longer has issues corrupting ID3 data if you write directly to ID3 tags, it will crash and abort if it runs into an error instead of continuing onward. That and the options are a pain, so this helps.

Accepts only one command line argument (optional) giving the directory to analyze. Otherwise analyzes the current directory *and all subdirectories*.

Dependencies: 
* [mp3gain](http://mp3gain.sourceforge.net/)
* ape2id3 from [MPD Wiki](http://mpd.wikia.com/wiki/Hack:ape2id3.py) or [this gist](https://gist.github.com/uriel1998/6333da780d44e59abbc1761700104329)

# webserver.covers.sh

Very simple script to make your album covers accessible by MPoD or 
other remote clients without exposing your entire music directory by 
copying the cover files to the webserver root. (You need to edit this, obvs.)

Dependencies:
* [rsync](https://en.wikipedia.org/wiki/Rsync)

# terminalcovers.sh

A kind of hack-y way to show terminal covers in the terminal.  Uses 
either AA-lib or libcaca.  AA-lib looks MUCH better, but doesn't 
automatically exit, so requires killall (yeah, that sucks).  You will 
need to *edit* the script to choose a different renderer.

Dependencies: 
* [mpc](http://git.musicpd.org/cgit/master/mpc.git/)

One or more of the following:  

* [AA-lib](http://aa-project.sourceforge.net/aview/)
* [libcaca](http://caca.zoy.org/wiki/libcaca)
* [img2text](https://github.com/hit9/img2txt)

### AA-lib output
![AA-lib](https://github.com/uriel1998/yolo-mpd/raw/master/aaview_output.png "AA-lib output")
### libcaca output
![LibCaca](https://github.com/uriel1998/yolo-mpd/raw/master/libcaca_output.png "libcaca output")

# mediakey.sh

This script uses the MPRIS interface to control your media players.  
Currently supported players include MPD, Pithos, Audacious, and Clementine

