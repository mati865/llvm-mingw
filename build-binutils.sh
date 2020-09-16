#!/bin/sh
#
# Copyright (c) 2018 Martin Storsjo
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -e

: ${BINUTILS_VERSION:=2.35.1}

if [ $# -lt 1 ]; then
    echo $0 dest
    exit 1
fi

MAKE=make
if [ "$(which gmake)" != "" ]; then
    MAKE=gmake
fi

PREFIX="$1"
mkdir -p "$PREFIX"
PREFIX="$(cd "$PREFIX" && pwd)"
export PATH="$PREFIX/bin:$PATH"

: ${CORES:=$(nproc 2>/dev/null)}
: ${CORES:=$(sysctl -n hw.ncpu 2>/dev/null)}
: ${CORES:=4}
: ${ARCHS:=${TOOLCHAIN_ARCHS-i686 x86_64}}

if [ ! -d binutils ]; then
    curl -O https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz
fi

tar -xf binutils-${BINUTILS_VERSION}.tar.xz
rm binutils-${BINUTILS_VERSION}.tar.xz

cd binutils-${BINUTILS_VERSION}

for arch in $ARCHS; do
    [ -z "$CLEAN" ] || rm -rf build-$arch
    mkdir -p build-$arch
    cd build-$arch
    _bfd_arch=''
    _triple="$arch-w64-mingw32"
    if [ "$arch" = "i686" ]; then
        LDFLAGS="${LDFLAGS} -Wl,--large-address-aware"
    elif [ "$arch" = "x86_64" ]; then
        _bfd_arch='--enable-64-bit-bfd'
    fi
    ../configure \
        --host="$_triple" \
        --prefix="$PREFIX/$_triple" \
        --disable-werror \
        "$_bfd_arch"
    $MAKE -j$CORES
    $MAKE DESTDIR="$(pwd)/install_dir" install
    mkdir -p "$PREFIX/$arch-w64-mingw32/bin"
    cp "install_dir/$PREFIX/$arch-w64-mingw32/bin/ld.exe" "$PREFIX/$arch-w64-mingw32/bin"
    cp "install_dir/$PREFIX/$arch-w64-mingw32/bin/ld.bfd.exe" "$PREFIX/$arch-w64-mingw32/bin"
    cd ..
done
