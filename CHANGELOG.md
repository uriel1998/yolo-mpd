# Changelog

This changelog is organized by tool and script rather than by release.

Tag meanings:

* `[added]`: first introduction of a tool or script
* `[major]`: major rework, feature expansion, or behavioral change
* `[fix]`: bugfix or edge-case correction
* `[docs]`: documentation-only update
* `[site]`: documentation/site publishing change
* `[moved]`: file move, deprecation, or migration note
* `[maint]`: cross-cutting maintenance work

Commit hashes are short Git hashes from this repository history.

## Release tags

The repository also now carries annotated `v0.9.x` Git tags for major project milestones:

* `v0.9.0` `c314643`: Initial project baseline.
* `v0.9.1` `0840426`: Added the first simple cover script.
* `v0.9.2` `3e9ac3f`: Added `mediakey.sh`.
* `v0.9.3` `883b58d`: Added `mpdcontrol` and terminal cover tooling.
* `v0.9.4` `b324039`: Added `webserver_covers.sh` and `mp3gainhelper.sh`.
* `v0.9.5` `795995c`: Added `bpmtoolshelper.sh`.
* `v0.9.6` `bb65105`: Added `terminal_multiplexer.sh` work.
* `v0.9.7` `81b7e58`: Added `mpdcontrol_add`.
* `v0.9.8` `df19593`: Expanded BPM helper behavior.
* `v0.9.9` `8661fdb`: Early helper-tool milestone replacing the old unprefixed `0.9.9` tag.
* `v0.9.10` `87353d7`: Added `stream_to_mpd.sh`.
* `v0.9.11` `04a304f`: Added `yad_show_mpd.sh`.
* `v0.9.12` `592a6bd`: Added `f_fix_covers.sh`.
* `v0.9.13` `776c7d1`: Reached the first assembled `f_fix_covers.sh` end-to-end workflow.
* `v0.9.14` `0b47e3c`: Added `edit_current_mp3tags.sh`.
* `v0.9.15` `3c86923`: Added `mediakey_no_checking.sh`.
* `v0.9.16` `6290d95`: Introduced terminal covers v2.
* `v0.9.17` `96699ca`: Added working terminal lyric display.
* `v0.9.18` `b2858fb`: Began `nowplaying_to_maubot.sh`.
* `v0.9.19` `66750a7`: Added playlist sync and expanded Maubot integration.
* `v0.9.20` `ce357e5`: Major `f_fix_covers.sh` improvement pass.
* `v0.9.21` `b38394d`: Added `rerun_non_square_covers.sh`.
* `v0.9.22` `8deb207`: Added `f_fix_lyrics.sh`.
* `v0.9.23` `c5ae685`: Added the resumable lyric queue and startup pre-check flow.
* `v0.9.24` `6952ba1`: Normalized helper scripts and Bash entrypoints.
* `v0.9.25` `31be810`: Moved legacy scripts and fixed `terminal_lyrics.sh`.
* `v0.9.26` `41c0f8f`: Fixed remaining root helper-script issues.
* `v0.9.27` `749cf0f`: Reorganized and expanded the README.
* `v0.9.28` `b9f5bb8`: Added this tool-oriented changelog.

## Repository, documentation, and structure

