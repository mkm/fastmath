section .text



global addArrayI64_simple
; rdi: int64_t* values
; rsi: uint64_t length
addArrayI64_simple:
; rcx: i
; r10: result.low
; r11: result.high
    xor ecx, ecx
    xor r10, r10
    xor r11, r11

    jmp .loop_test

.loop:
    mov rax, [rdi + rcx * 8]
    cqo
    add r10, rax
    adc r11, rdx
    add rcx, 1
.loop_test:
    cmp rcx, rsi
    jl .loop

    mov rax, r10
    mov rdx, r11

    ret



global addArrayI64_aligned
; rdi: int64_t* values
; rsi: uint64_t length
addArrayI64_aligned:
; rcx: i
; r10: result.low
; r11: result.high
    xor ecx, ecx
    xor r10, r10
    xor r11, r11

    jmp .loop_test

align 0x10
.loop:
    mov rax, [rdi + rcx * 8]
    cqo
    add r10, rax
    adc r11, rdx
    add rcx, 1
.loop_test:
    cmp rcx, rsi
    jl .loop

    mov rax, r10
    mov rdx, r11

    ret



global addArrayI64_unroll
; rdi: int64_t* values
; rsi: uint64_t length
addArrayI64_unroll:
; rcx: i
; r10: result.low
; r11: result.high
    xor ecx, ecx
    xor r10, r10
    xor r11, r11
    test rsi, 1
    jz .loop_test
    mov rax, [rdi]
    cqo
    add r10, rax
    adc r11, rdx
    add rcx, 1
    jmp .loop_test

align 0x10
.loop:
    mov rax, [rdi + rcx * 8]
    cqo
    add r10, rax
    adc r11, rdx
    mov rax, [rdi + (rcx + 1) * 8]
    cqo
    add r10, rax
    adc r11, rdx
    add rcx, 2
.loop_test:
    cmp rcx, rsi
    jl .loop
.loop_end:

    mov rax, r10
    mov rdx, r11

    ret



global addArrayI64_unrollmore
; rdi: int64_t* values
; rsi: uint64_t length
addArrayI64_unrollmore:
; rcx: i
; r10: result.low
; r11: result.high
    xor ecx, ecx
    xor r10, r10
    xor r11, r11
    mov rax, rsi
    and rax, 3
    jz .loop_test
    sub rax, 4
    sub rsi, rax
    lea rdi, [rdi + rax * 8]
    cmp rax, -1
    je .loop1
    cmp rax, -2
    je .loop2
    jmp .loop3

align 0x10
.loop:
    mov rax, [rdi + (rcx + 0) * 8]
    cqo
    add r10, rax
    adc r11, rdx
.loop1:
    mov rax, [rdi + (rcx + 1) * 8]
    cqo
    add r10, rax
    adc r11, rdx
.loop2:
    mov rax, [rdi + (rcx + 2) * 8]
    cqo
    add r10, rax
    adc r11, rdx
.loop3:
    mov rax, [rdi + (rcx + 3) * 8]
    cqo
    add r10, rax
    adc r11, rdx
    add rcx, 4
.loop_test:
    cmp rcx, rsi
    jl .loop
.loop_end:

    mov rax, r10
    mov rdx, r11

    ret



; extern mpn_add_1
; global addArrayI64_gmp
; ; rdi: int64_t* values
; ; rsi: uint64_t length
; addArrayI64_gmp:
;     push rbp
;     push rbx
;     push r12
; 
;     mov rbp, rdi
;     xor ebx, ebx
;     mov r12, rsi
; 
;     jmp .loop_test
; .loop:
;     lea rdi, [rsp - 0x10]
;     mov rsi, rdi
;     mov rdx, 2
;     mov rcx, [rbp + rbx * 8]
;     call mpn_add_1
; .loop_test:
;     cmp rbx, r12
;     jl .loop
; 
;     mov rax, [rsp - 0x10]
;     mov rdx, [rsp - 0x08]
;     pop rbx
;     pop rbp
;     ret
