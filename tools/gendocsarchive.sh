#!/bin/bash

# Create an archive of old versions of the Ledger manual

# Relative path to the Ledger manual source
SOURCE=../doc/ledger3.texi

# The directory in which the archive of old manual versions are placed,
# defaults to an archive/ directory in the directory that holds the source.
DEST_DIR=${1:-$(dirname $SOURCE)/archive}

# The the directory of this file
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Change into this script's directory as it expects
# to be able to work with relative paths
pushd $SCRIPT_DIR

git diff --exit-code $SOURCE >/dev/null
if [ $? -ne 0 ]; then
  cat <<EOF
Error: $SOURCE has local modifications

To generate old versions of the Ledger manual this script
needs to place old versions of the manual into the source tree.
Please stash or commit your changes and re-run this script
EOF
  exit -1
fi


# Iterate over all 3.x release tags of Ledger
for VERSION in $(git tag --list v3.\* | sort -V); do
  # Get the date of the release
  rdate=$(git log -1 --date=format:'%e %B %Y' --format=%cd $VERSION)

  echo "Building manual for Ledger version $VERSION (${rdate# })"

  # Temporarily use the ledger3.texi source from the release tag
  git show $VERSION:$SOURCE > $SOURCE

  # The version of Ledger was not always properly changed in the documentation, e.g. the
  # manual shows version 3.0 for version 3.0.2.
  # As of Ledger 3.1 version information comes from the CMake generated file version.texi.
  # Therefore the documentation is changed in-place to show the correct version of Ledger
  # and include the date of the release.
  /usr/bin/sed \
    -e "s/^@subtitle For Version.*of Ledger/@subtitle For Ledger version $VERSION, ${rdate# }/" \
    -e "s/^@top Overview/@top Ledger version $VERSION (${rdate# })/" \
    -e '/^@include version.texi/d' \
    -i "" \
    $SOURCE \
    # sed

  # Generate the Ledger manual in various formats
  $SCRIPT_DIR/gendocs.sh

  # Copy the info, html, pdf, and text format of the Ledger manual
  # into a per-version archive directory.
  DEST="$DEST_DIR/${VERSION#v}"
  mkdir -p $DEST
  mv ledger3.{info,html,pdf,txt} $DEST
  echo
done

git checkout $SOURCE

# Change back into previous working directory
popd
