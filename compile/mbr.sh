#!/bin/bash

set -e

# 根据 OS 加载程序的大小，计算该程序占用的扇区
loader_size=$(du -b $OS_LOADER | awk '{ print $1 }')
sector=$(echo "$loader_size / 512" | bc)
remainder=$(echo "$loader_size % 512" | bc)
if [[ $remainder != 0 ]]; then
    sector=$(($sector + 1))
fi

$ASSEMBLER "$1" -DLOADER_SECTORS=$sector -o "$2"
