#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

SERVER="$1"
shift

USE_LOCAL_CA=
WAIT_SERVER_READY=
for a in $@ ; do
    case "$a" in
        --local-ca)
            USE_LOCAL_CA=yes
            ;;
        --wait=*)
            WAIT_SERVER_READY=${a#--wait=}
            ;;
    esac
done

set -e

init-local-env
test -z "$WAIT_SERVER_READY" || \
    wait-server-ready "$SERVER" $WAIT_SERVER_READY

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
