# ELK stack based on Alpine Linux

This is a very small ElasticSearch + Logstash + Kibana

## Launch

```
docker run -p 8080:80 -d easeway/elk:latest
```

ElasticSearch runs with data mapped to `/data`.
Kibana is listening on port `80` internally.
The following input plug-ins are enabled for Logstash:

- file: watches volume mapped to `/logs`
- tcp/udp: listening on port `8081`
- http: listening on port `8080`
- syslog: listening on standard port `514`
- gelf: listening on standard port `12201`

If you want this container to watch log files, launch like this:

```
docker run -p 8080:80 -v your-logs-dir:/logs easeway/elk:latest
```

And if you want to emit logs var tcp/udp/http/syslog/gelf,
remember to map the port number to your host, or directly access using container IP.

If you want to persist ElasticSearch data, map a data volume like:

```
docker run ... -v persist-data-dir:/data easeway/elk:latest
```

## Alter the default configurations

The default configurations are built into the container:

```
/etc
  |
  +--elasticsearch
  |  |
  |  +--elasticsearch.yml
  |  +--logging.yml
  +--kibana
  |  |
  |  +--kibana.yml
  +--logstash
     |
     +--input
     +--output
```

If you want to override the configuration,
simply map the configuration file into the container, like:

```
docker run -v my-es-config:/etc/elasiticsearch/elasticsearch.yml ...
docker run -v my-lumber-input:/etc/logstash/input ...
```

## Versions of the components

- ElasticSearch: 2.3.1
- Kibana: 4.5.0
- Logstash: 2.3.2

# HAVE FUN!
