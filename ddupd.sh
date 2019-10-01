#!/bin/bash

#
# ddupd v1.04 (5th April 2016)
# Another Dynamic DNS Updater. But simpler.
#

##
## Tunnelbroker Details
TBENABLE=1
TBUSER="username"
TBUKEY="tunnel_key"
TBTID="tunnel_id"
##

IP4=`wget -q -O - "http://v4.ipv6-test.com/api/myip.php"`

##
## Logging
DDUPDLOG="/tmp/ddupd.log"
find $DDUPDLOG -size +64k -exec rm -f {} \;
touch $DDUPDLOG
##

if [ "${#IP4}" -lt 7 ]; then
	echo "`date  +'%d-%m-%Y %H:%M:%S'`: [$$] : WARN : Our IP was reported as '$IP4'. Not continuing." >> $DDUPDLOG
	exit 0
else
	echo "Current IP: $IP4"
fi

# Remove the IP temp file if it's not changed in 7 days.
DDIPTMP="/tmp/ddupd_ip4"
find $DDIPTMP -mtime +7 -exec rm -f {} \;

PP4=""
if [ -f /tmp/ddupd_ip4 ]; then
	PP4=`cat /tmp/ddupd_ip4`
fi

if [ "$IP4" = "$PP4" ]; then
	TIME=`date '+%H%M'`
	# If it's between 0500 and 0505, force a heartbeat update.
	# This does assume we're being called every 5 minutes.
	if [ "$1" != "force" ]; then
		if [ $TIME -lt 500 ] || [ $TIME -gt 504 ]; then
			echo "Address has not changed since last attempt."
			exit 0
		fi
	fi

	echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : BEAT : Pushing $IP4 as our current address." >> $DDUPDLOG

fi

# Set Tunnelbroker IP
if [ $TBENABLE = 1 ]; then
	TBOUT=`curl -4 -k -s "https://$TBUSER:$TBUKEY@ipv4.tunnelbroker.net/nic/update?hostname=$TBTID&myip=$IP4"`
	if [[ "$TBOUT" =~ "good" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [TB] Updated tunnel $TBTID to $IP4." >> $DDUPDLOG
	elif [[ "$TBOUT" =~ "nochg" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [TB] Sent an update to Tunnelbroker, but IP for tunnel $TBTID was already $IP4." >> $DDUPDLOG
	else
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [TB] $TBOUT" >> $DDUPDLOG
	fi
fi


echo "$IP4" > /tmp/ddupd_ip4
exit 0