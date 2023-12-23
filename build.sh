#!/bin/bash

set -e

exec 1> >(while IFS= read -r line; do echo "-- [$SCRIPT_NAME $(date +%H:%M:%S)] $line"; done)
exec 2> >(while IFS= read -r line; do echo "-- [$SCRIPT_NAME $(date +%H:%M:%S)] $line" >&2; done)

if ! [[ "$(cat /etc/*-release)" =~ alpine ]]; then
  echo "Please build on alpine linux"
fi

PATH_SCRIPT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$PATH_SCRIPT"

DIR_DIST="$(pwd)/dist"
mkdir -p "$DIR_DIST"

rm -rf build && mkdir build && cd build

function _build()
{
  # Compile sources
  local here="$(pwd)"
  local tool="$1"
  local link="$2"
  local bin="$3"
  local file="$(basename "$link")"

  echo "tool $tool"

  echo "fetch"
  wget "$link"

  echo "extract"
  tar xf "$file"

  local dir="${file%.tar.xz}"
  cd "$dir"

  export LDFLAGS="-static"
  export CFLAGS="-no-pie --static -Os -Wl,-static"
  export CXXFLAGS="-no-pie --static -Os -Wl,-static"

  env FORCE_UNSAFE_CONFIGURE=1 ./configure --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts --disable-doc

  make

  cp "$bin" "$DIR_DIST"/

  # Optimize size
  strip -s -R .comment -R .gnu.version --strip-unneeded "$DIR_DIST/$tool"
  upx --ultra-brute "$DIR_DIST/$tool"

  # Fall to prev dir
  cd "$here"
}

_build "xz" "https://github.com/tukaani-project/xz/releases/download/v5.4.5/xz-5.4.5.tar.xz" ./src/xz/xz
