# OpenVPN On-demand for AWS

The OpenVPN server is created on-demand on AWS and the client establishes the
tunnel automatically.

## Usage

```
docker run -ti -e AWS_SUBNET=subnetId -e AWS_SECURITY_GROUPS=securityGroupId
    -v $HOME/.aws:/.aws       # for credentials used by AWS
    -v /tmp/aws:/var/run/aws  # for tracking AWS instance id
    --net=host
    --cap-add=NET_ADMIN
    --rm
    easeway/ovpn-connect-aws --wait=180
```

The above command establishes an OpenVPN tunnel into AWS subnet `subnetId`.
Please note, the volume mapped to `/var/run/aws` is important:

- `/var/run/aws/server-instance-id`: keep the instance id of OpenVPN server VM
- `/var/run/aws/server-public-ip`: the public IP of OpenVPN server

It's necessary to do housekeeping removing the OpenVPN server using
`server-instance-id` when no longer needed.

There are a few more environment variables:

- `AWS_KEY`: key pair name if you want to ssh into OpenVPN server VM
- `AWS_IMAGE`: AMI image for VM, default is `ami-0eacc46e` which is `CoreOS-stable-835.9.0-hvm`
- `AWS_INSTANCE_TYPE`: default is `t2.nano`
