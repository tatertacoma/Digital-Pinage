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
BASE_DIR="/home/$USER/pinage"

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
cat <<EOF > "$BASE_DIR/pinage.conf"
REMOTE="$remote"
SYNC_TIME=300
SLIDE_TIME=10
EOF
chown "$USER:$USER" "$BASE_DIR/pinage.conf"
echo "Config Made"

# -DISPLAY SCRIPT-
cat <<EOF > "$BASE_DIR/display.sh"
#!/bin/bash

#Environment Vars
SLIDE_TIME=10
BASE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
ACT_DIR="\$BASE_DIR/act"

CONFIG="\$BASE_DIR/pinage.conf"
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

CONFIG="\$BASE_DIR/pinage.conf"
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
if [[ "$answer" =~ ^[Yy]$ ]]; then
	echo "Ok"
	sudo bash -c "cat > "/etc/systemd/system/pinage-display.service"" << EOF
[Unit]
Description=Pinage Display Service
After=systemd-user-sessions.service network.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/admin/.Xauthority

ExecStart=/usr/bin/startx $BASE_DIR/display.sh -- :0

Restart=always
RestartSec=15

TTYPath=/dev/tty1
Standardinput=tty

[Install]
WantedBy=multi-user.target
EOF
	echo "Display Service Configured"

	sudo bash -c "cat > "/etc/systemd/system/pinage-sync.service"" <<EOF
[Unit]
Description=Pinage Sync Service
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
	sudo systemctl daemon-reexec
	sudo systemctl daemon-reload
	read -c "Would you like to start the services now? (y/N): " answer
	if [[ "$answer" =~ ^[Yy]$ ]]; then
		sudo systemctl enable pinage-sync
		sudo systemctl enable pinage-display
		echo "Services Started, will start on boot as well"
	fi
else
	echo "Service not configured..."
fi
echo "Use sudo systemctl {start/stop} pinage-display"
echo "and sudo systemctl {start/stop} pinage-sync"
echo "to start and stop the services..."
sleep 1
echo "Setup Complete
if [[ "$answer" =~ ^[Yy]$ ]]; then
	sudo systemctl start pinage-sync
	sudo systemctl start pinage-display
fi
echo "done"










