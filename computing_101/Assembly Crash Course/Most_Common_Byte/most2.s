.intel_syntax noprefix
.global _start
_start:

xor r12, r12
xor r11, r11
xor r10, r10

mov rbp, rsp
sub rsp, 0x100


sub rsi, 1
loop_1:
cmp r12, rsi
jg next_Step

mov r11b, byte ptr [rdi+r12]

mov r10, rbp
sub r10b, r11b
add r10, 1

xor r10, r10
inc r12
jmp loop_1

next_Step:
xor r13, r13
xor r12, r12
xor r11, r11
xor r10, r10

mov r13, rbp

loop_2:
cmp r12, 0xff
jg the_End
sub r13, r12
cmp [r13], r11
jle iteration_Time


mov r11, [r13]

sub r13, r12
mov r10, r13
xor r13, r13
mov r13, rbp

iteration_Time:
inc r12
jmp loop_2


the_End:
xor rax, rax
mov rsp, rbp
mov al, r10b
ret
