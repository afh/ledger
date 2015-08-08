#!/usr/bin/env bash

#set -x
set -e
set -o pipefail

if [ "${COVERITY_SCAN_BRANCH}" = 1 ]; then
  # Skip this step for the coverity scan branch
  exit 0
fi

# These scripts are run for informational purposes and
# should be reintegrated into CTest once they reliably verify the documentation.
python test/CheckTexinfo.py -l ledger -s .
python test/CheckManpage.py -l ledger -s .