* `[added]` `c314643`: Initial commit.
* `[docs]` `d867c58`: Updated readme.
* `[docs]` `9905b9b`: Fixed readme.
* `[docs]` `b488670`: README touch-up.
* `[docs]` `580df91`: Added images and better documentation.
* `[docs]` `a12e9be`: Docs fix.
* `[site]` `001700d`: Added Pages content.
* `[site]` `fb226d6`: GitHub Pages update.
* `[site]` `96588b3`: Set Jekyll theme.
* `[site]` `1d1582e`: GitHub Pages update.
* `[docs]` `a13f20d`: Updated README.
* `[docs]` `53f4a20`: Docs cleanup.
* `[docs]` `c01a65d`: Fixing docs.
* `[docs]` `c402a7a`: Updated README for `yad_show_mpd.sh`.
* `[docs]` `51a0e8c`: Added example screenshot.
* `[docs]` `95aadd4`: Updated docs with sox and id3v2 notes.
* `[docs]` `1072ddc`: Updated README.
* `[docs]` `f2c60e1`: Updated readme properly.
* `[docs]` `6c6068b`: Expanded documentation.
* `[docs]` `1e3afe8`: Documentation tweak.
* `[docs]` `8898b50`: Updated documentation.
* `[docs]` `464456a`: Updated readme a little.
* `[docs]` `5d2fb2e`: Updated readme and filenames.
* `[docs]` `e090cc8`: Forgot website docs.
* `[docs]` `aae4199`: README and docs update.
* `[docs]` `c349035`: Updated docs with additional output files.
* `[docs]` `749cf0f`: Rewrote README and docs to cover all root scripts and organize them thematically.
* `[maint]` `6952ba1`: Normalized Bash entrypoints and helper-script loud/shebang behavior across root scripts.
* `[moved]` `31be810`: Moved legacy scripts into `old_versions/` and removed obsolete root copies.

## `f_fix_covers.sh`

* `[added]` `592a6bd`: Added the improved cover finder script.
* `[major]` `ad7f64c`: Updated `ffixer` / `ffixer covers` flow and README.
* `[major]` `7662ddd`: Added help framework and cleaned up code.
* `[major]` `7a39778`: Got multi-MP3 cover comparison working.
* `[major]` `6001cb6`: Got cover presentation working; selection handling in progress.
* `[major]` `82f5bfb`: Reached auto-search for cover path.
* `[major]` `1bc3d68`: Got searching covers working.
* `[major]` `689a9cc`: Searching and extracting working together.
* `[major]` `50f0cd5`: Added auto-embed mode for directory workflows.
* `[major]` `094598e`: Reworked flow for MP3 checking to be more efficient.
* `[major]` `776c7d1`: Synthesized the full cover-fix flow together.
* `[major]` `86039da`: Added safety mode.
* `[fix]` `564ffb2`: Fixed quoting with `realpath`.
* `[fix]` `d0e561f`: Fixed duplicate filename return from yad path.
* `[major]` `6185a4b`: Functional end-to-end with more filename edge-case work.
* `[fix]` `d3bd821`: Fixed SHA checking.
* `[major]` `325d4ce`: Added loud and quiet command variants; safety implies output.
* `[major]` `6c0d7c4`: Added alerting.
* `[major]` `68254d2`: Added sound file for alerts.
* `[major]` `0d57eee`: Added removal of old covers and improved no-cover search loop.
* `[major]` `bb04eb8`: Redid song search flow.
* `[fix]` `10e7e05`: Cleaned up found-cover test conditions.
* `[fix]` `61119f8`: Tuned search behavior to avoid too much or too little searching.
* `[major]` `5078c53`: Implemented remove and check-all behavior.
* `[fix]` `cb5f955`: Removed unnecessary writes when embedded covers already matched.
* `[fix]` `dcabd28`: Tweaked cleanup.
* `[major]` `ca8ab7e`: Stable working state.
* `[fix]` `96fd20f`: Fixed a small issue in `f_fix_covers.sh`.
* `[fix]` `586aa81`: Fixed error path when no ID3v2 tags existed and an error line was present.
* `[major]` `d1bf5fa`: Fixed a large embedded-cover write bug.
* `[major]` `ce357e5`: Large batch of `f_fix_covers` improvements.
* `[major]` `b38394d`: Improved presentation of alternative cover files and added rerun helper for non-square covers.
* `[fix]` `58d2782`: Fixed CoverArt Archive download behavior and escaping.
* `[fix]` `367eb64`: Additional cover-fix bugfixes.
* `[fix]` `d484788`: More bugfixes and edge cases for square-cover handling.
* `[fix]` `4f75129`: Specified a tag version to avoid cover-tag writing problems.
* `[maint]` `6952ba1`: Standardized loud handling and shebang normalization for the live cover-fix script.

