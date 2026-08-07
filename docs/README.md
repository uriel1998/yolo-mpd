yolo-mpd
========

Various MP3 and MPD tweaks, tips, tools, and scripts I have put together or found and then tweaked.

This README documents every Bash script in the repository root. Legacy scripts that were moved into `old_versions/` are not covered here except where they matter for migration notes.

## Script Index

### Library repair and tagging

* `f_fix_covers.sh`: Reconcile, search, select, and embed album art for MP3 directories.
* `rerun_non_square_covers.sh`: Re-run `f_fix_covers.sh` only on directories whose `cover.jpg` is not square.
* `f_fix_lyrics.sh`: Build missing `.lrc` and `.txt` lyric sidecars, with resumable queue support.
* `bpmtoolshelper.sh`: Write BPM tags while preserving original file timestamps.
* `mp3gainhelper.sh`: Run `loudgain` per directory while preserving timestamps and propagating failures.
* `edit_current_mp3tags.sh`: Print the currently playing local track path so another editor workflow can operate on it.

### Now playing displays

* `yad_show_mpd.sh`: Show a popup with current cover art and track name.
* `terminal_covers.sh`: Render current cover art directly in a terminal, with optional desktop notification.
* `terminal_lyrics.sh`: Render current lyrics in a terminal, preferring `.lrc`, then `.txt`, then a default file.
* `show_covers_w3mimage.sh`: Display current album art through `w3mimg.sh`.
* `terminal_multiplexer.sh`: Build a tmux music layout around `ncmpcpp`, `cava`, and `terminal_covers.sh`.

### Playback control and integration

* `mediakey.sh`: Send play/pause/next/previous/stop actions through MPRIS with optional player targeting.
* `mediakey_no_checking.sh`: Faster mediakey variant with lighter player checks but the same action model.
* `nowplaying_to_maubot.sh`: Build a composite “now playing” image, set the desktop background, and post the current track to Maubot.

### Streaming, playlists, and cover export

* `stream_to_mpd.sh`: Resolve a stream URL or playlist and send it to MPD, a playlist file, or local playback.
* `update_playlists_for_mpd.sh`: Convert Clementine `.m3u` playlists into MPD-friendly relative-path playlists.
* `webserver_covers.sh`: Mirror cover images into a webserver tree without exposing the entire music library.

### Legacy note

* `mpdcontrol` was rewritten and now lives at <https://github.com/uriel1998/mpdcontrol>.
* Older in-repo copies were moved to `old_versions/`.

## Common assumptions

Most scripts assume:

* your music library lives at `${HOME}/Music`
* `MPD_HOST` is already set, or exists in `${HOME}/.bashrc`
* album art is stored as `cover.jpg` or `folder.jpg`
* file changes should preserve timestamps whenever practical

Several scripts also keep scratch files in `${XDG_CACHE_HOME:-$HOME/.config}/yadshow`.

## Script Reference

### `f_fix_covers.sh`

Repairs album art for MP3 directories by comparing `cover.jpg`, `folder.jpg`, and embedded artwork, optionally prompting for a choice, searching online, and embedding the selected result back into the files.

Important behavior:

* Assumes a single album per directory.
* If exactly one cover variant exists, it is treated as authoritative unless you force verification.
* `--safe` prints intended actions without changing files.
* `--checkall` forces manual verification.
* `--everything` forces online search for every album.
* `--remove` clears embedded art before writing the selected cover.
* `--autoembed` embeds the selected cover into MP3 files.
* `--loud` or `--verbose` sends verbose diagnostics to stderr.

Usage:

```bash
./f_fix_covers.sh -d /path/to/music [options]
```

Dependencies:

* `eyeD3`
* `glyr`
* `sacad`
* `yad`
* `feh`
* `imagemagick`
* `ffprobe`
* `curl`, `wget`, `grep`, `sed`, `timeout`

### `rerun_non_square_covers.sh`

Scans a root tree for `cover.jpg` files whose width and height differ, then reruns `f_fix_covers.sh` on those directories only.

Usage:

```bash
./rerun_non_square_covers.sh [--dry-run] ROOT_DIR
```

Dependencies:

* `identify` from ImageMagick
* `f_fix_covers.sh`

### `f_fix_lyrics.sh`

