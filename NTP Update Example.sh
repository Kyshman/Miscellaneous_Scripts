# Remember ntpdate is deprecated
# Instead of ntpdate (which is deprecated), use
#
# sudo service ntp stop
# sudo ntpd -gq
# sudo service ntp start
#
# The -gq tells the ntp daemon to correct the time regardless of the offset (g) and exit immediately (q) after setting the time.

( /etc/init.d/ntp stop
until ping -nq -c3 8.8.8.8; do
   echo "Waiting for network..."
done
ntpdate -s time.nist.gov
/etc/init.d/ntp start )&