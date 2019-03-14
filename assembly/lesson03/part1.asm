section .data

hello_world      db      "Hello World!", 0x0a
hello_world_size equ     $ - hello_world

section .text
global main

main:
    mov rax, 0x02000004        ; SYS_write
    mov rdi, 1                 ; filedes = STDOUT_FILENO = 1
    mov rsi, hello_world       ; buf = The address of hello_world string
    mov rdx, hello_world_size  ; nbyte
    syscall

    mov rax, 0x02000001        ; SYS_exit
    mov rdi, 0                 ; Exit status
    syscall

