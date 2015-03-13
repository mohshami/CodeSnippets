#!/bin/sh

# PKGNG bootstrapper
# 20150312, Mohammad Al-Shami

# Use full pathes just in case
PKG=/usr/sbin/pkg
ENV=/usr/bin/env
UNAME=/usr/bin/uname
SED=/usr/bin/sed
MV=/bin/mv
RM=/bin/rm
MKDIR=/bin/mkdir
CAT=/bin/cat

# If for some reason you want to use a different package server
# Send it as a parameter to the script
if [ ! -z $1 ]; then
	pkgServer=$1
else
	pkgServer=192.168.1.150
fi
release=`$UNAME -r | $SED -r "s/([0-9]+).([0-9]+)-RELEASE/\1\2x64/"`

export PACKAGESITE=http://$pkgServer/$release-default

# Remove the default FreeBSD repo, only if it exists
if [ -f /etc/pkg/FreeBSD.conf ]; then
	$MV /etc/pkg/FreeBSD.conf /etc/pkg/FreeBSD.conf.org
fi

# Bootstrap pkg
$ENV ASSUME_ALWAYS_YES=YES $PKG bootstrap

# Perform some cleanup
$RM -f /usr/local/etc/pkg.conf

# Set up our repo, which will then be overwritten by Salt
$MKDIR -p /usr/local/etc/pkg/repos/
$CAT > /usr/local/etc/pkg/repos/magneto.conf <<EOF
magneto : {
    url : "pkg+$PACKAGESITE",
    mirror_type : "srv",
    enabled : true,
}
EOF