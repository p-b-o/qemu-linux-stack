FROM docker.io/debian:trixie

RUN apt update && apt install -y \
build-essential \
binutils \
git \
gcc-aarch64-linux-gnu \
g++-aarch64-linux-gnu \
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
parallel \
cgdb
RUN apt update && apt install -y \
e2fsprogs libarchive13t64 locales-all
RUN apt update && apt install -y \
libgnutls28-dev
RUN apt update && apt install -y ccache
RUN apt update && apt install -y clang-tools
RUN ln -s /usr/bin/intercept-build-* /usr/bin/intercept-build
RUN apt update && apt install -y pigz

# Need recent uftrace, which implements:
# - dump --srcline (81fe3b94782)
# - fix for --time-range (5f347b2)
# - add realtime clock option for using with uftrace record (f57c29f)
# uftrace v0.20 will contain the needed changes.
RUN sed -e 's/Types: deb/Types: deb deb-src/' -i /etc/apt/sources.list.d/debian.sources
RUN apt update && apt build-dep -y uftrace
RUN cd /tmp && git clone https://github.com/namhyung/uftrace && \
cd uftrace && git checkout f57c29f && \
./configure && make -j $(nproc) && make install && rm -rf /tmp/*

RUN apt update && apt install -y libyajl-dev
RUN cd tmp && git clone https://github.com/p-b-o/chrome2fuchsia && \
cd chrome2fuchsia && git checkout 07977568bf30fa724f9ed8960918946a29acc7bd && \
make && mv c2f /usr/bin && rm -rf /tmp/*

RUN apt update && apt install -y black mypy node-typescript
RUN wget -q https://github.com/biomejs/biome/releases/download/@biomejs/biome@2.4.5/biome-linux-x64 && \
mv biome-linux-x64 /usr/bin/biome && chmod +x /usr/bin/biome

# Qualcomm SDK, needed to have toolchain to build H2
# Also, H2 relies on hexagon-sim to retrieve some offsets
RUN apt update && apt install -y aria2 unzip
ENV HEXAGON_SDK_VERSION 6.6.0.0
RUN cd /tmp && \
aria2c -x 16 https://softwarecenter.qualcomm.com/api/download/software/sdks/Hexagon_SDK/Linux/Debian/${HEXAGON_SDK_VERSION}/Hexagon_SDK_Linux.zip && \
unzip Hexagon_SDK_Linux.zip "Hexagon_SDK/${HEXAGON_SDK_VERSION}/tools/HEXAGON_Tools/*/Tools/*" && \
mv Hexagon_SDK/${HEXAGON_SDK_VERSION}/tools/HEXAGON_Tools/*/Tools/ /opt/hexagon-sdk && \
rm -rf /tmp/*
ENV /opt/hexagon-sdk/bin/hexagon-clang --version
# hexagon-sim dependency
RUN apt update && apt install -y libncurses6
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libncurses.so.6 libncurses.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libpanel.so.6 libpanel.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libtinfo.so.6 libtinfo.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libform.so.6 libform.so.5

# latest clang and lldb
RUN apt update && apt install -y gpg lsb-release
ENV LLVM_VERSION=22
RUN cd /tmp && wget https://apt.llvm.org/llvm.sh && bash ./llvm.sh ${LLVM_VERSION} && rm /tmp/*
ENV PATH=/usr/lib/llvm-${LLVM_VERSION}/bin/:$PATH
RUN clang --version | grep "version ${LLVM_VERSION}"
RUN apt update && apt install lldb-${LLVM_VERSION}

# install hexagon-clang toolchain
RUN apt update && apt install -y zstd
RUN apt update && apt install -y libc++1 libunwind-19
RUN cd /tmp && \
aria2c -x 16 https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/22.1.4_/clang+llvm-22.1.4-cross-hexagon-unknown-linux-musl.tar.zst && \
tar xvf *.zst && \
rm *zst && \
mv clang*/x86_64-linux-gnu /opt/hexagon-toolchain/ && \
rm -rf /tmp/*
ENV PATH /opt/hexagon-toolchain/bin/:$PATH
RUN hexagon-clang --version

# wrap compilers to call ccache, keep frame pointer, and enable debug info
RUN mkdir /opt/compiler_wrappers && \
    for c in gcc g++ hexagon-clang hexagon-clang++ hexagon-unknown-linux-musl-clang hexagon-unknown-linux-musl-clang++; do \
        f=/opt/compiler_wrappers/$c && \
        echo '#!/usr/bin/env bash' >> $f && \
        echo 'args="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -g"' >> $f && \
        echo '[ "$CC_NO_DEBUG_MACROS" == "1" ] || args="$args -ggdb3"' >> $f && \
        echo '[[ "$*" =~ ' -E ' ]] && args=' >> $f && \
        echo "exec ccache $(which $c) \"\$@\" \$args" >> $f && \
        chmod +x $f;\
    done
ENV PATH=/opt/compiler_wrappers:$PATH

ENV LANG=en_US.UTF-8
