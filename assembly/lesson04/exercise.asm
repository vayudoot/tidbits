bits 64
default rel

section .data

width   equ     80
pitch   equ     width + 1

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


input_char db 0


section .text
global main

main:
    ; Start out at the center of the board (40, 13):
    mov r8, board + 40 + 13*pitch

.main_loop:
    ; Exercise: Collision detection part:
    cmp byte [r8], ' '
    jne .exit

    mov byte [r8], 'O'      ; Write head into board

    mov rax, 0x02000004     ; SYS_write
    mov rdi, 1              ; filedes = STDOUT_FILENO = 1
    mov rsi, board          ; buf
    mov rdx, board_size     ; nbyte
    syscall

.read_more:
    mov rax, 0x02000003     ; SYS_read
    mov rdi, 0              ; filedes = STDIN_FILENO = 0
    mov rsi, input_char     ; buf
    mov rdx, 1              ; nbyte
    syscall

    ; Assume exactly one byte was read

    mov al, [input_char]

    cmp al, 'w'
    jne .not_up
    sub r8, pitch
    jmp .done
.not_up:

    cmp al, 's'
    jne .not_down
    add r8, pitch
    jmp .done
.not_down:

    cmp al, 'a'
    jne .not_left
    dec r8
    jmp .done
.not_left:

    cmp al, 'd'
    jne .not_right
    inc r8
    jmp .done
.not_right:

    cmp al, 'q'
    je .exit

    ; Exercise: No interesting input -- read more
    jmp .read_more

.done:
    jmp .main_loop

.exit:
    mov rax, 0x02000001     ; SYS_exit
    mov rdi, 0              ; Exit status
    syscall
