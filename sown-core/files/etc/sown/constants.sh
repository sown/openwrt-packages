#!/bin/ash

SOWN_CORE_SERVERS="AUTH_SOWN VPN_SOWN GW_SOWN AUTH_ECS VPN_ECS GW_ECS"

# Networks

NET_SOWN_v4=10.12.0.0/15
NET_SOWN_v6=2001:630:d0:f600::/55

# IP Addresses

IP_AUTH_SOWN_v4='10.13.0.252'
IP_AUTH_ECS_v4='152.78.189.82'

IP_VPN_SOWN_v4='10.13.0.253'
IP_VPN_ECS_v4='152.78.189.83'

IP_GW_SOWN_v4='10.13.0.254'
IP_GW_ECS_v4='152.78.189.84'

IP_OPENDNS_1_v4='208.67.222.222'
IP_OPENDNS_2_v4='208.67.220.220'

# File locations

AUTH_ECS_REACHABLE_FILE=/tmp/sown/reachable/auth_ecs
AUTH_SOWN_REACHABLE_FILE=/tmp/sown/reachable/auth_sown
VPN_ECS_REACHABLE_FILE=/tmp/sown/reachable/vpn_ecs
VPN_SOWN_REACHABLE_FILE=/tmp/sown/reachable/vpn_sown
GW_ECS_REACHABLE_FILE=/tmp/sown/reachable/gw_ecs
GW_SOWN_REACHABLE_FILE=/tmp/sown/reachable/gw_sown

ROOT_CRONTAB_PATH=/tmp/sown/crontabs/crond
ROOT_CRONTAB_FILE=$ROOT_CRONTAB_PATH/root

TUNNEL_STARTUP_LOG=/tmp/sown_tunnel_startup.log

