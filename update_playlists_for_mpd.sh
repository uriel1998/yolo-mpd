#!/bin/bash

export PLAYLISTS=/home/steven/Documents/Playlists/Clementine
export FORMPD=/home/steven/Documents/Playlists/mpd

# Ensure both environment variables are set
if [[ -z "$PLAYLISTS" || -z "$FORMPD" ]]; then
  echo "Error: PLAYLISTS and FORMPD environment variables must be set."
  exit 1
fi

# Ensure the directories exist
if [[ ! -d "$PLAYLISTS" || ! -d "$FORMPD" ]]; then
  echo "Error: One or both directories do not exist."
  exit 1
fi

# Loop through all files in $PLAYLISTS
for file in "$PLAYLISTS"/*.m3u; do
  filename=$(basename "$file")
  target="$FORMPD/$filename"

  # If source is newer than target (or target doesn't exist)
  if [[ "$file" -nt "$target" ]]; then
    echo "Updating: $filename"
    sed '/^#/d; s|^/home/steven/Music/||' "$file" > "$target"
  fi
done
