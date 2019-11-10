#!/bin/ash

echo "White listing DNS and BOOTP traffic"

/usr/sbin/iptables -A FORWARD -i wlan0 -p udp --dport 67 -j ACCEPT
/usr/sbin/iptables -A FORWARD -i wlan0 -p udp --dport 53 -j ACCEPT
