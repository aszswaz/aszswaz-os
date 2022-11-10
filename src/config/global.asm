%ifndef GLOBAL_H
%define GLOBAL_H

%include "config/boot.asm"

; 定义全局变量的保存地址
section .bss vstart=GLOBAL_ADDRESS:

; 启动盘的驱动器号
STARTUP_DISK_DRIVE_LETTER: resb 1

; 用于存储通过 BIOS 获得所有内存信息，比如 RAM
ARDS: resb 200
ARDS_SIZE: resb 4
; 可用内存大小
MEMORY_SZIE: resb 4

; 所有全局变量的总大小
GLOBAL_SIZE: equ $ - $$

%endif
