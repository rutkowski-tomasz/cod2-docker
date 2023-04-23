#!/bin/bash -ex

VERSION=$(cat __version__)

# [Custom] Get parameters
speex=0
mysql_variant=0
enable_unsafe=0
push=0

while [ $# -gt 0 ]; do
    case "$1" in
        --image_name=*)
        image_name="${1#*=}"
        ;;
        --cod2_patch=*)
        cod2_patch="${1#*=}"
        ;;
        --mysql_variant=*)
        mysql_variant="${1#*=}"
        ;;
        --speex=*)
        speex="${1#*=}"
        ;;
        --enable_unsafe=*)
        enable_unsafe="${1#*=}"
        ;;
        --push=*)
        push="${1#*=}"
        ;;
        *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
done

for arg_name in "image_name" "cod2_patch"; do
    arg_value=$(eval echo \$$arg_name)
    if [ -z "$arg_value" ]; then
        echo "Error: Missing argument --${arg_name}"
        exit 1
    fi
done
# End: [Custom] Get parameters

tag="${image_name}:${VERSION}-server1.${cod2_patch}"
if [[ "$mysql_variant" -eq 1 ]]; then
    tag="${tag}-mysql"
elif [[ "$mysql_variant" -eq 2 ]]; then
    tag="${tag}-mysqlvoron"
fi

if [[ "$speex" -eq 1 ]]; then
    tag="${tag}-speex"
fi

if [[ "$enable_unsafe" -eq 1 ]]; then
    tag="${tag}-unsafe"
fi

docker build \
    --build-arg cod2_patch="${cod2_patch}" \
    --build-arg mysql_variant="${mysql_variant}" \
    --build-arg sqlite_enabled=1 \
    --build-arg speex=${speex} \
    --build-arg enable_unsafe=${enable_unsafe} \
    -t $tag \
    .

if [[ "$push" -eq 1 ]]; then
    docker push ${tag}
fi
