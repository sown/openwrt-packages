#!/bin/ash

echo "Creating table for one-ip-per-mac restrictions"

/usr/sbin/iptables -N one_ip_per_mac
/usr/sbin/iptables -A one_ip_per_mac -j REJECT
/usr/sbin/iptables -A FORWARD -i wlan0 -j one_ip_per_mac
