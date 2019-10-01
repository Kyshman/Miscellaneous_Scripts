#!/usr/local/bin/fish
# Get the current working directory
set -e WD
set -g WD $PWD
cd "/Users/tony/Google Drive/waldo_backups"
# Running the Full MTD Backup first
echo "Running the Full MTD Backup Process"
#/opt/local/bin/bash /Users/tony/Documents/Scripts/Full_OpenWRT_MTD_Backup.sh
bass /Users/tony/Documents/Scripts/Full_OpenWRT_MTD_Backup.sh
echo "Running the Configuration, List of Packages Backup Process... " 
echo "Check for Installed Packages... "
rm -f installed_packages.txt
ssh root@waldo "opkg list_installed | cut -f 1 -d ' '" > installed_packages-(date +%F).txt
#less installed_packages.txt
echo "Perform Sysupgrade Configuration backup"
ssh root@waldo "sysupgrade --create-backup /tmp/backup-`cat /proc/sys/kernel/hostname`-`date +%F`.tar.gz; ls /tmp/backup*"
echo "Fetching the new backup"
scp "root@waldo:/tmp/back*" .
echo "Done"
echo "Removing backup from Router"
ssh root@waldo "rm -rf /tmp/backup*"
echo "Done"
#ls backup*
/usr/bin/read -p "OpenWRT Backup complete for Router WALDO. Press any key to exit... " -n1 -s
cd $WD