section .data

width   equ     80

%macro full_line 0
    times width db "X"
    db 0x0a
%endmacro

%macro hollow_line 0
    db "X"
    times width-2 db " "
    db "X"
    db 0x0a
%endmacro


board:  full_line

        %rep 25
        hollow_line
        %endrep

        full_line

board_size equ $-board

section .text
global main

main:
    mov rax, 0x02000004     ; SYS_write
    mov rdi, 1              ; filedes = STDOUT_FILENO = 1
    mov rsi, board          ; buf
    mov rdx, board_size     ; nbyte
    syscall

    mov rax, 0x02000001     ; SYS_exit
    mov rdi, 0              ; Exit status
    syscall

