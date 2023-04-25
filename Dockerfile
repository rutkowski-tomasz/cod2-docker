FROM ubuntu:23.04 as builder

# libcod requirements
RUN dpkg --add-architecture i386 \
    && apt-get update -qq \
    && apt-get install -qq -y \
        g++-multilib \
        git \
        libmysqlclient-dev:i386 \
        libsqlite3-dev:i386 \
    && apt-get clean -qq

# speex requirements
RUN dpkg --add-architecture i386 \
    && apt-get update -qq \
    && apt-get install -qq -y \
        git \
        libtool \
        build-essential \
        automake \
        g++-multilib \
        # libogg-dev \
        # libogg-dev:i386 \
    && apt-get clean -qq

# compile speex
RUN git clone https://gitlab.xiph.org/xiph/speex.git
WORKDIR /speex
RUN git checkout tags/Speex-1.1.9 -b 1.1.9

RUN env AUTOMAKE=automake ACLOCAL=aclocal LIBTOOLIZE=libtoolize \
    ./autogen.sh CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32 --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu

RUN make
RUN make install
RUN ldconfig

WORKDIR /
RUN rm -rf /speex

# compile libcod
ARG cod2_patch="0"
ARG libcod_url="https://github.com/ibuddieat/zk_libcod"
ARG libcod_commit="f6b1582"
ARG mysql_variant="1"
ARG speex="0"
ARG enable_unsafe="0"
RUN git clone ${libcod_url} \
    && cd zk_libcod \
    && if [ -z "$libcod_commit" ]; then git checkout ${libcod_commit}; fi

WORKDIR /zk_libcod/code
COPY ./doit.sh doit.sh
RUN ./doit.sh --cod2_patch=${cod2_patch} --speex=${speex} --mysql_variant=${mysql_variant} --enable_unsafe=${enable_unsafe} \
    && cp ./bin/libcod2_1_${cod2_patch}.so /libcod.so

# Final runtime image
FROM ubuntu:23.04
ARG cod2_patch="0"

# Define the list of packages to be installed
RUN dpkg --add-architecture i386 \
    && apt-get update -qq \
    && apt-get install -qq -y libstdc++5:i386 netcat-openbsd libmysqlclient-dev:i386 libsqlite3-dev:i386 \
    && apt-get clean -qq

WORKDIR /cod2
COPY --from=builder /libcod.so libcod.so
COPY ./cod2_lnxded/1_${cod2_patch} cod2_lnxded
COPY healthcheck.sh entrypoint.sh ./

# check server info every 5 seconds 7 times (check, if your server can change a map without restarting container)
HEALTHCHECK --interval=5s --timeout=3s --retries=7 CMD /cod2/healthcheck.sh

# start script
ENTRYPOINT /cod2/entrypoint.sh
