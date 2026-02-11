FROM docker.io/debian:trixie

RUN apt update && apt install -y \
build-essential \
binutils \
git \
gcc-powerpc64-linux-gnu \
gcc-powerpc64le-linux-gnu \
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

# wrap compilers to call ccache, keep frame pointer, and enable debug info
# workaround issues when compiling some slof files
RUN mkdir /opt/compiler_wrappers && \
    for c in gcc g++ powerpc64-linux-gnu-gcc powerpc64le-linux-gnu-gcc; do \
        f=/opt/compiler_wrappers/$c && \
        echo '#!/usr/bin/env bash' >> $f && \
        echo 'args="-fno-omit-frame-pointer -g"' >> $f && \
        echo '[ "$CC_NO_DEBUG_MACROS" == "1" ] || args="$args -ggdb3"' >> $f && \
        echo '[[ "$*" =~ ' -E ' ]] && args=' >> $f && \
        echo '[[ "$*" =~ 'lowmem.S' ]] && args=' >> $f && \
        echo '[[ "$*" =~ 'brokensc1.c' ]] && args=' >> $f && \
        echo "exec ccache /usr/bin/$c \"\$@\" \$args" >> $f && \
        chmod +x $f;\
    done
ENV PATH=/opt/compiler_wrappers:$PATH

ENV LANG=en_US.UTF-8
