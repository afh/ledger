#!/usr/bin/env bash

#set -x
set -e
set -o pipefail

if [ "${COVERITY_SCAN_BRANCH}" = 1 -o "${TRAVIS_OS_NAME}" = "osx" ]; then
  exit 0
fi

make ledger_coverage
$HOME/.local/bin/coveralls --exclude lib --exclude tests --gcov-options '\-lp'
