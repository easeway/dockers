# A Simple CA Authority

This is a simple CA authority for auto-issue certificates.

Run as server (CA authority):

```
docker run -d -v local-cert-dir:/var/lib/ca easeway/simpleca
```

To retrieve CA certificate:

```
wget http://ip/certs/ca.pem
```

From a client to request a certificate

```
docker run --rm -v local-cert-dir:/var/lib/ca easeway/simpleca server-ip CommonName AltName1=Val1 AltName2=Val2 ...
```

Here, `local-cert-dir` is a local directory contains private keys and certificates.
A sub-folder `keys` is created for private keys and `certs` is created for certificates.

`AltName?` can be `IP.2=AnotherIP`, `DNS.1=dns1`, `DNS.2=dns2`.
Please note, `IP.1` is automatically determined by server when receiving the HTTP request.
