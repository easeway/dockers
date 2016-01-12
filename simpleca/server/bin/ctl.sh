#!/bin/bash

. /opt/ca/lib/mgmt.sh

ctl-sign() {
    local ip=$1 qs=$2
    local cert csr="/tmp/ctl-$$.csr" cnf="/tmp/ctl-$$.cnf"
    cat >"$csr"
cat <<EOF >"$cnf"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = $ip
EOF
    for q in ${qs//\&/ }; do
        echo "$q" >>"$cnf"
    done
    cat "$cnf" >&2
    cert=$(openssl x509 -req -in "$csr" \
        -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
        -days $CERT_DAYS -extensions v3_req -extfile "$cnf")
    if [ $? -eq 0 ]; then
        echo "200 OK"
    else
        echo "400 Bad Request"
    fi
    rm -f "$csr" "$cnf"
    echo "$cert"
}

bad-request() {
    echo "400 Bad Request"
}

read
case "$REPLY" in
    sign\ *) ctl-sign ${REPLY:5};;
    *) bad-request ;;
esac
