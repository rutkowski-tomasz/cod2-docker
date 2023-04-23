#!/bin/bash -ex

IMAGE_NAME=${1:-rutkowski/cod2}
PUSH=${2:-""}

cod_patches=( 0 2 3 )
mysql_variants=( 1 2 )
speex_options=( 0 1 )
enable_unsafe_options=( 0 1 )

for cod_patch in "${cod_patches[@]}"
do
    for mysql_variant in "${mysql_variants[@]}"
    do
        for speex in "${speex_options[@]}"
        do
            for enable_unsafe in "${enable_unsafe_options[@]}"
            do
                echo "Building and pushing with parameters cod_patch=$cod_patch, mysql_variant=$mysql_variant, speex=$speex, enable_unsafe=$enable_unsafe"

                ./build.sh \
                    --image_name=$IMAGE_NAME \
                    --cod2_patch=$cod_patch \
                    --mysql_variant=$mysql_variant \
                    --speex=$speex \
                    --enable_unsafe=$enable_unsafe \
                    --push=$PUSH

                echo "Done"
            done
        done
    done
done
