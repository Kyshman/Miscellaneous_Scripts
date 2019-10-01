#!/bin/bash

#### This script is published by Philipp Klaus <philipp.l.klaus@web.de>
#### on <http://blog.philippklaus.de/2011/05/ipv6-6in4-tunnel-via-hurricane-electric-tunnelbroker-net-automatic-ip-update-on-mac-os-x/>
#### It is originally by freese60 and modified by limemonkey.
#### Found on <http://www.tunnelbroker.net/forums/index.php?topic=287.0>

### Uncomment this line to debug the script:
#set -x

#######################################################################
#### Config start
### 
### This configuration file must set the following variables:
### MYIF, DEVNAME, LOCAL_IPV4, EXTERNAL_IPV4,
### HEUSER, HEKEY, HETUNNEL,
### HESERVER4END, HESERVER6END and HECLIENT6END

#MYIF="en1" # en1 = Airport, en0 = Ethernet
MYIF=`netstat -f inet -r | grep default | tr -s ' ' | cut -d ' ' -f 6 | sed -n 1p` # autodetect

DEVNAME='gif0'

LOCAL_IPV4=`ifconfig $MYIF |grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}'`
EXTERNAL_IPV4=`curl -s "http://ipv4.whatsmyip.reliable-ict.de/"`

HEUSER='tkinyua'     # The username you use to login at tunnelbroker.net
HEKEY='y4BGPA8QmrQAWLIJ'   # This 'Update Key' can be found on the 'Advanced' tab of the tunnel details page.
HETUNNEL='545481'           # The 'Tunnel ID' from the tab IPv6 tunnel on the tunnel details page.

### other settings from the website (the tunnel settings):
HESERVER4END='216.66.87.134'
HESERVER6END=2001:470:1f22:163::1
HECLIENT6END=2001:470:1f22:163::2

HE64PREFIX=2001:470:1f23:163::
MYCUSTOMADDRESS=${HE64PREFIX}9:1

#######################################################################
####  Starting the actual script

echo "Please enter the 'sudo' password. This is password of your user account on this Mac. It is needed to set up the IPv6 tunnel."
sudo echo "Gained superuser permissions"
if [ $? == 1 ]; then echo "Sorry! You need to provide your password in order to set up the tunnel."; exit 1; fi

echo "Remove previous tunnel (ignore any errors)"
sudo ifconfig $DEVNAME down
sudo ifconfig $DEVNAME inet6 $MYCUSTOMADDRESS prefixlen 128 delete
sudo ifconfig $DEVNAME inet6 $HECLIENT6END $HESERVER6END prefixlen 128 delete
sudo route delete -inet6 default -interface $DEVNAME
sudo ifconfig $DEVNAME deletetunnel

echo "Removed the previous tunnel. Will continue to set up the tunnel in 5 seconds..."
for i in {5..1}; do echo "$i"; sleep 1; done

echo "Updating your IPv4 tunnel endpoint setting on the Hurricane Electric Website."
# And instead of determining the external IPv4 address on your own, you can also set the param ip to AUTO.
curl -k -s "https://ipv4.tunnelbroker.net/nic/update?username=$HEUSER&password=$HEKEY&hostname=$HETUNNEL&myip=$EXTERNAL_IPV4"
# One more API of the tunnelbroker.net site is: https://username:password@tunnelbroker.net/tunnelInfo.php[?tid=tunnel_id] which returns an XML output

sleep 1

echo "Setting up the tunnel with the new settings now ."
sudo ifconfig $DEVNAME create
sudo ifconfig $DEVNAME tunnel $LOCAL_IPV4 $HESERVER4END
sudo ifconfig $DEVNAME inet6 $MYCUSTOMADDRESS prefixlen 128
sudo ifconfig $DEVNAME inet6 $HECLIENT6END $HESERVER6END prefixlen 128
sudo route -n add -inet6 default $HESERVER6END

# We now provide the user with information if the tunnel has ben set up successfully:
sleep 1
echo "The external IPv6 is now set to `curl -s 'http://ipv6.whatsmyip.reliable-ict.de/'`."
echo "The external IP of your default connection is now set to `curl -s 'http://whatsmyip.reliable-ict.de/'`."

