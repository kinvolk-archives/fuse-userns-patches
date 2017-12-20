#!/bin/bash
#
# Label an executable file under a directory with securit.ima xattr
# Run with a filename:
#
#  $ labelima.sh file1
#

set -euo pipefail

function label_file() {
	local IMA_ATTR="security.ima"
	local filename=$1

	if [ ! -f "$filename" ]; then
		echo "no such file $filename"
		return
	fi

	# skip non-executable file
	[ ! -x "$filename" ] && return

	# generate hash once to label file
	evmctl ima_hash $filename

	# check if its IMA attribute exists
	xattr_val="$(getfattr -m ^$IMA_ATTR --dump -e hex $filename | grep $IMA_ATTR)"
	if [ -z "$xattr_val" ]; then
		echo "no IMA xattr found for $filename"
		return
	fi

	echo "$xattr_val"
}

TARGET_FILE=$1
SECFS_IMA_DIR="/sys/kernel/security/ima"

if [ -z "$(which evmctl)" ]; then
	echo "cannot find evmctl, try to install ima-evm-utils"
	exit 1
fi

if [ ! -f "$TARGET_FILE" ]; then
	echo "no such file $TARGET_FILE"
	exit 1
fi

if [ ! -d "$SECFS_IMA_DIR" ]; then
	echo "no such directory $SECFS_IMA_DIR"
	exit 1
fi

label_file $(readlink -f $TARGET_FILE)
