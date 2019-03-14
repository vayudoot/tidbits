bits 64
default rel

section .data

d dq 0

section .text
global main

main:
	; Baseline: mov mem, reg works well
	mov byte [d], al
	mov word [d], ax
	mov dword [d], eax
	mov qword [d], rax

	; mov mem, imm does not work:
	mov byte [d], 5 ; off by 1
	mov word [d], 5 ; off by 2
	mov dword [d], 5 ; off by 4
	mov qword [d], 5 ; off by 4

	; All of the following are off by 1:
	and byte [d], 5
	and word [d], 5
	and dword [d], 5
	and qword [d], 5

	or word [d], 5
	xor word [d], 5

	add word [d], 5
	sub word [d], 5

	; No problem when second operand is reg
	and byte [d], al
	and word [d], ax
	and dword [d], eax
	and qword [d], rax

	; No problem when mem is second operand:
	and al, [d]
	and ax, [d]
