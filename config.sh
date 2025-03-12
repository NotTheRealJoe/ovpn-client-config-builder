#!/bin/bash
# Copy this file to config.sh and edit if the defaults are incorrect.

# EasyRSA paths
EASYRSA_BIN_PATH='/usr/share/easy-rsa'
EASYRSA_INSTALLED_PATH='/etc/openvpn/easyrsa'

# Config paths for tlscryptv2
TLSCRYPTV2_DIR='/etc/openvpn'
TLSCRYPTV2_SERVER_KEY='/etc/openvpn/tlscryptv2.pem'

# Remote configuration
# Enter remote in the following format: <server> <port_number> <proto (tcp/udp)>
OPENVPN_REMOTE="foco.joet.co 1194 udp"
