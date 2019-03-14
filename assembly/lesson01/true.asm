global main
 
main:
    mov rax, 0x02000001     ; System call number for exit = 1
    mov rdi, 0              ; Exit success = 0
    syscall                 ; Invoke the kernel

