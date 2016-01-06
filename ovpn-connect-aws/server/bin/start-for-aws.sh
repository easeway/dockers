#!/bin/bash

fatal() {
    echo "$@" >&2
    exit 1
}

test -z "$DEBUG" || set -x

: ${AWS_IMAGE:=ami-0eacc46e}  # CoreOS-stable-835.9.0-hvm
: ${AWS_INSTANCE_TYPE:=t2.nano}
test -n "$AWS_SUBNET" || fatal 'AWS_SUBNET not specified'

CLI_OPTS="$AWS_OPTIONS"
test -z "$AWS_REGION" || CLI_OPTS="$CLI_OPTS --region $AWS_REGION"
EC2_RUN_OPTS=
test -z "$AWS_SECURITY_GROUPS" || EC2_RUN_OPTS="--security-group-ids $AWS_SECURITY_GROUPS $EC2_RUN_OPTS"
test -z "$AWS_KEY" || EC2_RUN_OPTS="--key-name $AWS_KEY $EC2_RUN_OPTS"

SERVER_OPTS=
test -z "$VPN_PORT" || SERVER_OPTS="$SERVER_OPTS -e VPN_PORT=$VPN_PORT"
test -z "$VPN_SUBNET" || SERVER_OPTS="$SERVER_OPTS -e VPN_SUBNET=$VPN_SUBNET"
test -z "$VPN_NETMASK" || SERVER_OPTS="$SERVER_OPTS -e VPN_NETMASK=$VPN_NETMASK"
test -z "$VPN_ROUTES" || SERVER_OPTS="$SERVER_OPTS -e VPN_ROUTES=\"$VPN_ROUTES\""
test -z "$VPN_SERVER_OPTIONS" || SERVER_OPTS="$SERVER_OPTS -e VPN_OPTIONS=\"$VPN_SERVER_OPTIONS\""

if [ -f $HOME/.ssh/id_rsa.pub ]; then
    SSH_AUTHORIZED_KEY=$(cat $HOME/.ssh/id_rsa.pub)
fi

cat <<EOF >/var/run/aws/userdata
#!/bin/bash
set -x
SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
test -z "\$SSH_AUTHORIZED_KEY" || (mkdir -p /home/core/.ssh && echo "\$SSH_AUTHORIZED_KEY" >>/home/core/.ssh/authorized_keys)
systemctl enable docker.service
systemctl start docker
docker pull easeway/openvpn:latest
docker run --restart=always --net=host --cap-add=NET_ADMIN -d $SERVER_OPTS easeway/openvpn:latest
EOF

aws-cli() {
    aws --output json $CLI_OPTS $@
}

aws-ec2() {
    aws-cli ec2 $@ $AWS_EC2_OPTIONS
}

INSTANCE_ID=
INSTANCE_ID=$(aws-ec2 run-instances \
        --image-id $AWS_IMAGE \
        --count 1 \
        --instance-type $AWS_INSTANCE_TYPE \
        --subnet-id $AWS_SUBNET \
        --user-data file:///var/run/aws/userdata $EC2_RUN_OPTS \
    | jq -r -c -M .Instances[0].InstanceId) || fatal 'Unable to launch EC2 instance'
test -n "$INSTANCE_ID" || fatal 'Unable to retrieve launched EC2 instance Id'
mkdir -p /var/run/aws
echo -n "$INSTANCE_ID" >/var/run/aws/server-instance-id

delete-instance() {
    test -z "$INSTANCE_ID" || aws-ec2 terminate-instances --instance-ids $INSTANCE_ID
}

trap delete-instance EXIT

STATE_CODE=
for ((i=0; i<300; i=i+1)); do
    STATE_CODE=$(aws-ec2 describe-instances --instance-ids "$INSTANCE_ID" --query Reservations[0].Instances[0].State.Code)
    test "$STATE_CODE" == "0" || break
    sleep 1
done
test "$STATE_CODE" == "16" || fatal 'Unable to start EC2 instance'

PUBLIC_IP=$(aws-ec2 describe-instances --instance-ids "$INSTANCE_ID" --query Reservations[0].Instances[0] | jq -c -r -M .PublicIpAddress)
test -n "$PUBLIC_IP" || fatal 'Unable to retrieve public IP of EC2 instance'
echo -n "$PUBLIC_IP" >/var/run/aws/server-public-ip

exec /opt/openvpn/bin/start.sh $PUBLIC_IP "$@"
