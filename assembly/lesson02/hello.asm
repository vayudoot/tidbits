section .data
hello_world     db      "Hello World!", 0x0a
 
section .text
global main
 
main:
    mov rax, 0x02000004     ; SYS_write
    mov rdi, 1              ; filedes = STDOUT_FILENO = 1
    mov rsi, hello_world    ; The address of hello_world string
    mov rdx, 13             ; The size to write
    syscall

    mov rax, 0x02000001     ; SYS_exit
    mov rdi, 0              ; Exit status
    syscall
