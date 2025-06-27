FROM --platform=linux/arm64 docker.io/arm64v8/alpine:3.22

RUN apk add qemu-system-aarch64
RUN apk add bash lsblk
RUN echo host > /hostname
RUN mkdir /host
COPY --from=common resolv.conf /etc/resolv.conf
COPY --from=common init /init
