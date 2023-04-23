# Base image
FROM ubuntu:23.04 as builder

# cod2 requirements
RUN dpkg --add-architecture i386 \
    && apt-get -qq update \
    && apt-get -qq install -y \
        g++-multilib \
        libstdc++5:i386 \
        git \
    && apt-get -qq clean

# compile libcod
ARG cod2_patch="0"
ARG libcod_url="https://github.com/ibuddieat/zk_libcod"
ARG libcod_commit="8f9533b"
ARG mysql_variant="1"
ARG sqlite_enabled="1"
ARG speex="0"
ARG enable_unsafe="0"
RUN if [ "$mysql_variant" != "0" ]; then apt-get install -y libmysqlclient-dev:i386; fi \
    && if [ "$sqlite_enabled" != "0" ]; then apt-get install -y libsqlite3-dev:i386; fi \
    && mkdir /cod2 \
    && cd /cod2 \
    && git clone ${libcod_url} \
    && cd zk_libcod \
    && if [ -z "$libcod_commit" ]; then git checkout ${libcod_commit}; fi

WORKDIR /cod2/zk_libcod/code
COPY ./doit.sh doit.sh
RUN ./doit.sh --cod2_patch=${cod2_patch} --speex=${speex} --mysql_variant=${mysql_variant} --enable_unsafe=${enable_unsafe} \
    && cp ./bin/libcod2_1_${cod2_patch}.so /cod2/libcod.so

# Final runtime image
FROM ubuntu:23.04

ARG mysql_variant="1"
ARG sqlite_enabled="1"
ARG cod2_patch="0"

# Define the list of packages to be installed
RUN PACKAGES="libstdc++5:i386 netcat-openbsd"; \
    if [ "$mysql_variant" != "0" ]; then \
        PACKAGES="$PACKAGES libmysqlclient-dev:i386"; \
    fi; \
    if [ "$sqlite_enabled" != "0" ]; then \
        PACKAGES="$PACKAGES libsqlite3-dev:i386"; \
    fi; \
    echo "Going to install the following packages: $PACKAGES"; \
    dpkg --add-architecture i386 \
    && apt-get -qq update \
    && apt-get -qq install -y $PACKAGES \
    && apt-get -qq clean

WORKDIR /cod2
COPY --from=builder /cod2/libcod.so libcod.so
COPY ./cod2_lnxded/1_${cod2_patch} cod2_lnxded
COPY healthcheck.sh entrypoint.sh ./

# check server info every 5 seconds 7 times (check, if your server can change a map without restarting container)
HEALTHCHECK --interval=5s --timeout=3s --retries=7 CMD /cod2/healthcheck.sh

# start script
ENTRYPOINT /cod2/entrypoint.sh
