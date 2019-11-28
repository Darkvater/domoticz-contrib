#!/bin/bash
set -e
BASEDIR=$(dirname "$0")

RELEASE_INFO=$(lsb_release --codename --short)
[[ ${RELEASE_INFO} =~ wheezy|stretch|buster ]] || { echo "this script only works on Debian 8-10 (wheezy, stretch, buster)"; exit 1; }

echo "  fetching overlayfs scripts..."
install  -m 755 $BASEDIR/../init.d/saveoverlays-$RELEASE_INFO /etc/init.d/saveoverlays
install  -m 755 $BASEDIR/../init.d/syncoverlayfs.service /etc/systemd/system/

install  -m 755 $BASEDIR/../utils/mount_overlay /usr/local/bin/
install  -m 755 $BASEDIR/../utils/rootro /usr/local/bin/
ln -s /usr/local/bin/rootro /usr/local/bin/rootrw 2>/dev/null

exit 0
