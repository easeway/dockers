# Simple OpenVPN Server & Client

A very small (16MB) OpenVPN server and client image with automated certificate management.

## Details

This is OpenVPN server and client for you without worrying about the complicated certificates and configurations. The main purpose is to setup network tunnels on top of a few subnets which are difficult to inter-connected. Let's get started in a very simple way:

On your server:

```
docker run -d --net=host --cap-add=NET_ADMIN easeway/openvpn
```

The purpose using `--net=host` is to create a VPN for your hosts. Similarly, if you want to create a VPN for a set of containers, remove '--net=host' and share this network namespace with other containers.

And on your client:

```
docker run -d --net=host --cap-add=NET_ADMIN easeway/openvpn SERVER-IP
```

By default, the OpenVPN server manages CA, and the client will ask server to issue certificate on the fly - that's how you don't need to bother certificates. Of course, this is insecure, because of the purpose.

There are a few environment variables you can use the override the default configuration:

- `VPN_PORT`: the default listening port 1194.
- `VPN_SUBNET`: the default is 10.8.0.0
- `VPN_NETMASK`: the default is 255.255.255.0
- `VPN_ROUTES`: a list of CIDR blocks to be routed by server
- `VPN_OPTIONS`: other command-line arguments appended to `openvpn`.
