.intel_syntax noprefix
.global _start
_start:
mov rdi, 2		#AF_INET
mov rsi, 1		#SOCK_STREAM
mov rdx, 0    	#protocol
mov rax, 41 
syscall		    #socket
mov rbx, rax	#save socket fd

sub rsp, 16
mov word ptr [rsp], 0x0002
mov word ptr [rsp+2], 0x5000
mov dword ptr [rsp+4], 0x00000000
mov qword ptr [rsp+8], 0x0000000000000000
mov rsi, rsp	#pointer to sockaddr struct

add rsp, 16
mov rdx, 16	#address length
mov rdi, rbx	#sockfd
mov rax, 49	#bind
syscall

mov rdi, rbx
mov rsi, 0		#backlog
mov rax, 50	    #listen
syscall

parent:

mov rdi, rbx
mov rdx, 0
mov rsi, 0
mov rax, 43
syscall		    #accept
mov r12, rax	#save accepted socket fd

mov rax, 57
syscall		    #fork

cmp rax, 0
je child

mov rdi, r12
mov rax, 3
syscall		    #close child fd

jmp parent

child:

mov rdi, rbx
mov rax, 3
syscall		    #close parent fd

sub rsp, 128
mov rdi, r12	#sockfd to read from
mov rsi, rsp	#buffer to empty stack
mov rdx, 256	#chars to read
mov rax, 0
syscall		    #read
add rsp, 128


lea rdi, [rsi+4]	#find requested file path in HTTP request line; read stores "GET /path HTTP/1.0..." at rsi, skip "GET "
pathendloop:
cmp byte ptr [rdi], 0x20
je out
inc rdi
jmp pathendloop
out:
mov byte ptr [rdi], 0
lea rdi, [rsi+4]
mov rsi, 0
mov rax, 2
syscall		#open	
mov r13, rax	#save file descriptor

mov rdi, r13	#fd to read from
lea rsi, [rsp-512]#buffer to empty stack
mov rdx, 256	#chars to read
mov rax, 0
syscall		#read
push rsi
push rax		#save bytes read count

mov rdi, r13	#fd to close
mov rax, 3
syscall		#close

lea rsi, [rsp-256]
mov rcx, 0x302E312F50545448			#
mov qword ptr [rsi], rcx			#
mov rcx, 0x0D4B4F2030303220			#write HTTP/1.0 200 OK\r\n\r\n
mov qword ptr [rsi+8], rcx			#
mov dword ptr [rsi+16], 0x000A0D0A	#
mov rdx, 19	#characters to read
mov rdi, r12	#connected fd
mov rax, 1
syscall		#write HTTP OK response

pop rax		#restore saved byte count
pop rsi
mov rdi, r12	#write to connected fd
mov rdx, rax	#chars to write, returned by read
mov rax, 1
syscall		#write file contents

mov rdi, 0		#exit code
mov rax, 60
syscall		#exit
