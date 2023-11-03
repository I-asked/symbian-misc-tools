#!/usr/bin/env bash
set -euo pipefail

IMAGE_SDK=/Nokia_Symbian_Belle_SDK_v1.0.erofs
IMAGE_GCC=/gcc-12.1.0.erofs

MOUNT_SDK=/var/lib/nokiaprefix/drive_c/Nokia/devices/Nokia_Symbian_Belle_SDK_v1.0/
MOUNT_GCC=/var/lib/nokiaprefix/drive_c/gcc-12.1.0/

NOTIF_SDK=/tmp/Nokia_Symbian_Belle_SDK_v1.0.mount
NOTIF_GCC=/tmp/gcc-12.1.0.mount

_on_exit () {
  >&2 echo " ==> Cleaning up..."

  fusermount -z -u "${MOUNT_SDK}" &>/dev/null ||:
  fusermount -z -u "${MOUNT_GCC}" &>/dev/null ||:
}
trap '_on_exit' EXIT

_on_error () {
  >&2 echo " ==> sdk-run.sh exited with a non-zero exit code"
}
trap '_on_error $? $LINENO' ERR

mkdir -p "${MOUNT_SDK}"
mkdir -p "${MOUNT_GCC}"

>&2 echo " ==> Mounting the SDK..."

erofsfuse "${IMAGE_SDK}" "${MOUNT_SDK}" &>/dev/null ||:
erofsfuse "${IMAGE_GCC}" "${MOUNT_GCC}" &>/dev/null ||:

>&2 echo " ==> SDK ready!"

/sbin/update-binfmts --enable wine &>/dev/null ||:

# FIXME: Sooo broken... ("workaround")
apt-get update &>/dev/null && apt-get install -y xxd &>/dev/null

"$@"