## `rerun_non_square_covers.sh`

* `[added]` `b38394d`: Added helper to rerun cover fixing for directories with non-square cover files.
* `[fix]` `58d2782`: Updated alongside cover-fix improvements.
* `[fix]` `0c7ee6c`: Included in a larger bugfix pass.
* `[fix]` `367eb64`: Included in follow-up bugfixes.
* `[fix]` `3854322`: Fixed root-script runtime issues and kept it aligned with current `f_fix_covers.sh`.

## `f_fix_lyrics.sh`

* `[added]` `8deb207`: Added lyric version of the `f_fix` workflow.
* `[major]` `c5ae685`: Added startup sidecar pre-check and a physical resumable queue file.
* `[major]` `6b62acc`: Added extensive inline comments and operational explanations.
* `[major]` `b588f0e`: Switched lyric counting to per-artifact operations and stopped skipping tracks when only one lyric sidecar existed.
* `[fix]` `be00d04`: Fixed brittle plain-lyrics handling.
* `[fix]` `7452a53`: Fixed edge case where existing unsynced lyrics triggered a bad error.
* `[major]` `e057134`: Moved request delay semantics to between LRCLIB API calls rather than after every call.

## `yad_show_mpd.sh`

* `[added]` `04a304f`: Added YAD MPD cover popup script.
* `[fix]` `1b9eb75`: Fixed not-playing detection.
* `[major]` `92d0bb8`: Added `MPD_HOST` support to the YAD popup script.
* `[major]` `57a7732`: Added Audacity support and rounded rectangles.
* `[major]` `a56eac7`: Added Strawberry support via `qdbus`.
* `[major]` `9db3c19`: Added support for stream cover art from Strawberry.
* `[major]` `de095c6`: Added Clementine support.
* `[fix]` `fc6e80b`: Reduced redundant `qdbus` calls.
* `[fix]` `fc3311f`: Improved Clementine and Strawberry stream handling.
* `[fix]` `79c41a1`: Follow-up fix.
* `[major]` `805e47d`: Added Plexamp support.
* `[fix]` `f891700`: Corrected an omission in the YAD flow.
* `[fix]` `ece649f`: Fixed runtime bugs, stale state, stream detection, and temp-file handling.

## `terminal_covers.sh`

* `[added]` `883b58d`: Added terminal cover display tooling.
* `[major]` `bb65105`: Updated terminal covers and multiplexer together.
* `[major]` `67b7f45`: Continued terminal cover and multiplexer updates.
* `[major]` `2190ef0`: Started redoing terminal covers with multiple-player support.
* `[major]` `b9ac71e`: First working state of the new terminal cover approach.
* `[major]` `8b0ce61`: Added song title and improved startup behavior.
* `[major]` `6290d95`: Introduced the second version of terminal covers and the demo GIF.
* `[major]` `e307624`: Added optional notification support.
* `[major]` `6319d4d`: Added ImageMagick check for rounded rectangles.
* `[fix]` `3c7667d`: Tweaked cover rendering values while starting lyric work.
* `[fix]` `b58ed77`: Added a needed `clear`.
* `[fix]` `3710f42`: Cleaned up temporary files.
* `[fix]` `fa9e114`: More temp-file cleanup.
* `[fix]` `5bc3562`: Removed extra Plexamp-error code.
* `[fix]` `77945a1`: Typo fix.
* `[fix]` `2a251f6`: Added explicit host strings.
* `[fix]` `8e24cea`: Updated handling for when `audtool` does not exist.
* `[fix]` `cbcc027`: Fixed bracket typo.
* `[fix]` `64d02f2`: Fixed stale cover state, executable checks, notify state, and bad fallback cover paths.

