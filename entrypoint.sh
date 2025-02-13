#!/bin/bash -ex

fs_game=$COD2_SET_fs_homepath/$COD2_SET_fs_game
fs_library=$COD2_SET_fs_homepath/$COD2_SET_fs_game/$COD2_SET_fs_library

if [ ! -d "$fs_game" ]; then
    mkdir -p $fs_game
    if [ ! -d "$fs_library" ]; then
        ln -s /cod2/library $fs_library
    fi
fi

ls -l $fs_game
ls -l $fs_library

# prefix to parse cvars from envs
prefix=COD2_
cmds=(set seta sets)

# show envs | search for prefix | delete prefix name | replace = to space | format to set cvar output | join lines
COMMANDS=""
for cmd in ${cmds[@]}; do
    fullprefix="${prefix}${cmd^^}_"
    parsed=$(env | grep $fullprefix | sed "s/$fullprefix//g" | sed 's/=/ /g' | awk -v cmd=$cmd '{print "+" cmd " " $1 " " $2}' | paste -sd " " -)
    COMMANDS="$COMMANDS $parsed" 
done

export LD_LIBRARY_PATH=/lib:/lib/i386-linux-gnu:/usr/lib:/usr/lib/i386-linux-gnu
export LD_PRELOAD=/cod2/libcod.so

/cod2/cod2_lnxded "$PARAMS_BEFORE $COMMANDS $PARAMS $PARAMS_AFTER"
