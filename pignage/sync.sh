#!/bin/bash
 
#Environment Vars
REMOTE=""
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_TIME=300

NEW_DIR="$BASE_DIR/new"
ACT_DIR="$BASE_DIR/act"
OLD_DIR="$BASE_DIR/old"

CONFIG="$BASE_DIR/pignage.conf"
[ -f "$CONFIG" ] && source "$CONFIG"

#Main Sync Script
if [[ ! -z "$REMOTE" ]]; then
	while true; do
	echo "--------------------"
	echo "Checking Files..."
	if ! rclone check "$REMOTE" "$ACT_DIR" > /dev/null 2>&1; then
		echo "Changes Detected! Syncing..."
		rclone sync "$REMOTE" "$NEW_DIR"
		echo "Have Files, Moving"
		if [ "$(ls -A "$NEW_DIR")" ]; then
			rm -rf "$OLD_DIR"
			mv "$ACT_DIR" "$OLD_DIR"
			mv "$NEW_DIR" "$ACT_DIR"
			echo "Files Moved, done."
		else
			echo "Error: $NEW_DIR empty..."
		fi
	else
		echo "No Changes..."
	fi
	sleep "$SYNC_TIME"
	done
else
	echo "No or Blank Remote Location set!"
fi
