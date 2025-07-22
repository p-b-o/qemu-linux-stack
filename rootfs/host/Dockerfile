# Use ubuntu (and not debian) as it comes with frame pointers enabled by default
# https://ubuntu.com/blog/ubuntu-performance-engineering-with-frame-pointers-by-default
FROM --platform=linux/amd64 docker.io/amd64/ubuntu:24.04

RUN apt update && apt install -y \
    bash-completion pciutils net-tools \
    iputils-ping util-linux procps htop
RUN apt update && apt install -y strace
RUN apt update && apt install -y kmod
RUN echo host > /hostname
RUN mkdir /host
COPY --from=common resolv.conf /etc/resolv.conf
COPY --from=common init /init
