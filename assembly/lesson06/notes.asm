bits 64
default rel

section .data

; OS-defined stuff:

SYS_write       equ 0x02000004
SYS_read        equ 0x02000003
SYS_exit        equ 0x02000001
SYS_ioctl       equ 0x02000000 + 54
SYS_fcntl       equ 0x02000000 + 92
SYS_select      equ 0x02000000 + 93

STDIN_FILENO    equ 0
STDOUT_FILENO   equ 1

TIOCGETP    equ 0x40067408
TIOCSETP    equ 0x80067409

CBREAK      equ 0x00000002  ; half-cooked mode
ECHO        equ 0x00000008  ; echo input
RAW         equ 0x00000020  ; echo input

; /usr/include/sys/filio.h
F_GETFL     equ 0x00000003
F_SETFL     equ 0x00000004
O_NONBLOCK  equ 0x00000004

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


; Application-stuff:

width           equ 80
height          equ 25
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


board_pos:  db 27, '[25A'
board:  full_line

        %rep height - 2
        hollow_line
        %endrep

        full_line

board_size equ $-board
board_pos_size equ $-board_pos


input_char db 0


state:
    istruc sgttyb
        at sgttyb.sg_ispeed,  db 0
        at sgttyb.sg_ospeed,  db 0
        at sgttyb.sg_erase,   db 0
        at sgttyb.sg_kill,    db 0
        at sgttyb.sg_flags,   db 0
    iend

stored_flags dw 0


timeout:
    istruc timeval
        at timeval.tv_sec,  dq 0
        at timeval.tv_nsec, dq 100000
    iend


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

    ; Start out at the center of the board (40, 13):
    mov r8, board + 40 + 13*pitch
    mov r9, 1
    sub r8, r9

    mov rax, SYS_write
    mov rdi, STDOUT_FILENO  ; filedes
    mov rsi, board          ; buf
    mov rdx, board_size     ; nbyte
    syscall

.main_loop:
    add r8, r9
    cmp byte [r8], ' '
    jne .exit

    mov byte [r8], 'O'      ; Write head into board

    mov rax, SYS_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, 0
    syscall

    mov rax, SYS_write
    mov rdi, STDOUT_FILENO  ; filedes
    mov rsi, board_pos      ; buf
    mov rdx, board_pos_size ; nbyte
    syscall

    cmp rax, board_pos_size
    jne .exit


    mov rax, SYS_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, O_NONBLOCK
    syscall


    push r8
    mov rax, SYS_select
    mov rdi, 0              ; nfds
    mov rsi, 0              ; readfds
    mov rdx, 0              ; writefds
    mov rcx, 0              ; errorfds
    mov r8, timeout         ; timeout
    syscall
    pop r8


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
    mov r9, -pitch
    jmp .read_more
.not_up:

    cmp al, 's'
    jne .not_down
    mov r9, pitch
    jmp .read_more
.not_down:

    cmp al, 'a'
    jne .not_left
    mov r9, -1
    jmp .read_more
.not_left:

    cmp al, 'd'
    jne .not_right
    mov r9, 1
    jmp .read_more
.not_right:

    cmp al, 'q'
    je .exit

    jmp .read_more

.done:
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
