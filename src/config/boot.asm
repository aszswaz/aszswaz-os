%ifndef BOOT_H
%define BOOT_H

; 存储全局变量的地址
GLOBAL_ADDRESS: equ 0x7E00

; 内核加载器的内存地址，可用内存的地址范围是 0x500 ~ 0x7BFF，预留一部分内存作为栈内存
LOADER_BASE_ADDR: equ 0x900
; 内核加载器的所在扇区（CHS 地址）
LOADER_START_SECTOR: equ 3

; BIOS 中断号定义
; BIOS 显示服务
BIOS_VIDEO_SERVICE: equ 0x10
; BIOS 磁盘管理服务
BIOS_DISK_SERVICE: equ 0x13
; BIOS 杂项服务
BIOS_OTHER_SERVICE: equ 0x15

%endif
