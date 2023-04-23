#!/bin/bash

# Generate the Ledger manual in different output formats

# By default US Letter is used as the PDF papersize.
# For those preferring other dimensions add a4 or small
# as a commandline argument to this script to create a
# DIN A4 or smallbook version of the PDF.
case $1 in
  a4*|afour*)
    papersize='--texinfo=@afourpaper';;
  small*)
    papersize='--texinfo=@smallbook';;
  *)
    papersize='';; # US Letter is texinfo default
esac

# Use keg-only Mac Hombrew texinfo if installed.
# Since texi2pdf is a shell script itself executing texi2dvi
# PATH is prepended with the path to correct texinfo scripts.
if [ $(uname -s) = 'Darwin' -a "$(command -v brew)" ]; then
  brew list texinfo >/dev/null 2>&1 \
    && export PATH="$(brew --prefix texinfo)/bin:$PATH"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOURCE=$SCRIPT_DIR/../doc/ledger3.texi

echo "===================================== Making Info..."
makeinfo --force $SOURCE
echo "===================================== Making ASCII..."
makeinfo --force --plaintex --output=$(basename -s .texi $SOURCE).txt $SOURCE
echo "===================================== Making HTML..."
makeinfo --force --html --no-split $SOURCE
echo "===================================== Making PDF..."
texi2pdf --quiet --clean --batch ${papersize} $SOURCE
