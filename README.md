# Digital-Pinage
Bare-bones simple slideshow kiosk image viewer.
User rclone to download files from cloud and feh with X to display images.

## Compatibility
Made for Raspberry Pi (confirmed works on Zero 2 W and 3 B+) but should work on any minimal debian install.

## Prepare
 - A Raspberry Pi with a fresh Raspberry Pi OS Lite install, connected to the internet (either WiFi or Ethernet if your Pi supports it)
 - A computer connected to the internet, on the same network as your Pi, and has rclone installed (to authorize rclone)

# Installing/Using
## Automatically
 1. Download the lastest install.sh
 2. Move the file onto the Pi
    I reccomend using PuTTY or an SSH client to do the rest of this...
 4. Run chmod +x ./install.sh in the same folder as the install file
 5. run ./install.sh to start the installer
    If you don't have all the required programs, the script will install them
 6. Configure rclone (if you haven't already. see below)
 7. Rerun ./install.sh
 8. Follow the installer
 9. Reboot and it should boot into the fullscreen of whatever you have in the folder you setup!

## rclone
If you don't know how to set up rclone, here is the basic steps...
 1. (On the Pi) Run rclone config
 2. Type n for a new remote
 3. Put in a name (i.e. dropbox, save this for later)
 4. Select your service (enter the number ascociated with the one you want to use)
 5. Follow the steps
    Make sure you say n to "Use auto config"
 6. Depending on what you used, rclone will ask you to autorize your selected storage option.
    To do this, you will have to copy the command it gives you, and paste it into the terminal on your computer.
    At the end, it will give you some text that you copy back into your Pi.

    If everything worked, your remote should be setup.
    When the install script asks for the remote, enter remote:location, where remote is the name you set in rclone and location is the location of the file in your storage option.
    For example, if I named the remote "dropbox" while configuring rclone, and the files I want shown in the slideshow are in a folder at the root of my dropbox named "Signage", it would look like this...
    dropbox:Signage
    Alternatively, I named the remote "gDrive" and the images are located in "Signage/BreakRoom"
    gDrive:Signage/BreakRoom

## Manual Install
If you would like to manually install, this is how...
 1. Install dependencies (feh, xorg, and rclone) - sudo apt install feh xorg rclone
 2. Make a new folder (somewhere in your home folder is fine, I suggest /home/{user}/pignage) - mkdir /home/$USER/pignage
 3. Download display.sh, sync.sh, and pignage.conf and move them into the new folder
 4. Download pignage-display.service and pignage-sync.service and move it into /etc/systemd/system/
 5. Edit pignage-display.service and change WorkingDirectory=/home/admin to the home directory for your user, User=admin to your user,in Environment=XAUTHORITY... change /home/admin/... to your user home, and ExecStart=startx /home/admin/pignage/display.sh to the location of display.sh
 6. Edit pignage-sync.service and change User= and WorkingDirectory= to you user and home directory and ExecStart= to the location of sync.sh
 7. Run sudo systemctl daemon-reexec
 8. Run sudo systemctl daemon-reload
 9. Configure rclone (if you haven't)

## Post-Install Config
If you have alread installed using the automatic script, or need to configure after doing a manual install, here is how you manage some things...
 - If a slideshow is running, I recommend using a different tty to change things - Ctrl + Alt + F2
 - You can change how ofter it Syncs, each image stays on-screen, and the remote in pignage.conf
 - You can Enable automatic starting (if you did a manual install or selected n in the automatic installer) by running sudo systemctl enable pignage-display or pignage-sync and disable auto-start by using sudo systemctl disable pignage-...
   I recommend rebooting after enabling/disabling the display service...
