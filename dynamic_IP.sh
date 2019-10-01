#!/bin/bash
# - This will detect a changed IP and add the appropriate rule in UFW
# - Just uncomment Current_IP6 to use IPv6 and comment out Current_IP4
# Source - https://unix.stackexchange.com/questions/91701/ufw-allow-traffic-only-from-a-domain-with-dynamic-ip-address
HOSTNAME=waldo.kysh.me.ke
LOGFILE=$HOME/ufw.$HOSTNAME.log
Current_IP4=$(host $HOSTNAME | head -n1 | cut -f4 -d ' ')
#Current_IP6=$(host $HOSTNAME | tail -n1 | cut -f4 -d ' ')

if [ ! -f $LOGFILE ]; then
    /usr/sbin/ufw allow in from $Current_IP4 to any port 9090 proto tcp
    echo $Current_IP > $LOGFILE
else

    Old_IP=$(cat $LOGFILE)
    if [ "$Current_IP" = "$Old_IP" ] ; then
        echo IP address has not changed
    else
        /usr/sbin/ufw delete allow from $Old_IP to any port 9090 proto tcp
        /usr/sbin/ufw allow from $Current_IP to any port 9090 proto tcp
        echo $Current_IP > $LOGFILE
        echo iptables have been updated
    fi
fi