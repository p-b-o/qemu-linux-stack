FROM --platform=linux/arm64 docker.io/arm64v8/debian:trixie

RUN apt update && apt install -y \
    bash-completion pciutils net-tools \
    iputils-ping util-linux procps htop
RUN apt install -y libfdt1
RUN echo host > /hostname
RUN mkdir /host
COPY --from=common resolv.conf /etc/resolv.conf
COPY --from=common init /init
