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

ENV LLVM_VERSION=23
RUN wget -q https://apt.llvm.org/llvm-snapshot.gpg.key -O /etc/apt/trusted.gpg.d/apt.llvm.org.asc
RUN echo "deb http://apt.llvm.org/trixie/ llvm-toolchain-trixie-${LLVM_VERSION} main" >> /etc/apt/sources.list
RUN apt update && apt install -y lldb-${LLVM_VERSION} llvm-${LLVM_VERSION}
RUN ln -sf /usr/bin/llvm-nm-${LLVM_VERSION} /usr/bin/nm
RUN ln -sf /usr/bin/llvm-addr2line-${LLVM_VERSION} /usr/bin/addr2line
RUN ln -sf /usr/bin/lldb-${LLVM_VERSION} /usr/bin/lldb
RUN ln -sf /usr/bin/lldb-dap-${LLVM_VERSION} /usr/bin/lldb-dap

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
RUN dpkg --add-architecture amd64
# hexagon-sim dependency
RUN apt update && apt install -y libncurses6:amd64
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libncurses.so.6 libncurses.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libpanel.so.6 libpanel.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libtinfo.so.6 libtinfo.so.5
RUN cd /usr/lib/x86_64-linux-gnu/ && ln -s libform.so.6 libform.so.5

# install hexagon-clang toolchain
RUN apt update && apt install -y zstd
RUN apt update && apt install -y libc++1 libunwind-19
RUN cd /tmp && \
aria2c -x 16 https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/22.1.4_/clang+llvm-22.1.4-cross-hexagon-unknown-linux-musl.tar.zst && \
tar xvf *.zst && \
rm *zst && \
mv clang*/x86_64-linux-gnu /opt/hexagon-toolchain/ && \
rm -rf /tmp/*
RUN apt update && apt install -y libzstd1:amd64 zlib1g:amd64 libc++1:amd64 libc++abi1:amd64 llvm-libunwind1:amd64
ENV PATH=/opt/hexagon-toolchain/bin/:$PATH
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
