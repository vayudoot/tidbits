section .data

width   equ     80

board:
    ; North wall:
    times 80 db "X"
    db 0x0a

    ; One line of west and east walls:
    db "X"
    times 78 db " "
    db "X", 0x0a

    ; Another line of west and east walls:
    db "X"
    times 78 db " "
    db "X", 0x0a

    ; South wall:
    times 80 db "X"
    db 0x0a

board_size   equ   $ - board

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

