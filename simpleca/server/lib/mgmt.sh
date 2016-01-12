test -z "$DEBUG" || set -x

CERTS_DIR=/var/lib/ca/certs
KEYS_DIR=/var/lib/ca/keys
CA_CERT=$CERTS_DIR/ca.pem
CA_KEY=$KEYS_DIR/ca-key.pem
: ${CERT_DAYS:=3650}

init-dir() {
    mkdir -p $CERTS_DIR $KEYS_DIR
    chmod 0700 $KEYS_DIR
}

init-ca() {
    init-dir
    if ! [ -f "$CA_CERT" -a "$CA_KEY" ]; then
        openssl genrsa -out $CA_KEY 2048
        openssl req -x509 -new -nodes \
            -key $CA_KEY -days $CERT_DAYS -out $CA_CERT \
            -subj "/CN=SimpleCA"
    fi
}

request-cert() {
    local server=$1 name=$2 qs=
    local csr=$CERTS_DIR/$name.csr
    local crt=$CERTS_DIR/$name.pem
    local key=$KEYS_DIR/${name}-key.pem
    if test -f "$key" && openssl x509 -in "$crt" -text 2>/dev/null; then
        return
    fi
    shift; shift
    for q in $@; do
        test -z "$qs" || qs="$qs&"
        qs="$qs$q"
    done
    echo "Requesting certificate ..."
    init-dir
    openssl genrsa -out "$key" 2048
    openssl req -new -key "$key" -out "$csr" -subj "/CN=$name"
    curl -v -XPOST --data-binary "@$csr" \
        -H 'Content-type: text/plain' \
        -H Expect: \
        "http://$server/op/ctl/sign?$qs" > $crt
    openssl x509 -in "$crt" -text
}
