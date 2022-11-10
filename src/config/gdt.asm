%ifndef GDT_H
%define GDT_H

[bits 16]

; 定义 GDT 和选择子，分段策略采用平坦模型
; 段的大小粒度，为 0 表示以字节为单位，为 1 表示以内存页（4 KB）为单位
GDT_G4K: equ 1
GDT_G: equ 0
; 操作码的默认操作数大小，为 0 表示操作数为 16 位，为 1 表示操作数为 32 位
GDT_D32: equ 1
; 是否为 64 位段
GDT_L: equ 0
; 段内存用于软件，不用于硬件
GDT_AVL: equ 0
; 段是否存在
GDT_P: equ 1
; 段界限，段描述符的内存大小是(段界限 + 1) * 粒度
GDT_LIMIT_CODE: equ 0xFFFFF
GDT_LIMIT_DATA: equ GDT_LIMIT_CODE
GDT_LIMIT_VIDEO: equ 0
; 段基址
GDT_BASE_CODE: equ 0
GDT_BASE_DATA: equ GDT_BASE_CODE
GDT_BASE_VIDEO: equ 0xB8000
; 段特权
GDT_DPL0: equ 0
GDT_DPL1: equ 1
GDT_DPL2: equ 2
GDT_DPL3: equ 3
; 系统段和非系统段（代码段、数据段）
GDT_S_CODE: equ 1
GDT_S_DATA: equ GDT_S_CODE
GDT_S_SYS: equ 0
; 设置代码段可执行，不可读和不可写
GDT_TYPE_CODE: equ 0x8
; 设置数据段可读、可写和向下拓展，不可执行
GDT_TYPE_DATA: equ 0x2

; 生成代码段描述符高 32 bit
DESC_CODE_HIGH32: equ (GDT_TYPE_CODE << 8) | (GDT_S_CODE << 12) | (GDT_DPL0 << 13) | (GDT_P << 15) | \
    (GDT_LIMIT_CODE & 0xF0000) | (GDT_AVL << 20) | (GDT_L << 21) | (GDT_D32 << 22) | (GDT_G4K << 23)
; 数据段描述符高 32 bit
DESC_DATA_HIGH32: equ (GDT_TYPE_DATA << 8) | (GDT_S_DATA << 12) | (GDT_DPL0 << 13) | (GDT_P << 15) | \
    (GDT_LIMIT_DATA & 0xF0000) | (GDT_AVL << 20) | (GDT_L << 21) | (GDT_D32 << 22) | (GDT_G4K << 23)
; 显存段描述符高 32 bit
DESC_VIDEO_HIGH32: equ ((GDT_BASE_VIDEO & 0xFF0000) >>> 16) | (GDT_TYPE_DATA << 8) | (GDT_S_DATA << 12) | (GDT_DPL0 << 13) | (GDT_P << 15) | \
    (GDT_LIMIT_VIDEO & 0xF0000) | (GDT_AVL << 20) | (GDT_L << 21) | (GDT_D32 << 22) | (GDT_G4K << 23) | (GDT_BASE_VIDEO & 0xFF000000)

; 定义选择子
; 请求特权极
RPL0: equ 0
RPL1: equ 1
RPL2: equ 2
RPL3: equ 3
; 从 GDT 读取段描述符，还是从 LDT 读取段描述符
TI_GDT: equ 0
TI_LDT: equ 1

; 构建 GDT 和内部的描述符
GDT_BASE: dd 0, 0
DESC_CODE: dd GDT_LIMIT_CODE & 0xFFFF, DESC_CODE_HIGH32
DESC_STACK: dd GDT_LIMIT_DATA & 0xFFFF, DESC_DATA_HIGH32
DESC_VIDEO: dd ((GDT_BASE_VIDEO & 0xFFFF) << 16) | 0x7, DESC_VIDEO_HIGH32
GDT_SIZE: equ $ - GDT_BASE
GDT_LIMIT: equ GDT_SIZE - 1
; 预留 60 个段描述符的空位
times 60 dq 0

; 构建 GDT 指针和选择子
GDT_PTR: dw GDT_LIMIT
        dd GDT_BASE
SELECTOR_CODE: equ RPL0 | (TI_GDT << 2) | (1 << 3)
SELECTOR_DATA: equ RPL0 | (TI_GDT << 2) | (2 << 3)
SELECTOR_VIDEO: equ RPL0 | (TI_GDT << 2) | (3 << 3)

%endif