Recursively scans MP3 files and creates missing synchronized (`.lrc`) and plain-text (`.txt`) lyric sidecars.

Important behavior:

* Uses a persistent queue file, `f_fix_lyrics.queue`, in the repo root for resumable processing.
* Prefers an existing queue if present.
* Removes queue entries only after each file finishes, so interrupted runs resume correctly.
* Treats `.lrc` and `.txt` as separate artifacts: if only one exists, the other is still generated.
* Can derive `.txt` from `.lrc` when only synchronized lyrics exist.
* Uses LRCLIB first, then embedded synced lyrics, then embedded plain lyrics.
* `--force` disables the startup sidecar-pruning pass and rechecks all tracks in scope.

Usage:

```bash
./f_fix_lyrics.sh [--loud] [--force] [--delay SECONDS] [--base DIRECTORY]
```

Dependencies:

* `exiftool`
* `curl`
* `jq`
* `find`, `grep`, `sed`, `awk`

### `bpmtoolshelper.sh`

Computes BPM values with `bpm-tag`, writes them with `eyeD3`, and restores the original file timestamp afterward.

Behavior:

* Recurses from the current directory.
* `--skip` skips files that already have a valid BPM tag.
* `--save` compares against an existing BPM and warns when it differs.
* `--quiet` reduces console output.

Usage:

```bash
./bpmtoolshelper.sh [--save] [--skip] [--quiet]
```

Dependencies:

* `bpm-tag`
* `eyeD3`
* `stat`, `touch`, `find`

### `mp3gainhelper.sh`

Runs `loudgain` per directory while preserving file timestamps after modification.

Behavior:

* Defaults to the current directory when no directory is supplied.
* Accepts one or more literal directories or wildcard directory patterns.
* Runs work in parallel, with `MAX_JOBS` controlling concurrency.
* `--noclobber` skips directories where every MP3 already has both ReplayGain track and album tags.
* Exits non-zero if any background `loudgain` job fails.

Usage:

```bash
./mp3gainhelper.sh [--noclobber] [DIRECTORY ...]
```

Dependencies:

* `loudgain`
* `exiftool`
* `find`, `realpath`, `mktemp`, `touch`

### `edit_current_mp3tags.sh`

Locates the currently playing local file across supported players and prints the resolved on-disk file path.

This is mainly a helper for tag-editing workflows that already know what to do with the returned path.

Usage:

```bash
./edit_current_mp3tags.sh
```

Dependencies:

* `audtool`, `qdbus`, or MPD plus `mpc`

### `yad_show_mpd.sh`

Shows the current cover art and track name in a YAD popup window.

Behavior:

* Supports Audacious, Clementine, Strawberry, Plexamp, and MPD.
* Builds a rounded-corner cover image in the cache directory before display.
* Falls back to `defaultcover.jpg` in the repo root when no cover is found.

Usage:

```bash
./yad_show_mpd.sh
```

Dependencies:

* `yad`
* `mpc`
* `qdbus` or `audtool`
* `imagemagick`

### `terminal_covers.sh`

Shows current cover art in a terminal, using one of several terminal-friendly image renderers.

Behavior:

* Supports Audacious, Clementine, Strawberry, Plexamp, and MPD.
* Writes helper output files into the YAD cache directory.
* Can optionally send a desktop notification with `--notify`.
* Uses `timg`, `jp2a`, `img2txt.py`, or `asciiart` in that order.

Usage:

```bash
./terminal_covers.sh [--notify]
```

Dependencies:

* `mpc`
* `qdbus` or `audtool`
* one of `timg`, `jp2a`, `img2txt.py`, `asciiart`
* optionally `convert` and `notify-send`

### `terminal_lyrics.sh`

Shows lyrics for the current track in the terminal.

Behavior:

* Prefers `.lrc`, then `.txt`, then `default_lyrics.md`.
* Creates a plain-text `.txt` sidecar from `.lrc` if needed.
* Truncates output to fit the current terminal height.
* Reuses and replaces the running `rich` renderer instead of leaking background processes.

Usage:

```bash
./terminal_lyrics.sh
```

Dependencies:

* `rich`
* `mpc`
* `qdbus` or `audtool`

### `show_covers_w3mimage.sh`

Watches MPD for player events and passes the resolved cover image to `w3mimg.sh`.

