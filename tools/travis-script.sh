#!/usr/bin/env bash

#set -x
set -e
set -o pipefail

if [ "${COVERITY_SCAN_BRANCH}" = 1 ]; then
  # Skip this step for the coverity scan branch
  exit 0
fi

ctest --output-on-failure
PYTHONPATH=. python python/demo.py
