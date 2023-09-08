#!/usr/bin/bash
#
# {{{ CDDL HEADER
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source. A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
# }}}

# Copyright 2022 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=zig
VER=0.11.0
PKG=ooce/developer/zig
SUMMARY="$PROG programming language"
DESC="$PROG is a general-purpose programming language and toolchain for "
DESC+="maintaining robust, optimal, and reusable software."

set_arch 64
# We want to populate the clang-related environment variables
# and set PATH to point to the correct llvm/clang version
# but we want to build with gcc for releases before r151041
set_clangver 16 # zig 0.11.x requires LLVM 16
test_relver '<' 151041 && BASEPATH=$PATH set_gccver $DEFAULT_GCC_VER

CLANGFVER=`pkg_ver clang build-$CLANGVER.sh`

OPREFIX=$PREFIX
PREFIX+=/$PROG

XFORM_ARGS="
    -DOPREFIX=${OPREFIX#/}
    -DPREFIX=${PREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG
"

CONFIGURE_OPTS[amd64]="
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$PREFIX
    -DLLVM_INCLUDE_DIRS=$OPREFIX/llvm-$CLANGVER/include
    -DCLANG_INCLUDE_DIRS=$OPREFIX/llvm-$CLANGVER/include
    -DLLVM_LIBDIRS=$OPREFIX/llvm-$CLANGVER/lib
    -DCLANG_LIBDIRS=$OPREFIX/llvm-$CLANGVER/lib
    -DZIG_STATIC_LLVM=on
    -DZIG_HOST_TARGET_ARCH:STRING="x86_64"
    -DZIG_HOST_TARGET_OS:STRING="solaris"
    -DZIG_HOST_TARGET_TRIPLE:STRING="x86_64-solaris"
"

init

#########################################################################
# Download and build lld

save_buildenv

set_builddir llvm-project-$CLANGFVER.src/lld
prep_build cmake+ninja

CONFIGURE_OPTS[amd64]="
    -DCMAKE_BUILD_TYPE=Release
    -DLLVM_MAIN_SRC_DIR=$TMPDIR/llvm-project-$CLANGFVER.src/llvm
"

build_dependency -noctf lld-$CLANGVER llvm-project-$CLANGFVER.src/lld \
    llvm llvm-project $CLANGFVER.src

restore_buildenv

CONFIGURE_OPTS[amd64]+="
    -DLLD_INCLUDE_DIRS=$DEPROOT/usr/local/include
    -DLLD_LIBDIRS=$DEPROOT/usr/local/lib
"

#########################################################################

note -n "Building $PROG"

set_builddir $PROG-$VER
#set_mirror https://ziglang.org/download/0.11.0/
set_mirror https://ziglang.org/download
set_checksum "none"

CXXFLAGS+=" -fPIC"

#download_source $PROG $PROG $VER
download_source $VER $PROG $VER
patch_source
prep_build cmake+ninja
build -noctf    # C++
strip_install
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
