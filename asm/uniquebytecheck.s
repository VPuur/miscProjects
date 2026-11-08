.intel_syntax noprefix
.global solve
solve:
sub rsp, 256 #reserve 256 bits

#clear registers
mov rax, 0
mov rcx, 0
mov rbx, 0

clear:		#clear reserved frame
cmp rcx, 256
je check
mov byte ptr [rsp+rcx], 0
inc rcx
jmp clear

check:		#check loop
movzx rcx, byte ptr [rdi]
cmp rbx, rsi	#have all bits been checked
je count
mov byte ptr [rsp+rcx], 1	#write 1 to the corresponding stack location if not
inc rdi	#move checker address
inc rbx	#amount of bits checked
jmp check

count:
mov rcx, 0 #offset from new stack base
co_loop:	#count loop
cmp rcx, 256
je done
cmp byte ptr [rsp+rcx], 0 #is the address being checked 0
jne increment
inc rcx	#no? add 1 to check offset
jmp co_loop

increment:
inc rax #final return
inc rcx #1 to check offset
jmp co_loop

done:
#reset used registers
mov rbx, 0
mov rcx, 0
add rsp, 256 #return the bits
ret