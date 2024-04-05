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

# Copyright 2023 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=zig
#VER=0.12.0-dev.587+eb072fa52
#VER=0.12.0d587
VER=0.12.0
MAJVER=0
MINVER=12
#MAJVER=${VER%%.*}
#MINVER=${VER%.*}
#MINVER=${MINVER#*.}
PKG=ooce/developer/zig-012
SUMMARY="$PROG programming language"
DESC="$PROG is a general-purpose programming language and toolchain for "
DESC+="maintaining robust, optimal, and reusable software."

#
# Zig 0.12.x requires LLVM 17, which requires rel 151045 or later.
#
min_rel 151045
set_clangver 17
set_arch 64

CLANGFVER=`pkg_ver clang build-$CLANGVER.sh`

set_patchdir patches-$MAJVER.$MINVER
OPREFIX=$PREFIX
PREFIX+=/$PROG-$MAJVER.$MINVER

XFORM_ARGS="
    -DOPREFIX=${OPREFIX#/}
    -DPREFIX=${PREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG-$MAJVER.$MINVER
    -DMEDIATOR=$PROG -DMEDIATOR_VERSION=$MAJVER.$MINVER
"

#
# CMAKE_BUILD_TYPE=RelWithDebInfo
#
#   Keep debug info so symbols are available to the various
#   debugging tools.
#
# ZIG_STATIC_LLVM=on
#
#   Embed the LLVM toolchain in the zig executable. This is
#   the preferred way to ship zig.
#
# ZIG_HOST_TARGET_ARCH=x86_64
# ZIG_HOST_TARGET_OS=solaris
# ZIG_HOST_TARGET_TRIPLE=x86_64-solaris
#
#   Manually set the triple. Otherwise it falls back to uname and
#   we get a bogus target.
#
# ZIG_TARGET_MCPU=baseline
#
#   Target the compiler to pentium4-era CPU features so it can
#   work on the maximum set of hosts. This only effects the
#   compiler executable, applications built with this compiler
#   can set their own CPU features.
#
CONFIGURE_OPTS[amd64]="
    -DCMAKE_BUILD_TYPE=RelWithDebInfo
    -DCMAKE_INSTALL_PREFIX=$PREFIX
    -DLLVM_INCLUDE_DIRS=$OPREFIX/llvm-$CLANGVER/include
    -DCLANG_INCLUDE_DIRS=$OPREFIX/llvm-$CLANGVER/include
    -DLLVM_LIBDIRS=$OPREFIX/llvm-$CLANGVER/lib
    -DCLANG_LIBDIRS=$OPREFIX/llvm-$CLANGVER/lib
    -DZIG_STATIC_LLVM=on
    -DZIG_TARGET_MCPU="baseline"
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

# https://ziglang.org/builds/zig-0.12.0-dev.654+599641357.tar.xz
#set_mirror https://ziglang.org
#set_checksum none
#download_source "builds" $PROG "0.12.0-dev.654+599641357" "" \
#		"--transform=s/^zig-0.12.0-dev.654+599641357/zig-0.12.0/"
#		"--transform=s/^zig-0.12.0-dev.587+eb072fa52/zig-0.12.0d587/"

# 0266017b597e8fc74f41ec4eb78b1466751021c9: Make EfiPhysicalAddress in std/os/uefi/tables.zig public
clone_github_source "zig-0.12.0" $GITHUB/ziglang/zig e5d90026 "" 3000
append_builddir "zig-0.12.0"

CXXFLAGS+=" -fPIC"

#download_source $PROG $PROG $VER
patch_source
prep_build cmake+ninja
build -noctf    # C++
strip_install
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
