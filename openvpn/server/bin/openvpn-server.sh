#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

init-local-env
init-dh-key
self-sign

test -f "$CA_CRT" || cp -f "$LOCAL_CA_CRT" "$CA_CRT"

OPTIONS=""
IF_IN_RULES=""

if [ -n "$VPN_ROUTES" ]; then
    for subnet in $VPN_ROUTES; do
        OPTIONS="$OPTIONS --push \"route ${subnet%/*} $NETMASK\""
        IF=$(ip -o addr show to $subnet | cut -d ' ' -f 2)
        NETMASK=$(ipcalc -m $subnet | cut -d = -f 2)
        if [ -n "$IF" -a -n "$NETMASK" ]; then
            echo "Routing $subnet via $IF"
            if ! iptables -t nat -C POSTROUTING -o $IF -j MASQUERADE 2>/dev/null; then
                IF_IN_RULES="$IF_IN_RULES $IF"
                iptables -t nat -A POSTROUTING -o $IF -j MASQUERADE
            fi
        else
            echo "WARNING interface not found for routing $subnet" >&2
        fi
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

RET=$?

for IF in $IF_IN_RULES; do
    iptables -t nat -D POSTROUTING -o $IF -j MASQUERADE 2>/dev/null || true
done

exit $RET
