section .bss
request_buffer resb 4096

section .data
response db  "HTTP/1.0 200 OK", 0x0D, 0x0A, 0x0D, 0x0A

section .text
global _start

_start:

;socket syscall
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

;saving the fd
mov r15, rax

;setting up the stack
push rbp
mov rbp, rsp
sub rsp, 0x10

;adding the sockaddr_ip to the stack
mov dword [rsp+4], 0x00000000
mov word [rsp+2], 0x5000
mov word  [rsp], 2


;calling the bind
mov rax, 49
mov rdi, r15
mov rsi, rsp
mov rdx, 0x10
syscall

;fixing the stack
add rsp, 0x10
mov rsp, rbp
pop rbp

;setting the bound socket to listen
mov rax, 50
mov rdi, r15
mov rsi, 0
syscall

;setting the listening socket to accept connections
;
;Because the sockstruct_addr has already been placed into the kernal space and is associated with FD 3 (currently in r15)
;there is no need to re-do the whole stack structrue
;making the syscall
mov rax, 43
mov rdi, r15
mov rsi, 0
mov rdx, 0
syscall
mov r14, rax

;system read
mov rax, 0
mov rdi, r14
lea rsi, [request_buffer]
mov rdx, 4096
syscall

;making the write syscall
;write() writes up to count bytes from the buffer starting at buf
;to the file referred to by the file descriptor fd.
;making the write system call
mov rax, 1
mov rdi, r14
mov rsi, response
mov rdx, 0x13
syscall


;closing that connection
mov rax, 3
mov rdi, r14
syscall

;exit
mov rax, 60
mov rdi, 0
syscall
