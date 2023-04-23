# Base image
FROM ubuntu:23.04 as builder

# cod2 requirements
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        g++-multilib \
        libstdc++5:i386 \
        netcat \
        git \
    && apt-get clean

# compile libcod
ARG cod2_patch="0"
ARG libcod_url="https://github.com/ibuddieat/zk_libcod"
ARG libcod_commit="8f9533b"
ARG mysql_variant="1"
ARG sqlite_enabled="1"
ARG speex="0"
ARG enable_unsafe="0"
RUN if [ "$mysql_variant" != "0" ] || [ "$sqlite_enabled" != "0" ]; then apt-get update; fi \
    && if [ "$mysql_variant" != "0" ]; then apt-get install -y libmysqlclient-dev:i386; fi \
    && if [ "$sqlite_enabled" != "0" ]; then apt-get install -y libsqlite3-dev:i386; fi \
    && if [ "$mysql_variant" != "0" ] || [ "$sqlite_enabled" != "0" ]; then apt-get clean; fi  \
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

# Install necessary runtime dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        libstdc++5:i386 \
        netcat \
    && apt-get clean

ARG mysql_variant="1"
ARG sqlite_enabled="1"

RUN if [ "$mysql_variant" != "0" ]; then apt-get install -y libmysqlclient-dev:i386; fi \
    && if [ "$sqlite_enabled" != "0" ]; then apt-get install -y libsqlite3-dev:i386; fi

# Copy necessary files from the builder image
COPY --from=builder /cod2/libcod.so /cod2/libcod.so

# Copy cod2 server file to the runtime image
ARG cod2_patch="0"
COPY ./cod2_lnxded/1_${cod2_patch} /cod2/cod2_lnxded

# Set the working directory
WORKDIR /cod2

# Copy healthcheck.sh and entrypoint.sh
COPY healthcheck.sh entrypoint.sh /cod2/

# check server info every 5 seconds 7 times (check, if your server can change a map without restarting container)
HEALTHCHECK --interval=5s --timeout=3s --retries=7 CMD /cod2/healthcheck.sh

# start script
ENTRYPOINT /cod2/entrypoint.sh
