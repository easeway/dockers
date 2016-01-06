test -z "$DEBUG" || set -x

export CERT_DAYS=${VPN_CERT_DAYS:-3650}

export BASE_DIR=/var/lib/openvpn
export CERT_DIR=$BASE_DIR/certs
export KEYS_DIR=$BASE_DIR/keys

LOCAL_KEY=$KEYS_DIR/local.key
LOCAL_CRT=$CERT_DIR/local.crt
LOCAL_CSR=$CERT_DIR/local.csr
LOCAL_CA_KEY=$KEYS_DIR/local-ca.key
LOCAL_CA_CRT=$CERT_DIR/local-ca.crt
CA_CRT=$CERT_DIR/ca.crt
CA_DB=$BASE_DIR/index.txt
CA_DB_ATTR=$BASE_DIR/index.txt.attr
CA_SN=$BASE_DIR/serial
KEY_CONFIG=/opt/openvpn/etc/openssl-1.0.cnf
DHKEY_SIZE=2048
DHKEY_FILE=$KEYS_DIR/dh${DHKEY_SIZE}.pem

CONFIG_FILE=/opt/openvpn/etc/openvpn.conf

init-local-env() {
    test -e /dev/net/tun || mkdir -p /dev/net && mknod /dev/net/tun c 10 200

    mkdir -p -m 0700 "$KEYS_DIR"
    mkdir -p -m 0755 "$CERT_DIR"

    test -f "$CA_DB" || touch "$CA_DB"
    test -f "$CA_DB_ATTR" || echo 'unique_subject = no' >"$CA_DB_ATTR"
    test -f "$CA_SN" || echo 01 >"$CA_SN"

    test -f "$LOCAL_CA_CRT" || \
        openssl req -days $CERT_DAYS -nodes -new -x509 \
            -keyout "$LOCAL_CA_KEY" -out "$LOCAL_CA_CRT" \
            -subj "/CN=$(hostname)" && \
        chmod 0600 "$LOCAL_CA_KEY"
    test -f "$LOCAL_KEY" || \
        openssl req -days $CERT_DAYS -nodes -new \
            -keyout "$LOCAL_KEY" -out "$LOCAL_CSR" \
            -subj "/CN=$(hostname)" && \
        chmod 0600 "$LOCAL_KEY"
}

init-dh-key() {
    test -f "$DHKEY_FILE" || \
        openssl dhparam -out "$DHKEY_FILE" $DHKEY_SIZE
}

self-sign() {
    test -f "$LOCAL_CRT" || \
        openssl ca -batch -days $CERT_DAYS \
            -out "$LOCAL_CRT" -in "$LOCAL_CSR" \
            -config "$KEY_CONFIG"
}

push-certs() {
    local server="$1"
    curl -s -S http://$server/certs/local.csr >/tmp/server.csr
    openssl ca -batch -days $CERT_DAYS \
        -out /tmp/server.crt -in /tmp/server.csr \
        -config "$KEY_CONFIG"
    cp -f "$LOCAL_CA_CRT" "$CA_CRT"
    curl -s -S http://$server/op/ctl/ca-cert --data-binary "@$CA_CRT" -H Expect:
    curl -s -S http://$server/op/ctl/cert --data-binary @/tmp/server.crt -H Expect:
    curl -s -S http://$server/op/ctl/restart
}

request-certs() {
    local server="$1"
    curl -s -S http://$server/op/ctl/sign --data-binary "@$LOCAL_CSR" >"$LOCAL_CRT"
    curl -s -S http://$server/certs/ca.crt >"$CA_CRT"
}

wait-server-ready() {
    local server="$1" timeout=$2 start end state left
    test $timeout -gt 0 2>/dev/null || return 0
    echo "Wait server for $timeout seconds ..."
    start=$(date +%s)
    end=$(($start+$timeout))
    while [ $(date +%s) -le $end ]; do
        state=$(curl -s -m 5 http://$server/op/state || true)
        if [ "$state" == "up" ]; then
            echo "Server is READY!"
            return 0
        fi
        left=$(($end-$(date +%s)))
        test $left -le 0 2>/dev/null || echo "$left"
    done
    echo "Waiting for server timeout!"
    return 1
}