## `terminal_lyrics.sh`

* `[added]` `3c7667d`: Started lyric-display work alongside terminal cover tuning.
* `[added]` `96699ca`: Terminal lyric displayer works.
* `[fix]` `b58ed77`: Added a required `clear`.
* `[major]` `286b440`: Added `.lrc` handling.
* `[fix]` `ac735e5`: Tweaked lyric-length handling.
* `[fix]` `783c0b7`: Stopped clobbering existing plain-text lyric files when `.lrc` existed.
* `[fix]` `31be810`: Fixed multiple runtime bugs and cleaned up the root script during the old-version move.

## `show_covers_w3mimage.sh`

* `[major]` `176b790`: Updated simple cover script to handle album artist and other errors.
* `[added]` `5ccb967`: Added the helper script in its early form.
* `[maint]` `6952ba1`: Shebang normalization in the live script.
* `[fix]` `3854322`: Removed broken path mangling, removed remote fallback usage, and aligned cover fallback behavior with the repo default cover.

## `terminal_multiplexer.sh`

* `[added]` `bb65105`: Added the tmux multiplexer layout.
* `[major]` `67b7f45`: Updated the terminal multiplexer alongside terminal covers.
* `[fix]` `3854322`: Fixed existing-session reattach behavior and quoting around tmux session names.

## `mediakey.sh`

* `[added]` `3e9ac3f`: Added mediakey file.
* `[major]` `ce6e265`: Reworked mediakey logic to be cleaner and loop-oriented.
* `[fix]` `fe896c7`: Tested and working with proper `MPD_HOST`.
* `[major]` `052eb13`: Removed `--host` handling from mediakey.
* `[fix]` `eb1dae3`: Removed debugging output.
* `[major]` `3c86923`: Added simpler mediakey control path.
* `[fix]` `692e93d`: Fixed empty-player handling, MPD state checks, player targeting, and consistent play/pause behavior across both mediakey scripts.

## `mediakey_no_checking.sh`

* `[added]` `3c86923`: Added simpler mediakey control variant.
* `[fix]` `692e93d`: Fixed empty-player handling, optional player selection, MPD state checks, and play/pause behavior.

## `mp3gainhelper.sh`

* `[added]` `b324039`: Added gain helper.
* `[major]` `aa6eb2b`: Added switch to ignore clipping warning.
* `[fix]` `8661fdb`: Small bugfixes.
* `[major]` `d1e9097`: Simplified behavior after the original issue seemed to be gone.
* `[major]` `06ff91c`: Switched helper to `loudgain`.
* `[fix]` `c17a730`: Follow-up fix.
* `[major]` `440547b`: Updated gainhelper around the loudgain switch.
* `[major]` `cc53d13`: Added a watch/concurrency limiter to reduce process clobbering.
* `[major]` `777d76c`: Added more parallelization and `--noclobber`.
* `[fix]` `1b5688e`: Tweaked max jobs to leave some headroom.
* `[fix]` `f05b23a`: Minor tweaks.
* `[maint]` `6952ba1`: Fixed failure propagation, removed stray stdout, clamped job counts, and normalized the shebang.

## `bpmtoolshelper.sh`

* `[added]` `795995c`: Added BPM helper.
* `[major]` `df19593`: Added quiet mode and skip-existing behavior.
* `[fix]` `dd3be4f`: Fixed null BPM tag handling.
* `[major]` `eee2249`: Updated BPM helper to preserve file dates.
* `[major]` `cc53d13`: Added concurrency throttling.
* `[maint]` `6952ba1`: Shebang normalization.
* `[fix]` `41c0f8f`: Fixed filename handling, skip logic, BPM comparison typo, and safer iteration.

## `edit_current_mp3tags.sh`

