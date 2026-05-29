

FROM docker.io/debian:trixie

# https://github.com/quic/buildroot/commits/bcain/to-upstream
RUN apt update && apt install -y wget e2fsprogs
RUN cd /tmp && \
wget -q https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/23.1.0-rc1/rootfs.ext2.gz && \
gzip -d *.gz && \
mkdir /rootfs && \
debugfs -R "rdump / /rootfs" /tmp/rootfs.ext2 && \
rm -rf /tmp/*

COPY --from=common init /rootfs/init
RUN rm /rootfs/etc/resolv.conf
COPY --from=common resolv.conf /rootfs/etc/resolv.conf
RUN echo host > /rootfs/hostname

RUN mke2fs -t ext4 -d /rootfs /tmp/rootfs.ext4.tmp 1g && \
cp --sparse=always /tmp/rootfs.ext4.tmp /rootfs.ext4 && \
rm -rf /tmp/*
