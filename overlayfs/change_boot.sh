#!/bin/bash
set -e

BOOT_FILE=/boot/extlinux/extlinux.conf
ARMBIAN_BOOT_FILE=/boot/armbianEnv.txt

echo -n "  checking if boot needs to be changed... "

RO_KERNEL_OPTIONS="ro noswap fastboot"
if [[ -f "$ARMBIAN_BOOT_FILE" ]]; then
  if `grep -q "${RO_KERNEL_OPTIONS}" $ARMBIAN_BOOT_FILE`; then echo "no (already setup)"; exit 0; else echo "yes"; fi
  echo "extraargs=$RO_KERNEL_OPTIONS" >> $ARMBIAN_BOOT_FILE
elif [[ -f "$BOOT_FILE" ]]; then
  if `grep -q "${RO_KERNEL_OPTIONS}" $BOOT_FILE`; then echo "no (already setup)"; exit 0; else echo "yes"; fi

  if `egrep -q "label .+rockchip-ayufan.+" $BOOT_FILE`; then
    sed -i.orig -r "s/(APPEND=\".+)\"/\1 ${RO_KERNEL_OPTIONS}\"/"  /etc/default/extlinux
    if [ -x "$(command -v update_extlinux.sh)" ]; then update_extlinux.sh; fi
    if [ -x "$(command -v update-extlinux.sh)" ]; then update-extlinux.sh; fi
  else
    RO_KERNEL_NAME="kernel-ro"
    echo "  adding additional ${RO_KERNEL_NAME} boot target"

    DEFAULT_KERNEL_NAME=`cat $BOOT_FILE | sed -nr 's/default (.+)/\1/p'`

    # select header and all indented lines belonging to it
    DEFAULT_KERNEL_OPTIONS=`awk -v dko="label ${DEFAULT_KERNEL_NAME}" '$0 ~ dko && !f{f=1;x=$0;sub(/[^ ].*/,"",x);x=x" ";print;next} f {if (substr($0,1,length(x))==x)print; else f=0}' $BOOT_FILE`

    sed  -i.orig "s/default ${DEFAULT_KERNEL_NAME}/default ${RO_KERNEL_NAME}/" $BOOT_FILE
    echo "" >> $BOOT_FILE
    echo "${DEFAULT_KERNEL_OPTIONS}" | sed -e "s/${DEFAULT_KERNEL_NAME}/${RO_KERNEL_NAME}/" -e "s/ rw / ${RO_KERNEL_OPTIONS} /" >> $BOOT_FILE
  fi
fi

exit 0
