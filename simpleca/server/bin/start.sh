#!/bin/bash

. /opt/ca/lib/mgmt.sh

respawn() {
    while true; do
        test -f /var/run/start.pause || $@
        sleep 1
    done
}

server-ctl() {
    rm -f /var/run/ctl.sock
    socat UNIX-LISTEN:/var/run/ctl.sock,fork,user=lighttpd,group=lighttpd \
          SYSTEM:/opt/ca/bin/ctl.sh
}

start-server() {
    init-ca
    respawn /usr/sbin/lighttpd -D -f /opt/ca/etc/lighttpd.conf &
    respawn server-ctl
}

start-client() {
    request-cert "$@"
}

usage() {
cat <<EOF
Run as CA Authority:
    ./start.sh
Run to request a certificate
    ./start.sh server-ip
EOF
exit 2
}

if [ "$1" == "help" -o "$1" == "--help" ]; then
    usage
elif [ -z "$1" ]; then
    start-server
else
    start-client "$@"
fi
