bits 64
default rel


; System defines:

SYS_write       equ 0x02000004
SYS_read        equ 0x02000003
SYS_exit        equ 0x02000001
SYS_ioctl       equ 0x02000000 + 54
SYS_fcntl       equ 0x02000000 + 92
SYS_select      equ 0x02000000 + 93

STDIN_FILENO    equ 0
STDOUT_FILENO   equ 1

TIOCGETP        equ 0x40067408
TIOCSETP        equ 0x80067409

CBREAK          equ 0x00000002  ; half-cooked mode
ECHO            equ 0x00000008  ; echo input

; /usr/include/sys/filio.h
F_SETFL         equ 0x00000004
O_NONBLOCK      equ 0x00000004

struc sgttyb
    .sg_ispeed: resb    1
    .sg_ospeed: resb    1
    .sg_erase:  resb    1
    .sg_kill:   resb    1
    .sg_flags:  resw    1
endstruc

struc timeval
    .tv_sec:    resq    1
    .tv_nsec:   resq    1
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

move_up db 0x1b, '[27A' ; Keep number in string equal to height + 2

board:  full_line

        %rep 25
        hollow_line
        %endrep

        full_line

board_size equ $-board
move_up_then_board_size equ $-move_up

timeout:
    istruc timeval
        at timeval.tv_sec,  dq 0
        at timeval.tv_nsec, dq 100000
    iend

section .bss

state           resb sgttyb_size
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
    mov [stored_flags], ax
    and ax, ~ECHO
    or ax, CBREAK
    mov [state + sgttyb.sg_flags], ax

    mov rax, SYS_ioctl
    mov rdi, STDIN_FILENO
    mov rsi, TIOCSETP
    mov rdx, state
    syscall


    mov rax, SYS_write
    mov rdi, STDOUT_FILENO  ; filedes
    mov rsi, board          ; buf
    mov rdx, board_size     ; nbyte
    syscall

    ; Start out at the center of the board (40, 13):
    mov r14, board + 40 + 13*pitch
    mov r15, 1
    sub r14, r15

.main_loop:
    add r14, r15
    cmp byte [r14], ' '
    jne .exit

    mov byte [r14], 'O'      ; Write head into board

    mov rax, SYS_write
    mov rdi, STDOUT_FILENO  ; filedes
    mov rsi, move_up        ; buf
    mov rdx, move_up_then_board_size ; nbyte
    syscall

    mov rax, SYS_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, O_NONBLOCK
    syscall

    mov rax, SYS_select
    mov rdi, 0              ; nfds
    mov rsi, 0              ; readfds
    mov rdx, 0              ; writefds
    mov rcx, 0              ; errorfds
    mov r8, timeout         ; timeout
    syscall

.read_more:
    mov rax, SYS_read
    mov rdi, STDIN_FILENO   ; filedes
    mov rsi, input_char     ; buf
    mov rdx, 1              ; nbyte
    syscall

    cmp rax, 1
    jne .done

    mov al, [input_char]

    cmp al, 'w'
    jne .not_up
    mov r15, -pitch
    jmp .done
.not_up:

    cmp al, 's'
    jne .not_down
    mov r15, pitch
    jmp .done
.not_down:

    cmp al, 'a'
    jne .not_left
    mov r15, -1
    jmp .done
.not_left:

    cmp al, 'd'
    jne .not_right
    mov r15, 1
    jmp .done
.not_right:

    cmp al, 'q'
    je .exit

    jmp .read_more

.done:
    mov rax, SYS_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, 0
    syscall

    jmp .main_loop

.exit:
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
