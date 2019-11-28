#!/bin/bash
set -e

[ $# -eq 0 ] && { echo "change_fstab Usage: whitespace separated list of paths that should be enabled for overlay"; exit 1; }

PATHS_TO_MOVE_TO_OVERLAY=$@

echo -n "  checking if mounts need to be updated to ro... "
BOOT_FILE=/boot/extlinux/extlinux.conf
FSTAB_FILE=/etc/fstab
TMPFS_MARKER="mount_overlay"
if `grep -q ${TMPFS_MARKER} $FSTAB_FILE`; then echo "no (already setup)"; exit 0; else echo "yes"; fi

BOOT_DEVICE=`cat $BOOT_FILE | sed -rn 's/.+root=([^=]*)=.+/\1/p' | head -n 1`
# set boot device to ro
sed -i.orig -r "s|(${BOOT_DEVICE}.*)defaults|\1ro,noatime|" $FSTAB_FILE
# set root device to ro
sed -i -r 's|( / \s*\S*).*|\1\tro,noatime\t\t0\t1|' $FSTAB_FILE

echo "" >> $FSTAB_FILE
for D in $PATHS_TO_MOVE_TO_OVERLAY; do
  echo "mount_overlay	${D}		fuse	nofail,defaults		0	0" >> $FSTAB_FILE
done

echo "none		/tmp		tmpfs	size=50M,defaults	0	0" >> $FSTAB_FILE

exit 0
