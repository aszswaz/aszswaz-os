%ifndef PRINT32_H
%define PRINT32_H

%include "config/boot.asm"
%include "config/gdt.asm"

[bits 32]

SCREEN_COLUMN: equ 80
SCREEN_LINE: equ 25
; 显卡文本模式中，一页可显示的字符数量
VIDEO_TEXT_PAGE_SIZE: equ SCREEN_LINE * SCREEN_COLUMN
; 当前行的行号和行地址
CURRENT_LINE: db 0
CURRENT_LINE_ADDRESS: dd 0

; 清理屏幕
clean_screen:
    push ebp
    mov ebp, esp

    ; 将显存的段描述符选择子设置给 es 寄存器
    mov eax, SELECTOR_VIDEO
    mov es, eax

    ; 设置目标地址，段寄存器是 ES
    mov edi, 0
    ; 使用 ecx 作为循环计数器
    mov ecx, VIDEO_TEXT_PAGE_SIZE
    clean_screen_while01:
        mov word [es: edi], 0
        add edi, 2
        ; 每次执行 loop，ecx 寄存器就会减 1，这里用于循环，当 ecx 为 0 时，循环结束
        loop clean_screen_while01

    mov byte [CURRENT_LINE], 0
    mov dword [CURRENT_LINE_ADDRESS], 0
    leave
    ret

; 输出字符串到屏幕
print:
    push ebp
    mov ebp, esp

    mov eax, SELECTOR_VIDEO
    mov es, eax

    ; 将 ASCII 字符发送到显存
    ; 设置源地址，和目标地址
    mov esi, [ebp + 8]
    mov edi, [CURRENT_LINE_ADDRESS]
    .print_while01:
        mov al, [esi]

        ; 如果到达字符串末尾，结束循环
        cmp al, 0
        jz .print_end

        add esi, 1

        ; 如果遇到换行符，将 di 指向下一行的地址
        cmp al, 10
        jne .print_if_end01
            mov eax, 0
            ; 自增行号
            mov al, [CURRENT_LINE]
            add al, 1
            mov [CURRENT_LINE], al

            ; 计算行的起始地址
            push eax
            call get_line_address
            add esp, 8
            mov edi, eax
            jmp .print_while01
        .print_if_end01:
        ; 如果遇到归位符（\r），di 回到行首
        cmp al, 13
        jne .print_if_end02
            mov eax, [CURRENT_LINE]
            push eax
            call get_line_address
            add esp, 8
            mov edi, eax
            jmp .print_while01
        .print_if_end02:

        ; 写入字符到显存
        ; 设置文字属性，0 表示无背景色，7 表示前景色为白色
        mov ah, 0x07
        mov [es: edi], ax
        add edi, 2
        jmp .print_while01

    .print_end:
    mov [CURRENT_LINE_ADDRESS], edi
    leave
    ret

; 计算行在显存中的起始地址
get_line_address:
    push ebp
    mov ebp, esp

    mov eax, [bp + 8]
    ; 计算行的起始地址
    mov ebx, SCREEN_COLUMN
    mul ebx
    mov ebx, 2
    mul ebx

    leave
    ret

%endif
