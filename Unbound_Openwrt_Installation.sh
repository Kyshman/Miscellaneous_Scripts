#!/bin/sh
# Steps to configure unbound on OpenWrt with dnsmasq for dynamic DNS
# Note:  Clarity of instruction is favored over script speed or robustness.
#        It is not idempotent.

# Show commands as executed, error out on failure or undefined variables
set -eux

# Note the local domain (Network -> DHCP & DNS -> General Settings)
lan_domain=$(uci get 'dhcp.@dnsmasq[0].domain')

# Note the LAN network address (Network -> Interfaces -> LAN -> IPv4 address)
lan_address=$(uci get network.lan.ipaddr)

# Update the package list (System -> Software -> Update lists)
opkg update

# Install unbound (System -> Software -> Find package: unbound -> Install)
opkg install unbound # Ignore error that it can't listen on port 53

# Move dnsmasq to port 53535 where it will still serve local DNS from DHCP
# Network -> DHCP & DNS -> Advanced Settings -> DNS server port to 53535
uci set 'dhcp.@dnsmasq[0].port=53535'

# Configure dnsmasq to send a DNS Server DHCP option with its LAN IP
# since it does not do this by default when port is configured.
uci add_list "dhcp.lan.dhcp_option=option:dns-server,$lan_address"

# Configure Unbound from unbound.conf, instead of generating it from UCI
# Services -> Recursive DNS -> Manual Conf
uci set 'unbound.@unbound[0].manual_conf=1'

# Save & Apply (will restart dnsmasq, DNS unreachable until unbound is up)
uci commit

# Allow unbound to query dnsmasq on the loopback address
# by adding 'do-not-query-localhost: no' to server section
sed -i '/^server:/a\	do-not-query-localhost: no' /etc/unbound/unbound.conf

# Convert the network address to a Reverse DNS domain
# https://en.wikipedia.org/wiki/Reverse_DNS_lookup
case $(uci get network.lan.netmask) in
    255.255.255.0) ip_to_rdns='\3.\2.\1.in-addr.arpa' ;;
    255.255.0.0) ip_to_rdns='\2.\1.in-addr.arpa' ;;
    255.0.0.0) ip_to_rdns='\1.in-addr.arpa' ;;
    *) echo 'More complex rDNS configuration required.' >&2 ; exit 1 ;;
esac
lan_rdns_domain=$(echo "$lan_address" | \
    sed -E "s/^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/$ip_to_rdns/")

# Check if the local addresses are in a private address range (very common)
case "$lan_address" in
    0.*) ip_to_priv_rdns='0.in-addr.arpa.' ;;
    10.*) ip_to_priv_rdns='10.in-addr.arpa.' ;;
    169.254.*) ip_to_priv_rdns='254.169.in-addr.arpa.' ;;
    172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) ip_to_priv_rdns='\2.172.in-addr.arpa.' ;;
    192.0.2.*) ip_to_priv_rdns='2.0.192.in-addr.arpa.' ;;
    192.168.*) ip_to_priv_rdns='168.192.in-addr.arpa.' ;;
    198.51.100.*) ip_to_priv_rdns='100.51.198.in-addr.arpa.' ;;
    203.0.113.*) ip_to_priv_rdns='113.0.203.in-addr.arpa.' ;;
esac
if [ -n "${ip_to_priv_rdns-}" ] ; then
    # Disable default "does not exist" reply for private address ranges
    # by adding 'local-zone "$lan_domain" nodefault' to server section
    # Note that this must be on RFC 1918/5735/5737 boundary,
    # this is only equal to $lan_rdns_domain when netmask covers whole range.
    lan_priv_rdns_domain=$(echo "$lan_address" | \
        sed -E "s/^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/$ip_to_priv_rdns/")
    sed -i "/^server:/a\	local-zone: \"$lan_priv_rdns_domain\" nodefault"  \
        /etc/unbound/unbound.conf
fi

# Ignore DNSSEC chain of trust for the local domain
# by adding 'domain-insecure: "$lan_domain"' to server section
sed -i "/^server:/a\	domain-insecure: \"$lan_domain\"" /etc/unbound/unbound.conf

# Ignore DNSSEC chain of trust for the local reverse domain
# by adding 'domain-insecure: "$lan_rdns_domain"' to server section
sed -i "/^server:/a\	domain-insecure: \"$lan_rdns_domain\"" /etc/unbound/unbound.conf

# Add a forward zone for the local domain to forward requests to dnsmasq
cat >> /etc/unbound/unbound.conf <<DNS_FORWARD_ZONE
forward-zone:
	name: "$lan_domain"
	forward-addr: 127.0.0.1@53535
DNS_FORWARD_ZONE

# Add a forward zone for the local reverse domain to forward requests to dnsmasq
cat >> /etc/unbound/unbound.conf <<RDNS_FORWARD_ZONE
forward-zone:
	name: "$lan_rdns_domain"
	forward-addr: 127.0.0.1@53535
RDNS_FORWARD_ZONE

# Optionally enable DNS Rebinding protection by uncommenting private-address
# configuration and adding 'private-domain: "$lan_domain"' to server section
sed -E -i \
    -e 's/(# )?private-address:/private-address:/' \
    -e "/^server:/a\	private-domain: \"$lan_domain\"" \
    /etc/unbound/unbound.conf

# Restart (or start) unbound (System -> Startup -> unbound -> Restart)
/etc/init.d/unbound restart