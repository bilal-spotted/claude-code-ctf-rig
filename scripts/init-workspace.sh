#!/bin/bash
# Creates the challenge working directories the rig expects.
# Run this once inside your CTF workspace after copying CLAUDE.md,
# the .claude/ agents and skills, and settings.json into place.

set -e
for cat in web pwn crypto rev forensics ai hardware misc; do
    mkdir -p "$cat"
done
echo "Created challenge category folders: web pwn crypto rev forensics ai hardware misc"
echo "Each challenge gets its own subfolder, e.g. pwn/challenge-name/,"
echo "holding its files, your NOTES.md, and your solve scripts."
