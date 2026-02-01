.386
.model flat, stdcall
option casemap :none
.stack 4096

includelib kernel32.lib

; Khai bao cac ham API
ExitProcess PROTO :DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

STD_INPUT_HANDLE  equ -10
STD_OUTPUT_HANDLE equ -11
NULL    equ 0

.data
    msg1    db "Nhap n (Fibonacci): ", 0
    len1    equ $ - msg1
    newline db 10, 13, 0

    ; Buffer
    inputBuf  db 32 dup(0)
    outputBuf db 32 dup(0)

    hStdIn  dd ?
    hStdOut dd ?
    bytesRW dd ? 

.code

; --- Thu tuc nhap lieu ---
inputconsole proc  
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, eax

    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, eax

    ; In thong bao
    push NULL
    push OFFSET bytesRW
    push len1
    push OFFSET msg1
    push hStdOut
    call WriteConsoleA

    ; Nhap du lieu
    push NULL
    push OFFSET bytesRW
    push 15             
    push OFFSET inputBuf
    push hStdIn
    call ReadConsoleA
    
    ret
inputconsole endp

; --- Thu tuc chuyen String sang Int ---
atoi proc
    xor eax, eax    ; Ket qua
    xor ecx, ecx    ; Bien tam chua ky tu
    mov ebx, 10     ; He so nhan
    mov esi, OFFSET inputBuf ; Tro vao buffer input

atoi_loop:
    mov cl, [esi]   ; Lay 1 ky tu
    cmp cl, 13      ; Check Enter (CR)
    je done_atoi
    cmp cl, 10      ; Check Enter (LF)
    je done_atoi
    cmp cl, 0       ; Check Null
    je done_atoi
    
    cmp cl, '0'     ; 30h
    jl done_atoi
    cmp cl, '9'     ; 39h
    jg done_atoi

    sub cl, '0'     ; 30h
    mul ebx         
    add eax, ecx   
    inc esi
    jmp atoi_loop

done_atoi:
    ret
atoi endp

; --- Thu tuc chuyen Int sang String ---
itoa proc
    mov esi, OFFSET outputBuf
    add esi, 30           
    mov byte ptr [esi], 0   
    mov ebx, 10            
    xor ecx, ecx           

    cmp eax, 0              
    jne itoa_loop
    dec esi
    mov byte ptr [esi], '0'
    mov ecx, 1
    jmp done_itoa

itoa_loop:
    xor edx, edx
    div ebx                
    add dl, 30h             
    dec esi
    mov [esi], dl
    inc ecx                
    test eax, eax
    jnz itoa_loop

done_itoa:
    mov eax, esi           ; Tra ve dia chi chuoi
    ret
itoa endp

; --- Thu tuc de quy Fibonacci ---
; Input: EAX = n
; Output: EAX = fib(n)
Fibonacci proc
    cmp eax, 1
    jbe fib_done        ; Neu n <= 1, tra ve n (trong EAX)

    push eax            ; Luu n hien tai vao Stack [ESP]
    dec eax             ; n = n - 1
    call Fibonacci      ; Goi de quy: Tinh fib(n-1)
    
    ; Sau khi goi xong, EAX dang chua fib(n-1)
    push eax            ; Luu ket qua fib(n-1) vao Stack [ESP]. (Luu y: n cu~ bay gio la [ESP+4])

    mov eax, [esp + 4]  ; Lay lai gia tri n ban dau
    sub eax, 2          ; n = n - 2
    call Fibonacci      ; Goi de quy: Tinh fib(n-2)

    ; Bay gio EAX chua fib(n-2)
    pop ebx             ; Lay fib(n-1) da luu ra khoi Stack bo vao EBX
    add eax, ebx        ; EAX = fib(n-2) + fib(n-1)

    add esp, 4          ; Don Stack (Bo gia tri n da luu ban dau)
    ret

fib_done:
    ret
Fibonacci endp

; --- Chuong trinh chinh ---
main proc
    call inputconsole   

    call atoi           ; Ket qua n nam trong EAX

    call Fibonacci      ; Goi thu tuc Fibonacci rieng biet
                        ; Ket qua tra ve nam trong EAX

    call itoa           ; Chuyen EAX thanh chuoi de in
    
    ; In ket qua ra man hinh
    push NULL               
    push OFFSET bytesRW     
    push ecx                ; Do dai chuoi (tu itoa tra ve)
    push eax                ; Buffer chuoi (tu itoa tra ve)
    push hStdOut            
    call WriteConsoleA

    ; In xuong dong
    push NULL
    push OFFSET bytesRW
    push 2
    push OFFSET newline 
    push hStdOut
    call WriteConsoleA

    push 0
    call ExitProcess

main endp

end main