FROM ubuntu:24.04

# add architecture
RUN dpkg --add-architecture i386 \
    && apt-get update >/dev/null

# libcod requirements
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        g++-multilib \
        git \
    >/dev/null

# speex requirements
ARG enable_speex="0"
RUN if [ "$enable_speex" = "1" ]; then \
        apt-get install -y \
            git \
            libtool \
            build-essential \
            automake \
            g++-multilib \
            libogg-dev \
            libogg-dev:i386 \
            ffmpeg \
        >/dev/null; \
    fi

# cod2 runtime requirements
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        libstdc++5:i386 \
        netcat-openbsd \
        libmysqlclient-dev:i386 \
        libsqlite3-dev:i386 \
        curl \
    >/dev/null

RUN apt-get clean >/dev/null

# compile speex
RUN if [ "$enable_speex" = "1" ]; then \
        git clone https://gitlab.xiph.org/xiph/speex.git && \
        cd speex && \
        git checkout tags/Speex-1.1.9 -b 1.1.9 && \
        env AUTOMAKE=automake ACLOCAL=aclocal LIBTOOLIZE=libtoolize \
            ./autogen.sh CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32 --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu >/dev/null && \
        make >/dev/null && \
        make install >/dev/null && \
        ldconfig >/dev/null && \
        cd / && \
        rm -rf /speex && \
        speexdec --version && \
        speexenc --version; \
    fi

# compile libcod
ARG libcod_url="https://github.com/nl-squad/libcod"
ARG libcod_commit="9390a0859b29efc985cac5627be31b84e95d787c"

RUN git clone ${libcod_url} \
    && cd libcod \
    && if [ -z "$libcod_commit" ]; then git checkout ${libcod_commit}; fi

WORKDIR /libcod/code
COPY ./doit.sh doit.sh

ARG cod2_patch="0"
ARG mysql_variant="1"
ARG enable_unsafe="0"
RUN ./doit.sh --cod2_patch=${cod2_patch} --enable_speex=${enable_speex} --mysql_variant=${mysql_variant} --enable_unsafe=${enable_unsafe}

RUN mkdir /cod2

# Set user and group
ARG user=cod2
ARG group=cod2
ARG uid=1001
ARG gid=1002
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -d /cod2 ${user}

# cod2 server files
WORKDIR /cod2
RUN ls -lh /libcod/code/bin/libcod2_1_${cod2_patch}.so
RUN cp /libcod/code/bin/libcod2_1_${cod2_patch}.so libcod.so
COPY ./cod2_lnxded/1_${cod2_patch} cod2_lnxded
COPY healthcheck.sh entrypoint.sh ./

# pre-create volume directories
RUN mkdir -p /cod2/main
RUN mkdir -p /cod2/library
RUN mkdir -p /cod2/home

# change owner
RUN chown -R ${user}:${group} /cod2
RUN ls -la /cod2

# cleanup
RUN chmod -R +w /libcod && \
    rm -rf /libcod

# Switch to user
USER ${uid}:${gid}

# check server info every 5 seconds 7 times (check, if your server can change a map without restarting container)
HEALTHCHECK --interval=5s --timeout=3s --retries=7 CMD /cod2/healthcheck.sh

# start script
ENTRYPOINT /cod2/entrypoint.sh
