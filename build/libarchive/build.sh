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

PROG=libarchive
VER=3.7.1
PKG=ooce/library/libarchive
SUMMARY="libarchive"
DESC="Multi-format archive and compression library"

OPREFIX=$PREFIX
PREFIX+="/$PROG"

forgo_isaexec
test_relver '>=' 151045 && set_clangver

SKIP_LICENCES=various

XFORM_ARGS="
    -DPREFIX=${PREFIX#/}
    -DOPREFIX=${OPREFIX#/}
    -DPROG=$PROG
    -DPKGROOT=$PROG
"

TESTSUITE_SED="/libtool/d"

CONFIGURE_OPTS+="
    --disable-static
"
CONFIGURE_OPTS[i386]+="
    --libdir=$OPREFIX/lib
"
CONFIGURE_OPTS[amd64]+="
    --libdir=$OPREFIX/lib/amd64
"

LDFLAGS[i386]+=" -Wl,-R$OPREFIX/lib"
LDFLAGS[amd64]+=" -Wl,-R$OPREFIX/lib/amd64"

init
download_source $PROG $PROG $VER
prep_build
patch_source
build
run_testsuite check
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
