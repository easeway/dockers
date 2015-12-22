#!/bin/bash

. /opt/openvpn/lib/mgmt.sh

stop-server() {
    local pid=$(pidof openvpn) newpid
    test -n "$pid" || return
    for ((a=1; a<5; a=a+1)); do
        killall openvpn
        sleep 1
        newpid=$(pidof openvpn) || break
        test "$newpid" == "$pid" || break
    done

    if [ "$newpid" == "$pid" ]; then
        killall -9 openvpn
        sleep 1
        newpid=$(pidof openvpn)
    fi
    test "$newpid" != "$pid"
}

wait-server-start() {
    for ((a=1; a<5; a=a+1)); do
        pidof openvpn && return
        sleep 1
    done
    false
}

ctl-restart() {
    if ! stop-server; then
        echo "500 Internal Server Error"
        echo "Unable to stop service"
    elif ! wait-server-start; then
        echo "500 Internal Server Error"
        echo "Fail to start service"
    fi
}

ctl-sign() {
    local cert csr="/tmp/ctl-$$.csr"
    cat >"$csr"
    cert=$(openssl ca -batch -days $CERT_DAYS} \
        -in "$csr" -config "$KEY_CONFIG")
    if [ $? -eq 0 ]; then
        echo "200 OK"
    else
        echo "400 Bad Request"
    fi
    rm -f "$csr"
    echo "$cert"
}

save-cert() {
    local crt="/tmp/ctl-$$.crt" dest="$CERT_DIR/$1.crt"
    cat >"$crt"
    if grep "BEGIN CERTIFICATE" "$crt" >/dev/null 2>&1 && \
        grep "END CERTIFICATE" "$crt" >/dev/null 2>&1 ; then
        mv -f "$crt" "$dest"
        cat "$dest" >&2
        echo "CERT UPDATED $1" >&2
        echo "200 OK"
    else
        rm -f "$crt"
        echo "400 Bad Request"
        echo "Invalid certificate file"
    fi
}

bad-request() {
    echo "400 Bad Request"
}

read
case "$REPLY" in
    restart) ctl-restart ;;
    sign) ctl-sign ;;
    ca-cert) save-cert ca ;;
    cert) save-cert local ;;
    *) bad-request ;;
esac
