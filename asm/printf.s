.intel_syntax noprefix
.global _start
.extern atoi
#atoi uses rcx, rdx, rdi(output) + rax(pointer to string)
.extern itoa
#itoa uses (rsi+r8),rax(output) rdi(input), rcx, r8
_start:
    sub rsp, 32
    mov rsi, rsp    #point rsi at the output buffer

    mov r10, 72     #arg[2+] pointers start at rsp+72 at runtime

    call scan   #actual program
    call write

    done: 
        mov rdi, 0
        mov rax, 60
        add rsp, 32
        syscall

#uses rdx(output), rax, r8, r9 
scan:
    xor rdx, rdx
    xor r8, r8
    mov rax, [rsp+56]       #rax=pointer ekaan argumenttiin

    s_loop:
        xor r9, r9	#clear
        cmp byte ptr [rax+rdx], 0	#end of string?
        je s_done

        cmp byte ptr [rax+rdx], 0x5c #slash?
        je slash
        cmp byte ptr [rax+rdx], 0x25
        je marker

        mov r9b, byte ptr [rax+rdx]	#load char from memory into temporary register
        mov byte ptr [rsi+r8], r9b		#store char from temporary register into buffer
        inc rdx	#next char
        inc r8	#chars written
        jmp s_loop

    s_done:
        ret

    slash:
        inc rdx #next char
        cmp byte ptr [rax+rdx], 0x5c #escape?
        je esc_s
        cmp byte ptr [rax+rdx], 'n'	#newline?
        je newline
        cmp byte ptr [rax+rdx], 'x' #hex?
        je hex
        
        esc_s:
            inc rdx #next char
            mov byte ptr [rsi+r8], 0x5c	#write backslash
            inc r8	#chars written
            jmp s_loop

        newline:
            inc rdx #next char
            mov byte ptr [rsi+r8], 0x0A #write newline
            inc r8	#chars written
            jmp s_loop

        hex:
            push r9
            push r10
            xor rcx, rcx
            inc rdx
            h_loop:
                cmp rcx, 2
                je h_write
                cmp byte ptr [rax+rdx], '9'
                jl h_int
                h_n1:
                cmp byte ptr [rax+rdx], 'F'
                jl h_uppercase
                h_n2:
                cmp byte ptr [rax+rdx], 'f' 
                jl h_lowercase

                h_int:
                    cmp byte ptr [rax+rdx], '0'
                    jl h_n1
                    movzx r10, byte ptr [rax+rdx]  #load next char into temporary register
                    sub r10, '0'    #convert to numeric value
                    cmp rcx, 0      #are we on the first hex digit?
                    je h_int_fir

                    h_int_sec:
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop

                    h_int_fir:
                        shl r10, 4  #shift bits left by 4
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop

                h_uppercase:
                    cmp byte ptr [rax+rdx], 'A'
                    jl h_n2
                    movzx r10, byte ptr [rax+rdx]  #load next char into temporary register
                    sub r10, 'A'    #convert uppercase hex digit--
                    add r10, 10     #--to numeric value
                    cmp rcx, 0      #are we on the first hex digit?
                    je h_upper_fir

                    h_upper_sec:
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop
                    
                    h_upper_fir:
                        shl r10, 4  #shift bits left by 4
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop

                h_lowercase:
                    cmp byte ptr [rax+rdx], 'a'
                    jl h_error
                    movzx r10, byte ptr [rax+rdx]  #load next char into temporary register
                    sub r10, 'a'    #convert lowercase hex digit--
                    add r10, 10     #--to numeric value
                    cmp rcx, 0      #are we on the first hex digit?
                    je h_lower_fir

                    h_lower_sec:
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop

                    h_lower_fir:
                        shl r10, 4  #shift bits left by 4
                        add r9, r10 #add to result
                        inc rcx     #iteration counter
                        inc rdx     #next char
                        jmp h_loop

                    h_error:
                        push r11        #
                        add r11, 2      #
                        sub r11, rcx    #adjust rdx by the number of hex chars already consumed
                        add rdx, r11    #
                        pop r11         #

                        pop r10
                        pop r9
                        jmp s_loop

                h_write:
                    mov byte ptr [rsi+r8], r9b
                    inc r8
                    pop r10
                    pop r9
                    jmp s_loop

    marker:
        inc rdx  #next char
        cmp byte ptr [rax+rdx], 0x25 #escape?
        je esc_p
        cmp byte ptr [rax+rdx], 'd' #decimal marker?
        je decimal
        cmp byte ptr [rax+rdx], 's' #string marker?
        je string
        
        esc_p:
            inc rdx #next char
            mov byte ptr [rsi+r8], 0x25	#write percent sign
            inc r8	#chars written
            jmp s_loop

        decimal:
            inc rdx #next char
            push rax    #save pointer to current argument
            mov rax, [rsp+r10]  #load pointer to selected argument
            cmp byte ptr [rsp+48], 2    #only one argument provided? (+program name)
            je insufficient_args 

            push rdx    #save registers
            push r8
            push r9

            call atoi   #convert argument string to integer
            call itoa   #convert integer back to ASCII and write it into buffer

            pop r9
            pop r8
            pop rdx     #restore registers

            add r8, rax #rax contains number of chars written by itoa
            pop rax
            add r10, 8
            jmp s_loop

        string:
            inc rdx #next char
            push rax
            mov rax, [rsp+r10]
            push rdx
            xor rdx, rdx

            sarg_loop:
                xor r9, r9  #clear for next char
                cmp byte ptr [rax+rdx], 0
                je string_done

                mov r9b, byte ptr [rax+rdx]	#load char from memory into temporary register
                mov byte ptr [rsi+r8], r9b		#store char from temporary register into buffer
                inc r8  #chars written +1
                inc rdx #next char
                jmp sarg_loop

            string_done:
                pop rdx
                pop rax
                add r10, 8
                jmp s_loop

            insufficient_args:
                call write
                mov rdi, 11
                mov rax, 60
                add rsp, 32
                syscall

write:
    mov rdx, r8 #number of chars to write
    mov rdi, 1 
    mov rax, 1 
    syscall 
    ret
