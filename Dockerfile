FROM ubuntu:23.04

# Create non-root user
RUN useradd -m -d /home/user user

# add architecture
RUN dpkg --add-architecture i386 \
    && apt-get update >/dev/null

# libcod requirements
RUN apt-get install -y \
        g++-multilib \
        git \
        libmysqlclient-dev:i386 \
        libsqlite3-dev:i386 \
    >/dev/null

# speex requirements
ARG speex="0"
RUN if [ "$speex" = "1" ]; then \
        apt-get install -y \
            sudo \
            git \
            libtool \
            build-essential \
            automake \
            g++-multilib \
            libogg-dev \
            libogg-dev:i386 \
        >/dev/null; \
    fi

# cod2 runtime requirements
RUN apt-get install -y \
        libstdc++5:i386 \
        netcat-openbsd \
        libmysqlclient-dev:i386 \
        libsqlite3-dev:i386 \
        ffmpeg \
        curl \
    >/dev/null

RUN apt-get clean >/dev/null

# compile speex
RUN if [ "$speex" = "1" ]; then \
        git clone https://gitlab.xiph.org/xiph/speex.git && \
        cd speex && \
        git checkout tags/Speex-1.1.9 -b 1.1.9 && \
        env AUTOMAKE=automake ACLOCAL=aclocal LIBTOOLIZE=libtoolize \
            ./autogen.sh CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32 --build=x86_64-pc-linux-gnu --host=i686-pc-linux-gnu && \
        make && \
        make install && \
        ldconfig && \
        cd / && \
        rm -rf /speex && \
        speexdec --version && \
        speexenc --version; \
    fi

# compile libcod
ARG libcod_url="https://github.com/ibuddieat/zk_libcod"
ARG libcod_commit="f6b1582"

RUN git clone ${libcod_url} \
    && cd zk_libcod \
    && if [ -z "$libcod_commit" ]; then git checkout ${libcod_commit}; fi

WORKDIR /zk_libcod/code
COPY ./doit.sh doit.sh

ARG cod2_patch="0"
ARG mysql_variant="1"
ARG enable_unsafe="0"
RUN ./doit.sh --cod2_patch=${cod2_patch} --speex=${speex} --mysql_variant=${mysql_variant} --enable_unsafe=${enable_unsafe}

# cod2 server
RUN mkdir /cod2
WORKDIR /cod2
RUN cp /zk_libcod/code/bin/libcod2_1_${cod2_patch}.so libcod.so
RUN chown -R user:user /cod2
COPY --chown=user:user ./cod2_lnxded/1_${cod2_patch} cod2_lnxded
COPY --chown=user:user healthcheck.sh entrypoint.sh ./
RUN chmod +x healthcheck.sh entrypoint.sh
RUN ls -la /cod2

# cleanup
RUN chmod -R +w /zk_libcod && \
    rm -rf /zk_libcod

# check server info every 5 seconds 7 times (check, if your server can change a map without restarting container)
HEALTHCHECK --interval=5s --timeout=3s --retries=7 CMD /cod2/healthcheck.sh

# start script
USER user
ENTRYPOINT /cod2/entrypoint.sh
