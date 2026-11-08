.intel_syntax noprefix
.global itoa
#itoa uses rsi+rax(output) rdi(input), rcx
itoa: #takes the number in rdi and writes it to [rsi+offset], offset in r8 + returns the number of written characters in rax
    mov rax, rdi 	#move input number into rax
    push r8
    add rsi, r8
    mov rcx, 10 	#divisor 10 into rcx
    xor rdx, rdx	#clear regs
    xor r8, r8
    xor r9, r9

    cmp rax, 0	#is the given number negative
    jl is_neg

    test rax, rax 	#is the given number 0
    je zero

    i_loop:
        cmp rax, 0	#is the dividend 0
        je out
        div rcx		#divide by rcx
        add rdx, '0'	#convert remainder to ASCII digit
        push rdx		#push digit
        xor rdx, rdx	#clear register for remainder
        inc r8		#characters counted
        jmp i_loop

    is_neg:
        mov byte ptr [rsi], '-'  #write '-'
        neg rax
        mov r9, 1
        jmp i_loop

    zero:
        add rax, '0'	#itoa conv
        mov [rsi], al	#write char
        mov rax, 1	#one character written
        pop r8
        sub rsi, r8
        ret

    out:
        xor rcx, rcx
        add rdx, r9     #1 to rdx if the number is negative
        add r8, r9  
        poploop:
            cmp rdx, r8	#end loop when pushed count equals popped count
            je i_done
            pop rcx
            mov [rsi+rdx], cl #write char
            inc rdx		#popped count
            jmp poploop

    i_done:
        mov rax, r8	#return number of written chars
        pop r8
        sub rsi, r8
        ret
