section .text



global dotpArrayI64_simple
; rdi: I192* result
; rsi: int64_t* values1
; rdx: int64_t* values2
; rcx: uint64_t length
dotpArrayI64_simple:
    push rdi
    mov rdi, rdx
    xor r11, r11
    xor r8, r8
    xor r9, r9
    xor r10, r10

    jmp .loop_test

.loop:
    mov rax, [rsi + r11 * 8]
    imul QWORD [rdi + r11 * 8]
    add r8, rax
    adc r9, rdx
    adc r10, 0
    add r11, 1
.loop_test:
    cmp r11, rcx
    jl .loop

    pop rax
    mov [rax + 0x00], r8
    mov [rax + 0x08], r9
    mov [rax + 0x10], r10
    ret



global dotpArrayI64_unroll
; rdi: I192* result
; rsi: int64_t* values1
; rdx: int64_t* values2
; rcx: uint64_t length
dotpArrayI64_unroll:
    push rbx
    push rdi
    mov rdi, rdx
    xor ebx, ebx
    xor r11, r11
    xor r8, r8
    xor r9, r9
    xor r10, r10

    jmp .loop_test

align 0x10
.loop:
    mov rax, [rsi + r11 * 8]
    imul QWORD [rdi + r11 * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    mov rax, [rsi + (r11 + 1) * 8]
    imul QWORD [rdi + (r11 + 1) * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    mov rax, [rsi + (r11 + 2) * 8]
    imul QWORD [rdi + (r11 + 2) * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    mov rax, [rsi + (r11 + 3) * 8]
    imul QWORD [rdi + (r11 + 3) * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    add r11, 4
.loop_test:
    cmp r11, rcx
    jl .loop

    pop rax
    mov [rax + 0x00], r8
    mov [rax + 0x08], r9
    mov [rax + 0x10], r10
    pop rbx
    ret



global dotpArrayI64_chain
; rdi: I192* result
; rsi: int64_t* values1
; rdx: int64_t* values2
; rcx: uint64_t length
dotpArrayI64_chain:
    push rbx
    push r12
    push r13
    push r14
    push rdi
    mov rdi, rdx
    xor ebx, ebx
    xor r14, r14
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13

    jmp .loop_test

align 0x10
.loop:
    mov rax, [rsi + r14 * 8]
    imul QWORD [rdi + r14 * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    mov rax, [rsi + (r14 + 1) * 8]
    imul QWORD [rdi + (r14 + 1) * 8]
    add r11, rax
    adc r12, rdx
    adc r13, rbx
    mov rax, [rsi + (r14 + 2) * 8]
    imul QWORD [rdi + (r14 + 2) * 8]
    add r8, rax
    adc r9, rdx
    adc r10, rbx
    mov rax, [rsi + (r14 + 3) * 8]
    imul QWORD [rdi + (r14 + 3) * 8]
    add r11, rax
    adc r12, rdx
    adc r13, rbx
    add r14, 4
.loop_test:
    cmp r14, rcx
    jl .loop

    add r8, r11
    adc r9, r12
    adc r10, r13
    pop rax
    mov [rax + 0x00], r8
    mov [rax + 0x08], r9
    mov [rax + 0x10], r10
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
