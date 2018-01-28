#!/usr/bin/env bash

#set -x
set -e
set -o pipefail

if [ "${TRAVIS_OS_NAME}" = "osx" ]; then
  brew update
fi

if [ -n "${BOOST_VERSION}" ]; then
  mkdir -p $BOOST_ROOT
  wget --no-verbose --output-document=- \
    https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2 \
    | tar jxf - --strip-components=1 -C "${BOOST_ROOT}"
fi
