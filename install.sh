#!/bin/bash
set -e

# DEPENDENCIES
MISSING=()
command -v feh >/dev/null 2>&1 || MISSING+=("feh")
command -v startx >/dev/null 2>&1 || MISSING+=("xorg")
command -v rclone >/dev/null 2>&1 || MISSING+=("rclone")

if [ ${#MISSING[@]} -ne 0 ]; then
	echo "Installing ${MISSING[*]}"
	sudo apt update
	sudo apt install -y "${MISSING[@]}"
	echo "Configure rclone (if needed) and rerun install script"
	exit 1
else
	echo "All Dependencies Found..."
fi


# CONFIG

USER="${SUDO_USER:-$(id -un)}"
BASE_DIR="/home/$USER/pignage"

read -p "Have you configured rclone? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
	read -p "Please enter your rclone locatin \(i.e. "dropbox:slideshow"\): " remote
else
	echo "Please configure rclone first- rclone config"
	sleep 1
	exit 1
fi

#Make Directories
mkdir -p "$BASE_DIR"/{new,act,old}

#Make .conf
cat <<EOF > "$BASE_DIR/pignage.conf"
REMOTE="$remote"
SYNC_TIME=300
SLIDE_TIME=10
EOF
chown "$USER:$USER" "$BASE_DIR/pignage.conf"
echo "Config Made"

# -DISPLAY SCRIPT-
cat <<EOF > "$BASE_DIR/display.sh"
#!/bin/bash

#Environment Vars
SLIDE_TIME=10
BASE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
ACT_DIR="\$BASE_DIR/act"

CONFIG="\$BASE_DIR/pignage.conf"
[ -f "\$CONFIG" ] && source "\$CONFIG"


#Display Script
xset s off
xset -dpms
xset s noblank

exec feh -F -Y -D "\$SLIDE_TIME" -R 60 "\$ACT_DIR"
EOF
chown "$USER:$USER" "$BASE_DIR/display.sh"
chmod +x "$BASE_DIR/display.sh"
echo "Display Script Made"

# -SYNC-
cat <<EOF > "$BASE_DIR/sync.sh"
#!/bin/bash
 
#Environment Vars
REMOTE=""
BASE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
SYNC_TIME=300

NEW_DIR="\$BASE_DIR/new"
ACT_DIR="\$BASE_DIR/act"
OLD_DIR="\$BASE_DIR/old"

CONFIG="\$BASE_DIR/pignage.conf"
[ -f "\$CONFIG" ] && source "\$CONFIG"

#Main Sync Script
if [[ ! -z "\$REMOTE" ]]; then
	while true; do
	echo "--------------------"
	echo "Checking Files..."
	if ! rclone check "\$REMOTE" "\$ACT_DIR" > /dev/null 2>&1; then
		echo "Changes Detected! Syncing..."
		rclone sync "\$REMOTE" "\$NEW_DIR"
		echo "Have Files, Moving"
		if [ "\$(ls -A "\$NEW_DIR")" ]; then
			rm -rf "\$OLD_DIR"
			mv "\$ACT_DIR" "\$OLD_DIR"
			mv "\$NEW_DIR" "\$ACT_DIR"
			echo "Files Moved, done."
		else
			echo "Error: \$NEW_DIR empty..."
		fi
	else
		echo "No Changes..."
	fi
	sleep "\$SYNC_TIME"
	done
else
	echo "No or Blank Remote Location set!"
fi
EOF
chown "$USER:$USER" "$BASE_DIR/sync.sh"
chmod +x "$BASE_DIR/sync.sh"

# -SERVICES-
read -p "Would you like configure services? (Recommended, requires sudo) (Y/n): " answer
if [[ ! "$answer" =~ ^[Nn]$ ]]; then
	echo "Ok"
	sudo bash -c "cat > "/etc/systemd/system/pignage-display.service"" << EOF
[Unit]
Description=Pignage Display Service
After=getty@tty1.service systemd-user-sessions.service
Conflicts=getty@tty1.service

[Service]
User=$USER
WorkingDirectory=/home/$USER

StandardInput=tty
TTYPath=/dev/tty1
TTYReset=yes
PAMName=login

Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority

ExecStart=/usr/bin/startx $BASE_DIR/display.sh

Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF
	echo "Display Service Configured"

	sudo bash -c "cat > "/etc/systemd/system/pignage-sync.service"" <<EOF
[Unit]
Description=pignage Sync Service
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
ExecStart=$BASE_DIR/sync.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
	echo "Sync Service Configured"
	echo "Reloading daemon"
	sudo systemctl daemon-reexec
	sudo systemctl daemon-reload
	read -p "Would you like to enable services? (Y/n): " answer
	if [[ "$answer" =~ ^[Nn]$ ]]; then
		echo "Ok, re-run script to set-up services..."
		echo "or read readme.md on how to do it manually"
	else
		sudo systemctl enable pignage-display
		sudo systemctl enable pignage-sync
		echo "Services enabled..."
		echo "Reboot to enter slideshow"
	fi
else
	echo "Service not configured..."
	echo "Read readme.md or rerun install.sh to configure"
fi

sleep 1
echo "done"
