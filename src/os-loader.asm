%include "config/boot.asm"
%include "config/global.asm"

section OS_LOADER vstart=LOADER_BASE_ADDR:
jmp main

%include "config/gdt.asm"
%include "print.asm"

[bits 16]

PROTECTED_MODE_OK: db "Successfully entered protected mode!", 10, 13, 0
GET_MEMORY_INFO_OK: db "Get memory information successfully!", 10, 13, 0
GET_MEMORY_INFO_FAILED: db "Failed to get memory information!", 10, 13, 0

; 备份寄存器
REGISTER_BP: dw 0

main:
    mov sp, $$
    mov bp, sp

    ; 获取内存大小
    call get_mem_size
    ; 在进入保护模式之前，关闭所有中断，否则，可能会导致 BIOS 无限重启
    cli

    ; 打开保护模式
    ; 打开 A20 地址线
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 加载 GDT
    lgdt [GDT_PTR]
    ; 设置 CR0 寄存器第 0 位为 1
    mov eax,cr0
    or al, 1
    mov cr0, eax

    ; 刷新指令流
    jmp dword SELECTOR_CODE:p_mode_start

; 获得内存大小
get_mem_size:
    push bp
    mov bp, sp

    ; ebx 必须为 0
    mov ebx, 0
    ; 设置 ARDS 结构体起始地址
    mov di, ARDS
    ; 固定为签名标记 0x534D4150，此十六进制数字是字符串 SMAP 的ASCII 码，BIOS 将调用者正在请求的内存信息写入 ES: DI 寄存器所指向的ARDS 缓冲区后，再用此签名校验其中的信息
    mov edx, 0x534D4150

    .get_mem_size_while:
        ; 设置子功能号
        mov eax, 0xE820
        ; ARDS 结构的字节大小：用来指示 BIOS 写入的字节数。调用者和 BIOS 都同时支持的大小是 20 字节
        mov ecx, 20
        int BIOS_OTHER_SERVICE
        ; 如果 CF 为 1，表示出现异常
        jc .get_mem_size_error

        ; BIOS 会返回多种内存的信息，比如 RAM，只需要获取最大的那一块内存信息即可
        mov eax, [MEMORY_SZIE]
        cmp eax, [di + 8]
        jnl .get_mem_size_if_end
            mov eax, [di + 8]
            mov [MEMORY_SZIE], eax
        .get_mem_size_if_end:

        ; di 指向下一个结构体的地址
        add di, 20
        ; ARDS 大小加一，inc 是自增指令
        inc word [ARDS_SIZE]
        ; 如果 ebx 为 0，代表所有内存信息获取完毕
        cmp ebx, 0
        jnz .get_mem_size_while

    push GET_MEMORY_INFO_OK
    call print16
    add sp, 2
    leave
    ret
    .get_mem_size_error:
        push GET_MEMORY_INFO_FAILED
        call print16
        add sp, 2
        leave
        ret

print16:
    push bp
    mov bp, sp

    mov [REGISTER_BP], bp

    ; 获取光标信息
    mov ah, 3
    mov bh, 0
    int BIOS_VIDEO_SERVICE

    ; 计算字符串的长度
    mov si, [bp + 4]
    mov cx, 0
    .print16_while:
        mov al, [si]
        cmp al, 0
        jz .print16_while_end
        inc si
        inc cx
        jmp .print16_while
    .print16_while_end:

    ; 打印字符串，并移动光标
    mov bp, [bp + 4]
    mov ax, 0x1301
    mov bx, 0x7
    int BIOS_VIDEO_SERVICE

    mov bp, [REGISTER_BP]
    leave
    ret

[bits 32]
p_mode_start:
    mov esp, $$
    ; 已进入保护模式，将段寄存器初始化为选择子
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov ss, ax
    mov gs, ax
    mov es, ax

    call clean_screen

    push PROTECTED_MODE_OK
    call print
    add esp, 8

    jmp $
