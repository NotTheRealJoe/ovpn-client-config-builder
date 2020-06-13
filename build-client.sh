#!/bin/bash

SCRIPT_DIR="$(dirname $(realpath "$BASH_SOURCE"))"

if [ "$1" == "" ]; then
	echo "Enter the client name as the first argument"
	exit 1
fi

# TODO: Check all paths that will be generated with the client name to make sure they don't already exist

# Check for and load config file
if [ -f "$SCRIPT_DIR/config.sh" ]; then
	echo "Using config file $SCRIPT_DIR/config.sh"
	source "$SCRIPT_DIR/config.sh"
elif [ -f "$SCRIPT_DIR/config.sh.default" ]; then
	echo "Using config file $SCRIPT_DIR/config.sh.default"
	source "$SCRIPT_DIR/config.sh.default"
else
	echo "Config file not found."
	exit 1
fi

# Load the easyrsa vars
EASYRSA="$EASYRSA_BIN_PATH/easyrsa"
cd "$EASYRSA_INSTALLED_PATH"

# Run easyrsa to build a client
"$EASYRSA" build-client-full "$1"


# Build the client config file
cd "$SCRIPT_DIR"

echo "$1" >> "$1.ovpn"
echo "tls-client" >> "$1.ovpn"

echo "<ca>" >> "$1.ovpn"
cat "$EASYRSA_INSTALLED_PATH/pki/ca.crt" >> "$1.ovpn"
echo "</ca>" >> "$1.ovpn"

echo "<cert>" >> "$1.ovpn"
cat "$EASYRSA_INSTALLED_PATH/pki/issued/$1.crt"
echo "</cert>" >> "$1.ovpn"

echo "<key>" >> "$1.ovpn"
cat "$EASYRSA_INSTALLED_PATH/pki/private/$1.key" >> "$1.ovpn"
echo "</key>" >> "$1.ovpn"

echo "<tls-auth>" >> "$1.ovpn"
cat "$TLSCRYPT_PATH" >> "$1.ovpn"
echo "</tls-auth>" >> "$1.ovpn"

echo "remote-cert-eku \"TLS Web Client Authentication\"" >> "$1.ovpn"
