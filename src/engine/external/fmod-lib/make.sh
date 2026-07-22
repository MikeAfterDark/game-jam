#!/bin/bash

LINUX_API=/home/mike/code/FMOD/fmodstudioapi20235linux/api/

# gcc -c -fPIC src/fmod_lua.c -I$LINUX_API/core/inc -I$LINUX_API/studio/inc

gcc -c -fPIC src/fmod_lua.c \
    $(pkg-config --cflags lua5.1) \
    -I$LINUX_API/core/inc \
    -I$LINUX_API/studio/inc

LD_RUN_PATH='$ORIGIN' gcc -o libfmodlua.so -Wl,-undefined,dynamic_lookup -shared fmod_lua.o -L$LINUX_API/studio/lib/x86_64 -L$LINUX_API/core/lib/x86_64 -lfmod -lfmodstudio
