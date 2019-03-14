bits 64
default rel


; System defines:

SYS_write       equ 0x02000004
SYS_read        equ 0x02000003
SYS_exit        equ 0x02000001
SYS_ioctl       equ 0x02000000 + 54

STDIN_FILENO    equ 0
STDOUT_FILENO   equ 1

TIOCGETP        equ 0x40067408
TIOCSETP        equ 0x80067409

CBREAK          equ 0x00000002  ; half-cooked mode
ECHO            equ 0x00000008  ; echo input

struc sgttyb
    .sg_ispeed: resb    1
    .sg_ospeed: resb    1
    .sg_erase:  resb    1
    .sg_kill:   resb    1
    .sg_flags:  resw    1
endstruc


; Program defines:

width           equ 80
pitch           equ width + 1


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


section .data

board:  full_line

        %rep 25
        hollow_line
        %endrep

        full_line

board_size equ $-board


section .bss

; The multiplication by two is there to work around a bug in nasm: http://bugzilla.nasm.us/show_bug.cgi?id=3392231
state           resb sgttyb_size * 2

; Exercise: Use this to store the original sg_flags value
stored_flags    resw 1

input_char      resb 1

section .text
global main

main:
    mov rax, SYS_ioctl
    mov rdi, STDIN_FILENO
    mov rsi, TIOCGETP
    mov rdx, state
    syscall

    mov ax, [state + sgttyb.sg_flags]
    mov [stored_flags], ax ; Exercise: Store the original sg_flags
    and ax, ~ECHO
    or ax, CBREAK
    mov [state + sgttyb.sg_flags], ax

    mov rax, SYS_ioctl
    mov rdi, STDIN_FILENO
    mov rsi, TIOCSETP
    mov rdx, state
    syscall


    ; Start out at the center of the board (40, 13):
    mov r8, board + 40 + 13*pitch

.main_loop:
    cmp byte [r8], ' '
    jne .exit

    mov byte [r8], 'O'      ; Write head into board

    mov rax, SYS_write
    mov rdi, STDOUT_FILENO  ; filedes
    mov rsi, board          ; buf
    mov rdx, board_size     ; nbyte
    syscall

.read_more:
    mov rax, SYS_read
    mov rdi, STDIN_FILENO   ; filedes
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

    jmp .read_more

.done:
    jmp .main_loop

.exit:
    ; Exercise: Restore the original sg_flags
    mov ax, [stored_flags]
    mov [state + sgttyb.sg_flags], ax

    mov rax, SYS_ioctl
    mov rdi, STDIN_FILENO
    mov rsi, TIOCSETP
    mov rdx, state
    syscall

    mov rax, SYS_exit
    mov rdi, 0              ; Exit status
    syscall
