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

PROG=mosh
VER=1.4.0
PKG=ooce/network/mosh
SUMMARY="mosh - mobile shell"
DESC="Remote terminal application that allows roaming"

# The protobuf ABI changes frequently. Link mosh statically
# to the current version.
PBUFVER=3.21.9

set_arch 64

init
prep_build

#####################################################################
# Download and build a static version of protobuf

save_buildenv

CONFIGURE_OPTS=" --disable-shared --enable-static"

build_dependency -noctf protobuf protobuf-$PBUFVER \
    protobuf protobuf-cpp $PBUFVER

restore_buildenv

export protobuf_CFLAGS="-I$DEPROOT/opt/ooce/include"
export protobuf_LIBS="-L$DEPROOT/opt/ooce/lib/amd64 -lprotobuf"

# the mosh build requires the protoc protobuf compiler
PATH+=":$DEPROOT$OOCEBIN"

#####################################################################

download_source $PROG $PROG $VER
patch_source
build -noctf    # C++
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
