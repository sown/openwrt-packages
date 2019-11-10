#!/bin/ash

echo "Forbidding private subnet access"

/usr/sbin/iptables -N private_subnets

/usr/sbin/iptables -A private_subnets -d 192.168.0.0/16 -j REJECT
/usr/sbin/iptables -A private_subnets -d 172.16.0.0/12 -j REJECT

# Sown subnets are okay
/usr/sbin/iptables -A private_subnets -d 10.13.0.0/16 -j ACCEPT
/usr/sbin/iptables -A private_subnets -d 10.5.0.0/16 -j ACCEPT
/usr/sbin/iptables -A private_subnets -d 10.0.0.0/8 -j REJECT

/usr/sbin/iptables -A FORWARD -j private_subnets

