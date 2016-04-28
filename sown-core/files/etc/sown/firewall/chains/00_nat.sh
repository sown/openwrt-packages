#!/bin/ash

echo "Loading NAT"

/usr/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/usr/sbin/iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

