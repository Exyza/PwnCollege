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

parentLoop:	;	This is where the parent process will loop back too
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
;	Logic for the fork
;	The parent and the child will be split
;	The parent process (identified by rax being greater than 0) will close the new connection socket on the fd in r14
;		It will then jump back to accepting connections
;	The child process (identified by rax being equal to 0) will close the connection socket that accepts connections, and move foreward in the program with the connected socket FD
;		It will follow the code accordingly and then exit
mov rax, 57
syscall
cmp rax, 0
je childProcess
jg parentProcess

parentProcess:
;---------------------------------------------------------------------------
;	Closing the file descriptor
mov rax, 3
mov rdi, r14
syscall
jmp parentLoop

childProcess:
;---------------------------------------------------------------------------
;	Closing the file descriptor
mov rax, 3
mov rdi, r15
syscall

;---------------------------------------------------------------------------
;	Using system read() to read from the socket into the byte array |request_buffer|
mov rax, 0
mov rdi, r14
lea rsi, [request_buffer]
mov rdx, 4096
syscall
mov r15, rax

;---------------------------------------------------------------------------
;	Read through the byte array to see if it is a GET or a POST
xor rdx, rdx
xor rax, rax
lea rsi, [request_buffer]
readLoop:
mov al, byte [rsi + rdx]
cmp al, 0x20
je chooseLogic
inc rdx
jmp readLoop

chooseLogic:
cmp rdx, 3
je getTime
jne postTime

getTime:

;********************************************
;	This is the loop
xor rdx, rdx	;	This is the counter
lea rsi, [request_buffer + 4 + rdx]	;	Loading the base address of where we want to read from
lea rcx, [filepath]	;	Loading the base address of where we want to write to
readFilepathGet:
mov al, [rsi + rdx]	;	Moving a byte from base + counter into rax
cmp rax, 0x20	;	Checking that it isn't a space
je openFileGet	;	If it is a space, jump to the open
mov [rcx + rdx], al ; Moving the byte into the variable base + counter
inc rdx	;	Incrementing the counter
jmp readFilepathGet	;	Jumping back to the beginning of the loop

;********************************************
openFileGet:
mov rax, 2
mov rdi, filepath	;	So this works? It is reading what is directly in the filepath variable
mov rsi, 0
syscall
mov r13, rax ;	Saving the new FD for the file

;---------------------------------------------------------------------------
;	read() syscall is used to read from the file into the variable
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

postTime:

;---------------------------------------------------------------------------
; Using the open() system call to open the file specified in the request buffer
; We will have to use a loop to loop over the varaible that contains the entire request, from base + 4 to the next space


;********************************************
;	This is the loop
xor rdx, rdx	;	This is the counter
lea rsi, [request_buffer + 5 + rdx]	;	Loading the base address of where we want to read from
lea rcx, [filepath]	;	Loading the base address of where we want to write to
readFilepathPost:
mov al, [rsi + rdx]	;	Moving a byte from base + counter into rax
cmp al, 0x20	;	Checking that it isn't a space
je openFilePost	;	If it is a space, jump to the open
mov [rcx + rdx], al ; Moving the byte into the variable base + counter
inc rdx	;	Incrementing the counter
jmp readFilepathPost	;	Jumping back to the beginning of the loop

;********************************************
openFilePost:
mov rax, 2
mov rdi, filepath	;	So this works? It is reading what is directly in the filepath variable
mov rsi, 0x41
mov edx, 0x1FF
syscall
mov r13, rax ;	Saving the new FD for the now open/created file


;The problem is: I need to read know the content length of the body so that I can properly read the data into the now open file
;1. start a counter
;2. load the address of request_buffer
;3. BEGIN LOOP
;4. read 1 byte from the buffer into a register
;5. compare this byte to \r (0x0D)
;   1) If it is not this, increment the counter by 1 and jump back to the beginning of the loop
;7. if it is \n, see if the next byte is \n (0x0A)
;   1) If it is not this, increment the counter by 1 and jump back to the beginning of the loop
;9. if it is \r, see if the next byte is \r
;   1) If it is not this, increment the counter by 1 and jump back to the beginning of the loop
;11. if it is, see if the next byte is \n
;   1) If it is not this, increment the counter by 1 and jump back to the beginning of the loop
;13. If all 4 checks are passed, record the number of bytes
;
xor rdx, rdx	;	This is the counter
lea rsi, [request_buffer]	;	This is where we will start reading from
loopThree:
xor rax, rax
mov al, [rsi + rdx]
cmp al, 0x0D
jne endOfLoop
xor rax, rax
mov al, [rsi + rdx + 1]
cmp al, 0x0A
jne endOfLoop
xor rax, rax
mov al, [rsi + rdx + 2]
cmp al, 0x0D
jne endOfLoop
xor rax, rax
mov al, [rsi + rdx + 3]
cmp al, 0x0A
jne endOfLoop
add rdx, 4
mov rcx, rdx
jmp writeToFile

endOfLoop:
inc rdx
jmp loopThree

writeToFile:
mov rax, 1
mov rdi, r13
lea rsi, [request_buffer + rcx]
sub r15, rcx
mov rdx, r15
syscall

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
; Using exit() to exit the program cleanly
mov rax, 60
mov rdi, 0
syscall
