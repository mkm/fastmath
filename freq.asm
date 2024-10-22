section .text



global freq
; rdi: uint64_t count
freq:
    xor eax, eax
    xor ecx, ecx
    jmp .loop_test

align 0x10
.loop:
    add eax, 1
    add eax, 1
    add eax, 1
    add eax, 1
    add eax, 1
    add eax, 1
    add eax, 1
    add eax, 1
    add ecx, 8
.loop_test:
    cmp ecx, edi
    jne .loop

    ret