Behavior:

* Looks for `cover.jpg`, then `folder.jpg`, then falls back to `defaultcover.jpg`.
* Uses `${HOME}/Music` as the library base.

Usage:

```bash
./show_covers_w3mimage.sh
```

Dependencies:

* `mpc`
* `w3mimg.sh`

### `terminal_multiplexer.sh`

Creates or reattaches to a tmux session named `MPD` with panes for:

* `ncmpcpp`
* `cava`
* `terminal_covers.sh`

Usage:

```bash
./terminal_multiplexer.sh
```

Dependencies:

* `tmux`
* `wmctrl`
* `ncmpcpp`
* `cava`
* `terminal_covers.sh`

### `mediakey.sh`

Uses MPRIS to send playback controls to active players, with optional player selection.

Supported actions:

* `p`: play/pause toggle
* `n`: next
* `b`: previous
* `s`: stop
* `z`: pause

Supported player selectors:

* `p`: Pithos
* `a`: Audacious
* `m`: MPD
* `c`: Clementine

Usage:

```bash
./mediakey.sh [p|n|b|s|z] [PLAYER]
```

Dependencies:

* `qdbus`
* `mpc` for MPD state checks

### `mediakey_no_checking.sh`

Simpler mediakey variant that assumes the selected player or active MPRIS players are available and skips some of the extra presence checks from `mediakey.sh`.

Usage:

```bash
./mediakey_no_checking.sh [p|n|b|s|z] [PLAYER]
```

Dependencies:

* `qdbus`
* `mpc` for MPD state checks

### `nowplaying_to_maubot.sh`

Builds a “now playing” composite image, sets it as the desktop background with `feh`, and posts the current track title to a Maubot webhook.

Behavior:

* Loads runtime configuration from `maubot_vars.env`.
* Pulls artist imagery from Deezer and album art from the configured cover server.
* Falls back to `default_artist.jpg` and `default_album.jpg`.
* Uses optional webhook auth from `MAUBOT_HTTP_AUTH` or `MAUBOT_WEBHOOK_USER` and `MAUBOT_WEBHOOK_PASS`.

Required configuration in `maubot_vars.env`:

* `COVERSERVER`
* `MATRIXSERVER`
* `MPD_HOST`
* `MAUBOT_WEBHOOK_INSTANCE`

Usage:

```bash
./nowplaying_to_maubot.sh
```

Dependencies:

* `mpc`
* `curl`
* `jq`
* `wget`
* `feh`
* `imagemagick`

### `stream_to_mpd.sh`

Takes a stream URL or bookmark, resolves the underlying playable URL, and sends it to one of three destinations.

Destinations:

* local playback through `streamlink`
* insertion into MPD
* appending to a playlist file

Usage:

```bash
./stream_to_mpd.sh [--host PASSWORD@HOST] [--mpd|--playlist|--native] [--bookmarks] STREAM
```

Dependencies:

* `streamlink`
* `curl`
* `wget`
* `grep`
* `awk`
* `zenity`
* `mpc` when using MPD output

### `update_playlists_for_mpd.sh`

Converts `.m3u` playlists from a Clementine playlist directory into MPD-style relative-path playlists.

Behavior:

* Uses `PLAYLISTS` and `FORMPD` from the environment when set.
* Otherwise defaults to the hardcoded personal directories in the script.
* Skips playlists with `Radio` in the filename.
* Only rewrites files when the source playlist is newer than the target.

Usage:

```bash
./update_playlists_for_mpd.sh
```

Dependencies:

* `sed`

### `webserver_covers.sh`

Mirrors only cover image files into a webserver tree while preserving directory structure.

Behavior:

* Copies `*.jpg` and `*.png`
* Preserves directory layout
* Prunes empty directories
* Uses `${HOME}/Music/` as the source and `${HOME}/www/covers/` as the target by default

Usage:

```bash
./webserver_covers.sh
```

Dependencies:

* `rsync`

## Some AI/LLM Use

![button_some-ai-used](https://i.imgur.com/rmiLFDD.png)

The code in this repository has been to some degree written or altered by an AI tool with human supervision.  This may include one or more of the following: documentation, locating bugs, or commit messages; in this repository it's been bugsquashing and reorganizing and updating the documentation.  
