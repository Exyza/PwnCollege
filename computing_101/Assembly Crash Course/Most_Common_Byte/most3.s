.intel_syntax noprefix
.global _start
_start:
push rbp
mov rbp, rsp
sub rsp, 0x300
push r12
push r13
push r14

xor r12, r12
xor r13, r13
xor r14, r14
xor rax, rax

dec rsi
while_Loop1:
cmp r12, rsi
ja section_Two

mov r13, [rdi+r12]
lea rax, [rbp-0x100]
movzx r14, r13b
add byte ptr [rax+r14], 1
inc r12
jmp while_Loop1

section_Two:
xor r12, r12
xor r13, r13
xor r14, r14
xor rax, rax

while_Loop2:
cmp r12, 0x100
ja epilouge

lea rax, [rbp-0x100]
cmp byte ptr [rax+r12], r13b
jbe skip

movzx r13, byte ptr [rax+r12]
mov r14, r12

skip:
inc r12
jmp while_Loop2

epilouge:
xor rax, rax
mov rax, r14
pop r14
pop r13
pop r12
mov rsp, rbp
pop rbp
ret
