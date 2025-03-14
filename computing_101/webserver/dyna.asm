;---------------------------------------------------------------------------
;	Section for uninitialized variables
section .bss	
request_buffer resb 4096		;Sets the variable request_buffer to a byte array of 4096
filepath resb 16					;Filepath that we will be reading
dataToSend resb 4096			;Data that we will send

;---------------------------------------------------------------------------
;	Section for initialized variables
section .data
response db  "HTTP/1.0 200 OK", 0x0D, 0x0A, 0x0D, 0x0A		;Declares the byte variable response

;---------------------------------------------------------------------------
;	Section for actual code
section .text
global _start	;Label for the start of the program
_start:

;---------------------------------------------------------------------------
;	Socket syscall
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

;---------------------------------------------------------------------------
;	Saving the fd :: This is important for identifying the socket
mov r15, rax

;---------------------------------------------------------------------------
;	Setting up the stack :: for the sockaddr_ip struct that will go into bind
push rbp
mov rbp, rsp
sub rsp, 0x10 ; 0x10 is for stack alignment

;---------------------------------------------------------------------------
;	Adding the sockaddr_ip struct to the stack (first two vars are in big endian)
mov dword [rsp+4], 0x00000000
mov word [rsp+2], 0x5000
mov word [rsp], 2

;---------------------------------------------------------------------------
;	Calling the bind system call
mov rax, 49
mov rdi, r15
mov rsi, rsp ;	Where the sockaddr_ip structure is
mov rdx, 0x10 ;	Reads 16 bytes
syscall

;---------------------------------------------------------------------------
;	Returning the stack to its origional state
add rsp, 0x10
mov rsp, rbp
pop rbp

;---------------------------------------------------------------------------
;	Using the listen() system call to set the bound socket into listen mode
mov rax, 50
mov rdi, r15
mov rsi, 0
syscall

;---------------------------------------------------------------------------
;	Using the accept() system call to accept connections onto the socket
;	Because the sockstruct_addr has already been placed into the kernal space and is associated with FD 3 (currently in r15), there is no need to re-do the whole stack structure ::
;	Making the syscall
mov rax, 43
mov rdi, r15
mov rsi, 0
mov rdx, 0
syscall

;---------------------------------------------------------------------------
;	Saving the file descriptor returned by accept()
;	This is a new socket connection and this file descriptor will be used to identify this open connection
mov r14, rax

;---------------------------------------------------------------------------
;	Using system read() to read from the socket into the byte array |request_buffer|
mov rax, 0
mov rdi, r14
lea rsi, [request_buffer]
mov rdx, 4096
syscall

;---------------------------------------------------------------------------
; Using the open() system call to open the file specified in the request buffer
; We will have to use a loop to loop over the varaible that contains the entire request, from base + 4 to the next space


;********************************************
;	This is the loop
xor rdx, rdx	;	This is the counter
lea rsi, [request_buffer + 4 + rdx]	;	Loading the base address of where we want to read from
lea rcx, [filepath]	;	Loading the base address of where we want to write to
read_Filepath:
mov al, [rsi + rdx]	;	Moving a byte from base + counter into rax
cmp rax, 0x20	;	Checking that it isn't a space
je open_File	;	If it is a space, jump to the open
mov [rcx + rdx], al ; Moving the byte into the variable base + counter
inc rdx	;	Incrementing the counter
jmp read_Filepath	;	Jumping back to the beginning of the loop

;********************************************
open_File:
mov rax, 2
mov rdi, filepath	;	So this works? It is reading what is directly in the filepath variable
mov rsi, 0
syscall
mov r13, rax ;	Saving the new FD for the file

;---------------------------------------------------------------------------
;	read() syscall is used to read from the file into the varaible
mov rax, 0
mov rdi, r13
mov rsi, dataToSend
mov rdx, 4096
syscall
mov r12, rax	;	Number of bytes that were read THIS WILL BE IMPORTANT WHEN WE ARE WRITING

;---------------------------------------------------------------------------
;	Closing the file descriptor
mov rax, 3
mov rdi, r13
syscall



;---------------------------------------------------------------------------
;	Using the write() system call to write to the socket
;		Write() writes up to count bytes from the buffer starting at buf
;		to the file referred to by the file descriptor fd.
;	This is the HTTP response
mov rax, 1
mov rdi, r14
lea rsi, [response]
mov rdx, 0x13
syscall

;---------------------------------------------------------------------------
;	Using the write() system call to write to the socket
;		Write() writes up to count bytes from the buffer starting at buf
;		to the file referred to by the file descriptor fd.
;	This is the data response
mov rax, 1
mov rdi, r14
lea rsi, [dataToSend]
mov rdx, r12
syscall

;---------------------------------------------------------------------------
;	Closing the file descriptor
mov rax, 3
mov rdi, r14
syscall

;---------------------------------------------------------------------------
; Using exit() to exit the program cleanly
mov rax, 60
mov rdi, 0
syscall
