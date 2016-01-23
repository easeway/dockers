#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

init-local-env
init-dh-key
self-sign

test -f "$CA_CRT" || cp -f "$LOCAL_CA_CRT" "$CA_CRT"

OPTIONS=""

if ! iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -j MASQUERADE
fi

if [ -n "$VPN_ROUTES" ]; then
    for subnet in $VPN_ROUTES; do
        NETMASK=$(ipcalc -m $subnet | cut -d = -f 2)
        test -n "$NETMASK" || continue
        OPTIONS="$OPTIONS --push \"route ${subnet%/*} $NETMASK\""
    done
fi

eval /usr/sbin/openvpn \
    --writepid /var/run/openvpn.pid \
    --config "$CONFIG_FILE" \
    --server ${VPN_SUBNET:-10.8.0.0} ${VPN_NETMASK:-255.255.255.0} \
    --port ${VPN_PORT:-1194} \
    --dh ${DHKEY_FILE} \
    --ifconfig-pool-persist $BASE_DIR/ipp.txt \
    --client-to-client \
    $OPTIONS $VPN_OPTIONS
