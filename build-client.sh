#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

if [ "$1" == "" ]; then
	echo "Enter the client name as the first argument"
	exit 1
fi

if [[ "$USER" != "root" ]]; then
	echo "This script must be run as root in order to access EasyRSA PKI files."
	exit 2
fi

# Check for and load config file
if [ -f "$SCRIPT_DIR/config.sh" ]; then
	echo "Using config file $SCRIPT_DIR/config.sh"
	source "$SCRIPT_DIR/config.sh"
elif [ -f "$SCRIPT_DIR/config.sh.default" ]; then
	echo "Using config file $SCRIPT_DIR/config.sh.default"
	source "$SCRIPT_DIR/config.sh.default"
else
	echo "Config file not found."
	exit 3
fi

# Check all paths that will be generated with the client name to make sure they don't already exist
EASYRSA_BLOCKER_PATHS=(
	"$EASYRSA_INSTALLED_PATH/pki/reqs/$1.req"
	"$EASYRSA_INSTALLED_PATH/pki/issued/$1.crt"
	"$EASYRSA_INSTALLED_PATH/pki/private/$1.key"
	"$SCRIPT_DIR/$1.ovpn"
)
for BLOCKER in "${EASYRSA_BLOCKER_PATHS[@]}"; do
	if [ -f "$BLOCKER" ]; then
		echo "Unable to continue creation because EasyRSA already knows of a profile by that name."
		echo "Found: $BLOCKER"
		echo "To completely remove this profile, you must:"
		echo "  (1): Revoke the associated certificate:"
		echo "       cd \"$EASYRSA_INSTALLED_PATH\""
		echo "       source vars"
		echo "       \"$EASYRSA_BIN_PATH/easyrsa\" revoke \"$1\""
		echo "       \"$EASYRSA_BIN_PATH/easyrsa\" gen-crl"
		echo "  (2): Copy the generated CRL file (\"$EASYRSA_INSTALLED_PATH/pki/crl.pem\") to a place where OpenVPN will"
		echo "       look for it. See the \"crl-verify\" option in your server's config file for the correct location to"
		echo "       place the CRL."
		echo "  (3): Remove any/all of the following files:"
		echo "       ${EASYRSA_BLOCKER_PATHS[*]}"
		exit 4
	fi
done

function append-wrapped-from-file {
	printf "<%s>\n%s\n</%s>\n" "$1" "$(cat "$2")" "$1" >> "$3"
}

# Load the easyrsa vars
EASYRSA="$EASYRSA_BIN_PATH/easyrsa"
if ! [ -f "$EASYRSA" ]; then
	echo "Failed to find easyrsa binary in easyrsa installation path. Please check easyrsa installation and EASYRSA_INSTALLED_PATH in config file."
	exit 5
fi
if ! cd "$EASYRSA_INSTALLED_PATH"; then
	echo "Failed to cd to easyrsa installation path. Please check EASYRSA_INSTALLED_PATH in config file."
	exit 5
fi

# Run easyrsa to build a client
"$EASYRSA" build-client-full "$1" nopass

# Build the client config file
cd "$SCRIPT_DIR" || exit 99

{ echo "# $1"
	echo "client"
	echo "tls-client"
	echo "dev tun"
	echo "remote $OPENVPN_REMOTE"
} >> "$1.ovpn"

append-wrapped-from-file "ca" "$EASYRSA_INSTALLED_PATH/pki/ca.crt" "$1.ovpn"
append-wrapped-from-file "cert" "$EASYRSA_INSTALLED_PATH/pki/issued/$1.crt" "$1.ovpn"
append-wrapped-from-file "key" "$EASYRSA_INSTALLED_PATH/pki/private/$1.key" "$1.ovpn"
append-wrapped-from-file "tls-crypt" "$TLSCRYPT_PATH" "$1.ovpn"
