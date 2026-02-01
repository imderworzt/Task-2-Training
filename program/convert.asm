.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

extern ExitProcess@4: PROC
extern GetStdHandle@4: PROC
extern WriteConsoleA@20: PROC
extern ReadConsoleA@20: PROC
extern GetProcessHeap@0: PROC
extern HeapAlloc@12: PROC
extern HeapFree@12: PROC

ExitProcess    EQU ExitProcess@4
GetStdHandle   EQU GetStdHandle@4
WriteConsoleA  EQU WriteConsoleA@20
ReadConsoleA   EQU ReadConsoleA@20
GetProcessHeap EQU GetProcessHeap@0
HeapAlloc      EQU HeapAlloc@12
HeapFree       EQU HeapFree@12

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11
HEAP_ZERO_MEMORY  EQU 8

.data
    msginput    db "Nhap so thap phan: ", 0
    msgbase     db "Nhap co so (2-36): ", 0
    msgnewline  db 13, 10, 0
    digitsmap   db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0 

.code
StrLen proc
    push edi
    mov edi, eax
    xor eax, eax
    scan_loop:
        cmp byte ptr [edi + eax], 0
        je done_len
        inc eax
        jmp scan_loop
    done_len:
    pop edi
    ret
StrLen endp

Outputconsole proc
    push ebp
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + 12]
    call StrLen
    mov ecx, eax

    push 0
    lea eax, [ebp - 4]
    push eax
    push ecx
    push [ebp + 12]
    push [ebp + 8]
    call WriteConsoleA

    mov esp, ebp
    pop ebp
    ret 8 
Outputconsole endp

inputconsole proc
    push ebp
    mov ebp, esp
    sub esp, 4          

    push 0              
    lea eax, [ebp - 4]  
    push eax            
    push [ebp + 16]     
    push [ebp + 12]     
    push [ebp + 8]      
    call ReadConsoleA

    mov ecx, [ebp - 4]      
    mov edi, [ebp + 12]     
    
    mov byte ptr [edi + ecx], 0 

    test ecx, ecx           
    jz finish_read          

    mov al, byte ptr [edi + ecx - 1]
    cmp al, 10
    jne check_cr            
    mov byte ptr [edi + ecx - 1], 0
    dec ecx                
    jz finish_read

    check_cr:
    mov al, byte ptr [edi + ecx - 1]
    cmp al, 13
    jne finish_read
    mov byte ptr [edi + ecx - 1], 0

    finish_read:
    mov esp, ebp
    pop ebp
    ret 12
inputconsole endp

atoi proc
    push ebx
    push esi
    mov esi, eax
    xor eax, eax
    xor ebx, ebx

    conver_loop:
        mov bl, byte ptr[esi]
        test bl, bl
        jz convert_done

        cmp bl, '0'
        jl skip_char
        cmp bl, '9'
        jg skip_char 

        sub bl, '0'
        imul eax, eax, 10
        add eax, ebx

    skip_char:
        inc esi
        jmp conver_loop

    convert_done:
    pop esi
    pop ebx 
    ret
atoi endp

push_stack proc
    push ebp
    mov ebp, esp
    push ebx
    push esi

    call GetProcessHeap
    mov ebx, eax

    push 8
    push HEAP_ZERO_MEMORY
    push ebx
    call HeapAlloc

    test eax, eax
    je push_exit

    mov ecx, [ebp + 12]
    mov [eax], ecx        

    mov esi, [ebp + 8]    
    mov edx, [esi]        
    mov [eax + 4], edx    

    mov [esi], eax        

    push_exit:
    pop esi
    pop ebx
    pop ebp
    ret 8
push_stack endp

pop_stack proc
    push ebp
    mov ebp, esp
    push esi
    push ebx
    push edi

    mov esi, [ebp + 8]    
    mov edi, [esi]        

    test edi, edi
    je pop_empty

    mov ebx, [edi]        

    mov eax, [edi + 4]    
    mov [esi], eax        

    push ebx              
    call GetProcessHeap
    push edi
    push 0
    push eax
    call HeapFree
    pop ebx              
    mov eax, ebx          
    jmp pop_done

    pop_empty:
        mov eax, 0
    
    pop_done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 4
pop_stack endp

BaseConvert proc
    push ebp
    mov ebp, esp
    sub esp, 8 
    push ebx
    push esi 
    push edi

    mov DWORD ptr [ebp - 4], 0 
    
    mov eax, [ebp + 8] 
    mov ebx, [ebp + 12]

    test eax, eax
    jnz div_loop_start  

    push 0
    lea ecx, [ebp - 4]
    push ecx
    call push_stack
    jmp pop_phase

    div_loop_start:
    
    div_loop:
        test eax, eax
        jz pop_phase

        xor edx, edx
        div ebx


        push eax       
        
        push edx       
        lea ecx, [ebp - 4]
        push ecx
        call push_stack

        pop eax         

        jmp div_loop

    pop_phase:

    pop_next:
        cmp DWORD ptr [ebp - 4], 0 
        je done_convert

        lea ecx, [ebp - 4]
        push ecx
        call pop_stack

        lea esi, digitsmap
        mov al, byte ptr [esi + eax] 

        mov byte ptr [ebp - 8], al
        mov byte ptr [ebp - 7], 0   

        lea ecx, [ebp - 8]
        push ecx
        push [ebp + 16]
        call Outputconsole

        jmp pop_next

    done_convert:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp 
    pop ebp
    ret 12
BaseConvert endp

main proc
    push ebp
    mov ebp, esp
    sub esp, 100

    push STD_INPUT_HANDLE
    call GetStdHandle
    mov [ebp - 4], eax  

    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [ebp -8], eax 

    lea eax, msginput
    push eax
    push [ebp - 8]
    call Outputconsole

    push 30
    lea eax, [ebp - 40]
    push eax
    push [ebp - 4]
    call inputconsole

    lea eax, [ebp - 40]
    call atoi
    mov [ebp - 84], eax

    lea eax, msgbase
    push eax
    push [ebp - 8]
    call Outputconsole

    push 10
    lea eax, [ebp - 80]
    push eax
    push [ebp - 4]
    call inputconsole

    lea eax, [ebp - 80]
    call atoi
    mov [ebp - 88], eax 

    cmp eax, 2
    jl exit_app
    cmp eax, 36
    jg exit_app

    push [ebp-8]           
    push [ebp-88]           
    push [ebp-84]           
    call BaseConvert

    lea eax, msgnewline
    push eax
    push [ebp - 8]
    call Outputconsole

    exit_app:
    push 0
    call ExitProcess
main endp
end main