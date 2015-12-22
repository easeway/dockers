#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

SERVER="$1"
shift

USE_LOCAL_CA=
for a in $@ ; do
    case "$a" in
        --local-ca)
            USE_LOCAL_CA=yes
            ;;
    esac
done

set -e

init-local-env

if [ -n "$USE_LOCAL_CA" ]; then
    echo "USE LOCAL CA"
    self-sign
    push-certs "$SERVER"
else
    echo "REQUEST CERTIFICATE"
    request-certs "$SERVER"
fi

exec /usr/sbin/openvpn \
    --writepid /var/run/openvpn.pid \
    --client \
    --config "$CONFIG_FILE" \
    --remote "$SERVER" ${VPN_PORT:-1194} \
    $OPTIONS $OPENVPN_OPTIONS
