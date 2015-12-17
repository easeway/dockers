FROM centos:7
MAINTAINER EaseWay Hu easeway@gmail.com
RUN curl http://download.gluster.org/pub/gluster/glusterfs/3.6/LATEST/CentOS/glusterfs-epel.repo >/etc/yum.repos.d/glusterfs-epel.repo && \
    yum --setopt=tsflags=nodocs -y install glusterfs glusterfs-server glusterfs-fuse glusterfs-geo-replication glusterfs-cli glusterfs-api \
    yum -y clean all
EXPOSE 22 111 245 443 24007 2049 8080 6010 6011 6012 38465 38466 38468 38469 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162
ENTRYPOINT ["/usr/sbin/glusterd", "--no-daemon", "--log-file=-"]

