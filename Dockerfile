FROM docker.io/debian:trixie

RUN apt update && apt install -y \
build-essential \
git \
gcc-x86-64-linux-gnu \
g++-x86-64-linux-gnu \
bison \
flex \
bc \
libssl-dev \
python3 \
rsync \
cpio \
wget \
qemu-user \
gdb-multiarch \
cgdb
RUN apt update && apt install -y \
e2fsprogs libarchive13t64 locales-all
RUN apt update && apt install -y \
libgnutls28-dev
RUN apt update && apt install -y ccache
RUN apt update && apt install -y clang-tools
RUN ln -s /usr/bin/intercept-build-* /usr/bin/intercept-build
RUN apt update && apt install -y \
libelf-dev
RUN apt update && \
apt install -y uuid-dev python-is-python3 nasm acpica-tools

# Need recent uftrace, which implements dump --srcline (81fe3b94782)
# uftrace v0.19 will contain the needed changes.
RUN apt update && apt install -y pigz
RUN cd /tmp && git clone https://github.com/namhyung/uftrace && \
cd uftrace && git checkout 81fe3b94782 && \
./configure && make -j $(nproc) && make install && rm -rf /tmp/*

# wrap compilers to call ccache, keep frame pointer, and enable debug info
RUN mkdir /opt/compiler_wrappers && \
    for c in gcc g++ x86_64-linux-gnu-gcc x86_64-linux-gnu-g++; do \
        f=/opt/compiler_wrappers/$c && \
        echo '#!/usr/bin/env bash' >> $f && \
        echo 'args="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -g"' >> $f && \
        echo '[ "$CC_NO_DEBUG_MACROS" == "1" ] || args="$args -ggdb3"' >> $f && \
        echo '[[ "$*" =~ ' -E ' ]] && args=' >> $f && \
        echo "exec ccache /usr/bin/$c \"\$@\" \$args" >> $f && \
        chmod +x $f;\
    done
ENV PATH=/opt/compiler_wrappers:$PATH

ENV LANG=en_US.UTF-8
