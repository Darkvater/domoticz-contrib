#!/bin/bash
set -e
BASEDIR=$(dirname "$0")

showHelp() {
cat << EOF
Usage: ./install_overlayfs.sh -r <ro_paths> -o <overlay>
Note: requires a debian installation, might work on other distributions,
but it's not tested. Make sure the path arguments is within quotes
-h, --help              Display help
-r, --read-only-paths   <arg>  Space separate list of paths to mount
                               as ro (recommended /)
-o, --overlay-paths     <arg>  Space separated list of paths to mount as
                               overlay (recommended "/var /home/root")
EOF
}

options=`getopt -l "help,read-only-paths:,overlay-paths:" -o "hr:o:" -- "$@"`
eval set -- "$options"

while true; do
  case $1 in
  -h|--help)              showHelp; exit 0;;
  -r|--read-only-paths)   PATHS_TO_MOUNT_AS_RO=$2; shift;;
  -o|--overlay-paths)     PATHS_TO_MOVE_TO_OVERLAY=$2; shift;;
  --)                     break;;
  *)                      showHelp; exit 1;
  esac
  shift
done

REMAINING_ARGS=$@
([ -z "$PATHS_TO_MOUNT_AS_RO" ] || [ -z "$PATHS_TO_MOVE_TO_OVERLAY" ]) && { echo "required argument not set!"; exit 1; }
[ "$REMAINING_ARGS" == "--" ] || { echo "trailing arguments, are you sure you have put your arguments in quotes?"; exit 1; }
echo "implement overlayfs creating a read-only root filesystem..."

echo "  disabling rsyslog service"
systemctl stop syslog.socket rsyslog
systemctl disable syslog.socket rsyslog

if [ -x "$(command -v dphys-swapfile)" ]; then
  echo "  turning off swap..."
  dphys-swapfile swapoff
  dphys-swapfile uninstall
  systemctl disable dphys-swapfile
fi

echo "  setting up overlayfs..."
apt -qq install fuse lsof

$BASEDIR/overlayfs/setup_files.sh
$BASEDIR/overlayfs/change_boot.sh
$BASEDIR/overlayfs/change_fstab.sh ${PATHS_TO_MOVE_TO_OVERLAY}
$BASEDIR/overlayfs/movefs.sh ${PATHS_TO_MOVE_TO_OVERLAY}

echo "  customising paths on overlayfs scripts"
sed -i -r "s|(for FS in ).+|\1${PATHS_TO_MOUNT_AS_RO}|" /usr/local/bin/rootro
sed -i -r "s|(RequiresMountsFor=).*|\1${PATHS_TO_MOVE_TO_OVERLAY}|" /etc/systemd/system/syncoverlayfs.service

echo "  starting overlayfs service..."
systemctl enable syncoverlayfs
systemctl start syncoverlayfs

echo "  setup motd script to show whether we're running in ro/row mode"
install -m 755 $BASEDIR/overlayfs/motd/80-overlayfs /etc/update-motd.d/

echo "  activating all changes..."
for D in ${PATHS_TO_MOVE_TO_OVERLAY}; do
  mount ${D}
done

echo "  done, please reboot to activate changes"
systemctl is-active --quiet syncoverlayfs
