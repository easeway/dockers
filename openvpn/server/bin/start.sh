#!/bin/bash

respawn() {
    while true; do
        test -f /var/run/start.pause || $@
        sleep 1
    done
}

server-ctl() {
    rm -f /var/run/ctl.sock
    socat UNIX-LISTEN:/var/run/ctl.sock,fork,user=lighttpd,group=lighttpd \
          SYSTEM:/opt/openvpn/bin/ctl.sh
}

start-server() {
    respawn /usr/sbin/lighttpd -D -f /opt/openvpn/etc/lighttpd.conf &
    respawn /opt/openvpn/bin/openvpn-server.sh &
    respawn server-ctl
}

start-client() {
    exec /opt/openvpn/bin/openvpn-client.sh "$@"
}

usage() {
cat <<EOF
Run as OpenVPN Server:
    ./start.sh
Run as a client
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
