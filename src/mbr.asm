%include "config/boot.asm"
%include "config/global.asm"

; MBR 主引导记录
; vstart 是 mbr 程序的入口地址
section .text vstart=0x7C00:
    jmp main

[bits 16]

DISK_READ_ERROR: db "OS loader read failed, the error code is: 0x", 0
DISK_ERROR_CODE: db 0

HEX_SEED: db "0123456789ABCDEF"
HEX_STR: times 3 db 0

; 寄存器备份
REGISTER_BP: dw 0

main:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov fs, ax
    mov es, ax
    mov sp, $$
    mov bp, sp

    ; 初始化所有全局变量
    mov cx, GLOBAL_SIZE
    mov di, GLOBAL_ADDRESS
    .main_while:
        mov byte [GLOBAL_ADDRESS], 0
        inc di
        loop .main_while

    ; BIOS 将启动盘的驱动器号保存在 dl 寄存器
    mov [STARTUP_DISK_DRIVE_LETTER], dl

    ; 清理屏幕
    ; 通过 BIOS 中断，向上滚屏
    mov ax, 0x0600
    ; 空白区域的缺省属性
    mov bh, 0
    ; 设置窗口的左上角位置，CH 为 Y 坐标，CL 为 X 坐标
    mov cx, 0
    ; 设置窗口的右下角位置，以行和列为单位，dh 为行，dl 为列
    mov dx, 0x1950
    ; 调用 BIOS 中断
    int BIOS_VIDEO_SERVICE

    ; 初始化光标坐标
    mov ah, 2
    mov bh, 0
    mov dx, 0
    int BIOS_VIDEO_SERVICE

    ; 通过 BIOS 中断，读取 OS 加载器
    ; 设置功能号，2 表示读取扇区
    mov ah, 2
    ; 设置要读取的扇区数
    mov al, LOADER_SECTORS
    ; 设置柱面
    mov ch, 0
    ; 设置磁头
    mov dh, 0
    ; 设置扇区
    mov cl, LOADER_START_SECTOR
    ; 设置驱动器号，0 ~ 0x7F 是软盘，0x80 ~ 0xFF 是硬盘
    mov dl, [STARTUP_DISK_DRIVE_LETTER]
    ; 设置目标地址
    mov bx, LOADER_BASE_ADDR
    int BIOS_DISK_SERVICE
    ; 如果磁盘读取出错，BIOS 会将 flags 寄存器的 CF 置 1，AH 为错误码
    jc disk_error

    jmp LOADER_BASE_ADDR

; BIOS 会将错误码设置给 AH 寄存器，需要将它打印到屏幕上
disk_error:
    mov [DISK_ERROR_CODE], ah
    mov [REGISTER_BP], bp

    push DISK_READ_ERROR
    call print
    add sp, 2

    ; 以 16 进制打印错误码
    ; 低 4 位的十六进制
    mov al, [DISK_ERROR_CODE]
    and al, 0xF
    mov si, HEX_SEED
    mov ah, 0
    add si, ax
    mov al, [si]
    mov [HEX_STR + 1], al
    ; 高 4 位的十六进制
    mov al, [DISK_ERROR_CODE]
    shr al, 4
    mov si, HEX_SEED
    mov ah, 0
    add si, ax
    mov al, [si]
    mov [HEX_STR], al

    push HEX_STR
    call print
    add sp, 2

    jmp $

print:
    push bp
    mov bp, sp

    mov [REGISTER_BP], bp

    ; 获取光标信息
    mov ah, 3
    mov bh, 0
    int BIOS_VIDEO_SERVICE

    ; 计算字符串长度
    mov si, [bp + 4]
    mov cx, 0
    .print_while:
        mov al, [si]
        cmp al, 0
        jz .print_while_end
        inc si
        inc cx
        jmp .print_while
    .print_while_end:

    ; 打印字符串
    mov bp, [bp + 4]
    mov ax, 0x1301
    mov bx, 0x7
    int BIOS_VIDEO_SERVICE

    mov bp, [REGISTER_BP]
    leave
    ret

; 对剩余空间进行填充，让整个程序的总计大小为 512 B
times 510 - ($ - $$) db 0
db 0x55, 0xAA
