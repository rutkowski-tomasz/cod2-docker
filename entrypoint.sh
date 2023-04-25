#!/bin/bash -ex

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

export LD_LIBRARY_PATH=/usr/lib/i386-linux-gnu:$LD_LIBRARY_PATH
export LD_PRELOAD=/cod2/libcod.so

ls -la /cod2
ls -la /cod2/nl
ls -la /cod2/main
ls -la /cod2/.callofduty2
ls -la /cod2/.callofduty2/nl
ls -la /cod2/.callofduty2/nl/Library

strace -f -o strace.log /cod2/cod2_lnxded "$PARAMS_BEFORE $COMMANDS $PARAMS $PARAMS_AFTER"