* `[added]` `0b47e3c`: Initial save for tag-editing helper.
* `[fix]` `9df296e`: Fixed a bug in the tag-editing helper.
* `[fix]` `13972a8`: Updated tag-editing helper.
* `[maint]` `6952ba1`: Shebang normalization.
* `[fix]` `41c0f8f`: Fixed player detection, `IF_URL` assignment, and proper `MPD_HOST` use with `mpc`.

## `nowplaying_to_maubot.sh`

* `[added]` `b2858fb`: Began Maubot integration work.
* `[major]` `14065bc`: First mostly working version.
* `[major]` `2a251f6`: Added explicit host strings.
* `[major]` `66750a7`: Added playlist-sync helper and expanded Maubot behavior.
* `[major]` `9292bd5`: Expanded Maubot integration substantially, including background changes.
* `[maint]` `6952ba1`: Shebang normalization.
* `[fix]` `8ee4a8f`: Fixed runtime auth, cleanup, temp-file handling, logging, and artist/album fallback behavior.

## `stream_to_mpd.sh`

* `[added]` `87353d7`: Added `stream_to_mpd`.
* `[fix]` `b871ee2`: Fixed an early bug.
* `[major]` `ffa2d32`: Switched bookmark defaults.
* `[fix]` `5db88bd`: Added an omitted check.
* `[fix]` `c4eeb63`: Switched grep matching to be more greedy.
* `[maint]` `6952ba1`: Shebang normalization.
* `[fix]` `41c0f8f`: Fixed argument parsing, removed unsafe `eval`, hardened URL handling, and corrected native playback behavior.

## `update_playlists_for_mpd.sh`

* `[added]` `66750a7`: Added playlist sync utility between Clementine and MPD.
* `[maint]` `6952ba1`: Shebang normalization.
* `[fix]` `41c0f8f`: Fixed environment override behavior and safe glob/no-match handling.

## `webserver_covers.sh`

* `[added]` `b324039`: Added simple webserver cover export utility.
* `[maint]` `6952ba1`: Shebang normalization and path cleanup.
* `[fix]` `3854322`: Fixed the source path to align with `${HOME}/Music`.

## `mpdcontrol` legacy tools

* `[added]` `883b58d`: Added `mpdcontrol`.
* `[docs]` `7116e89`: Added visual output of `mpdcontrol`.
* `[added]` `ae4923c`: Added SSH version of `mpdcontrol`.
* `[added]` `81b7e58`: Added `mpdcontrol_add` variant.
* `[major]` `28f569a`: Added auto-use of `fzf` for multi-select.
* `[major]` `7cf7a40`: Added album artist to `mpdcontrol`.
* `[major]` `146cb03`: Added add mode and `MPD_HOST`.
* `[major]` `56b6ddf`: Moved queue-clearing code.
* `[major]` `ebe0857`: Added `nowartist` and `nowalbum` commands.
* `[major]` `d131e0e`: Updated `mpdcontrol` to add songs instead of only controlling playback.
* `[major]` `a2066a2`: Added custom mode for genre, then song.
* `[fix]` `6cf008f`: Fixed custom mode pulling same-named tracks from other artists.
* `[fix]` `cfc9c7d`: Aligned `pick` version behavior.
* `[major]` `0aabfab`: Added random “Bumper” genre selection.
* `[moved]` `31be810`: Moved old root versions into `old_versions/`.
* `[moved]` `749cf0f`: Documented the rewrite and pointed users at the standalone `mpdcontrol` repository.

## Documentation and website-only commits not tied to a single root tool

* `[docs]` `0840426`: Added simple cover file documentation.
* `[docs]` `09878d8`: Added new album directory variant notes.
* `[docs]` `5eef05d`: Added `fzf` to the readme.
* `[docs]` `9b2f93f`: Updated README after `mp3gainhelper` changes.

## Miscellaneous history notes

* `[maint]` `47b63f1`: Merge commit from GitHub.
* `[maint]` `6b20cbd`: Added self-explanatory utility.
* `[maint]` `d4b9b9c`: Miscellaneous maintenance commit.
