.intel_syntax noprefix
.global atoi
#atoi uses rcx, rdx, rdi(output) + rax(pointer to string)
atoi:
    xor rcx, rcx #clear, NTS: clears only registers that would not otherwise be reset, e.g. by mov
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
        add rdi, rdx    #add converted digit to total
        inc rax 		#move to next char
        jmp a_loop

    convneg:
        test rcx, rcx 	#is the number marked negative?
        je a_done
        neg rdi		 #negate rdi

    a_done:
        ret
