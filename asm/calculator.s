.intel_syntax noprefix
.global _start
_start:
    sub rsp, 32 #reserve space for itoa output
    mov r12, 1  #count of written numbers, starts at one because line 10
    mov rsi, rsp   #point rsi at reserved space for itoa
    cmp byte ptr [rsp+32], 3
    je unary
    cmp byte ptr [rsp+32], 4
    je binary

unary:
    mov rbx, [rsp+56]
    call atoi
    mov rbx, [rsp+48]
    cmp byte ptr [rbx], '-'
    je neg_op
    cmp byte ptr [rbx], '~'
    je not_op
    
    jmp unkn_operator
    
binary:
    mov rbx, [rsp+48] #read pointer to first argument, args begin at rsp+48
    call atoi		#output in rdi
    mov rdx, rdi
    push rdx	#save rdx
    mov rbx, [rsp+72] #second number to parse
    call atoi		#output in rdi
    mov rbx, [rsp+64] #operator
    pop rdx	#restore rdx
    cmp byte ptr [rbx], '+'
    je add
    cmp byte ptr [rbx], '-'
    je subtr
    cmp byte ptr [rbx], '*'
    je mult
    cmp byte ptr [rbx], '^'
    je xor_op
    cmp byte ptr [rbx], '|'
    je or_op
    cmp byte ptr [rbx], '&'
    je and_op
    
    jmp unkn_operator
    
unkn_operator:
    mov rdi, 11
    mov rax, 60
    syscall

done:
    call itoa
    call write
    add rsp, 32	#restore reserved stack space
    mov rax, 60
    mov rdi, 0
    syscall     #exit

add:
    add rdi, rdx
    jmp done

subtr:
    sub rdx, rdi
    mov rdi, rdx
    jmp done

mult:
    imul rdi, rdx
    jmp done
    
xor_op:
    xor rdx, rdi
    mov rdi, rdx
    jmp done
    
or_op:
    or rdx, rdi
    mov rdi, rdx
    jmp done
    
and_op:
    and rdx, rdi
    mov rdi, rdx
    jmp done
    
neg_op:
    neg rdi
    jmp done
    
not_op:
    not rdi
    jmp done

#atoi uses rcx, rdx, rax, rdi(output) + rbx(pointer to string)
atoi:
    xor rcx, rcx #clear, NTS: clears only registers that would not otherwise be reset, e.g. by mov
    mov rax, rbx
    xor rdi, rdi
    cmp byte ptr [rax], '-' 	#is the first character '-'?
    jne a_loop				#if not, then skip to the loop
    mov rcx, 1 #Mark number as negative
    inc rax

    a_loop:
        movzx rdx, byte ptr [rax] 	#move char to a register from memory
        sub rdx, '0'	#atoi convert
        cmp rdx, 9	#check if the converted value is above 9, to exit at all non-number characters or null
        ja convneg
        imul rdi, 10 	#multiply total
        add rdi, rdx 	#add converted char to total
        inc rax 		#move to next char
        jmp a_loop

    convneg:
test rcx, rcx 	#is the number marked negative?
        je a_done
        neg rdi		 #negate rdi

    a_done:
        ret

#itoa uses rsi+rax(output) rdi(input), rcx, r8,
itoa: #takes the number in rdi and writes it to [rsi] + returns written char count in rax
    mov rax, rdi 	#move input number into rax
    mov rcx, 10 	#load divisor 10 into rcx
    xor rdx, rdx	#clear regs
    xor r8, r8
    xor r9, r9

    cmp rax, 0	#is the input number negative?
    jl is_neg

    test rax, rax 	#is the input number zero?
    je zero

    i_loop:
        cmp rax, 0	#is dividend zero
        je out
        div rcx		#divide by rcx
        add rdx, '0'	#convert remainder to ASCII digit
        push rdx		#push digit onto stack
        xor rdx, rdx	#clear remainder register
        inc r8		#characters counted
        jmp i_loop

    is_neg:
        mov byte ptr [rsi], '-'  #write '-'
        neg rax
        mov r9, 1
        jmp i_loop

    zero:
        add rax, '0'	#itoa convert
        mov [rsi], al	#write char
        mov rax, 1	#one character written
        ret

    out:
        xor rcx, rcx
        add rdx, r9 #add 1 to rdx if the number is negative
        add r8, r9  
        poploop:
            cmp rdx, r8	#end loop when pushed count equals popped count
            je i_done
            pop rcx     #load char from temp buffer into rcx
            mov [rsi+rdx], cl #write char
            inc rdx		#popped count
            jmp poploop

    i_done:
        mov rax, r8	#return number of written characters
        ret

write:
    #mov byte ptr [rsi+rdx], '\n'   #uncomment for newline
    #inc rax                        #uncomment for newline
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret
