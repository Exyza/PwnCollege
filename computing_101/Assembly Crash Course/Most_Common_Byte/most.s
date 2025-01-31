.intel_syntax noprefix
.global _start
_start:

xor r12, r12
xor r11, r11
dec rsi
mov rbp, rsp
sub rsp, 0x100
while_Loop_1:
cmp r12, rsi
jg second_Section
mov r11, [rdi+r12]
sub rsp, r11
add byte ptr [rsp], 1
inc r12
jmp while_Loop_1

second_Section:
xor r9, r9
xor r8, r8
xor r15, r15
while_Loop_2:
cmp r9, rbp
jg end_Of_Program
cmp rsp, r8
jle increment
sub rsp, r9
mov r8, [rsp]
mov r15, r9
increment:
inc r9
jmp while_Loop_2

end_Of_Program:
mov rsp, rbp
mov rax, r15
ret
