; --------------------------------------------------------------------------- ;
; ffge_64i8.s: Perform FFGE on 8 packed matrices.                             ;
;                                                                             ;
; Copyright 2024 ⧉⧉⧉                                                          ;
;                                                                             ;
; This program is free software: you can redistribute it and/or modify it     ;
; under the terms of the GNU General Public License as published by the       ;
; Free Software Foundation, either version 3 of the License, or (at your      ;
; option) any later version.                                                  ;
;                                                                             ;
; This program is distributed in the hope that it will be useful, but         ;
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  ;
; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License    ;
; for more details.                                                           ;
;                                                                             ;
; You should have received a copy of the GNU General Public License along     ;
; with this program.  If not, see <https://www.gnu.org/licenses/>.            ;
; --------------------------------------------------------------------------- ;
[bits 64]
default rel

global ffge_32i8

section .rodata

mag_const	dq -9223372032559808509

section .text

	extern	ffge_32i8_pivot, ffge_32i8_modprim

ffge_32i8:
	push	r14
	push	r13
	push	r12
	push	rbx
	push	rbp
	mov	rbp, rsp
	sub	rsp, 0x80
	and	rsp, -0x20

	mov	-0x08[rbp], rdi		; size_t n
	mov	qword -0x10[rbp], 0	; size_t pc: pivot column index

	mov	r12, rdi
	shl	r12, 5			; row length in bytes
	mov	r13, r12
	imul	r13, rdi		; packed matrix size

	mov	rbx, rsi		; int64_t *m

	xor	rax, rax		; pivot col offset
	xor	rcx, rcx		; pivot row offset
	vpbroadcastq ymm14, [mag_const]
	vpxor	ymm15, ymm15

	; todo: vectorize pivot
.l0:	push	rax
	push	rcx
	mov	rdi, -0x08[rbp]
	mov	rsi, rbx
	mov	rcx, -0x10[rbp]
	mov	rdx, -0x10[rbp]
	call 	ffge_32i8_pivot
	pop	rcx
	pop	rax

	mov	rsi, rcx
	add	rsi, rax
	vmovdqa ymm0, [rbx + rsi]
	vpsllq	ymm1, ymm0, 4

	mov	r8, rcx
	add	r8, r12
.l1:	mov	rsi, r8
	add	rsi, rax
	vmovdqa	ymm2, [rbx + rsi]
	vpsllq  ymm3, ymm1, 4

	mov	r9, rax
	add	r9, 0x20
.l2:	mov	rdi, rcx
	add	rdi, r9
	vmovdqa ymm4, [rbx + rdi]
	vpsllq	ymm5, ymm3, 4
	mov	rdi, r8
	add	rdi, r9
	vmovdqa	ymm6, [rbx + rdi]
	vpsllq	ymm7, ymm6, 4

	vpmuldq	ymm0, ymm0, ymm6
	vpmuldq	ymm1, ymm1, ymm7
	vpmuldq	ymm2, ymm2, ymm4
	vpmuldq	ymm3, ymm3, ymm5
	vpsubq	ymm0, ymm0, ymm2
	vpsubq	ymm1, ymm1, ymm3

	; todo: vectorize modulo magic prime
	vmovdqa	[rsp], ymm0
	vmovdqa 0x20[rsp], ymm1
	push	rax
	push	rcx
	push	r8
	push	r9
	push	rsi
	push	rdi
	lea	rdi, [rsp]
	lea	rsi, 0x40[rsp]
	call	ffge_32i8_modprim
	pop	rdi
	pop	rsi
	pop	r9
	pop	r8
	pop	rcx
	pop	rax
	vmovdqa	ymm0, 0x40[rsp]

	vmovdqa	[rbx + rdi], ymm0
	add	r9, 0x20
	cmp	r9, r12
	jb	.l2

	vmovdqa	[rbx + rsi], ymm15
	add	r8, r12
	cmp	r8, r13
	jb	.l1

	add	qword -0x10[rbp], 1
	add	rax, 0x20
	add	rcx, r12
	cmp	rcx, r13
	jb	.l0

	vzeroupper
	xor	rax, rax

	mov	rsp, rbp
	pop	rbp
	pop	rbx
	pop	r12
	pop	r13
	pop	r14
	ret

