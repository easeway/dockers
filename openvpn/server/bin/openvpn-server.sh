#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

init-local-env
init-dh-key
self-sign

test -f "$CA_CRT" || cp -f "$LOCAL_CA_CRT" "$CA_CRT"

OPTIONS=""
if [ -n "$VPN_ROUTES" ]; then
    for rt in $VPN_ROUTES; do
        OPTIONS="$OPTIONS --push \"$rt\""
    done
fi

exec /usr/sbin/openvpn \
    --writepid /var/run/openvpn.pid \
    --config "$CONFIG_FILE" \
    --server ${VPN_SUBNET:-10.8.0.0} ${VPN_NETMASK:-255.255.255.0} \
    --port ${VPN_PORT:-1194} \
    --dh ${DHKEY_FILE} \
    --ifconfig-pool-persist $BASE_DIR/ipp.txt \
    --client-to-client \
    $OPTIONS $OPENVPN_OPTIONS
