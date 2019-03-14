bits 64
default rel


section .data

; Varying the count of bytes at 'a' affects which calculations go wrong.
; There seems to be a breaking point at the address half way between a and x.

; secion .bss and resb acts the same way.
a db 0,0,0,0,0,0

x db 1

section .text
global main

main:
    and dword [a], 1
    mov ax, [a]
    mov ax, [a + 1]
    mov ax, [a + 2]
    mov ax, [a + 3] ; Ends up 0x100 bytes too high
    mov ax, [a + 4] ; Ends up 0x100 bytes too high
    mov ax, [a + 5] ; Ends up 0x100 bytes too high
    mov ax, [a + 6] ; <x>
    mov ax, [a + 7]
    mov ax, [a + 8]
    mov ax, [a + 9]
    mov ax, [a + 10]
