#!/bin/bash
set -e

[ $# -eq 0 ] && { echo "movefs Usage: whitespace separated list of paths that should be enabled for overlay"; exit 1; }

PATHS_TO_MOVE_TO_OVERLAY=$@

echo "  setting up overlay filesystem (this might take a while)..."
for D in ${PATHS_TO_MOVE_TO_OVERLAY}; do
  D_HID=`sed -r "s|/(.+)|/.\1|" <<< $D`
  if [ ! -d ${D_HID}_org ]; then
    mv -v ${D} ${D_HID}_org
    cd ${D_HID}_org
    find . | cpio -pdum ${D_HID}_stage
    mkdir -v ${D} ${D_HID}_rw ${D}/.overlaysync ${D_HID}_org/.overlaysync
  fi
done
