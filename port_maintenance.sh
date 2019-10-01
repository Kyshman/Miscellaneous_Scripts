#!/usr/local/bin/fish
sudo port selfupdate
/usr/bin/read -p "Port selfupdate complete. Press any key to continue... " -n1 -s
port outdated
/usr/bin/read -p "Check for outdated ports complete. Press any key to continue... " -n1 -s
sudo port upgrade outdated
/usr/bin/read -p "Upgrade of outdated ports complete. Press any key to continue... " -n1 -s
port installed inactive
/usr/bin/read -p "Check for inactive ports complete. Press any key to continue... " -n1 -s
sudo port uninstall inactive
/usr/bin/read -p "Uninstall of inactive ports complete. Press any key to continue... " -n1 -s
sudo port reclaim
/usr/bin/read -p "Port reclaim complete. Press any key to continue... " -n1 -s
sudo port_cutleaves
/usr/bin/read -p "port leaves operation complete. Press any key to continue... " -n1 -s
sudo port clean --all all
/usr/bin/read -p "Port clean operation complete. Press any key to exit... " -n1 -s
