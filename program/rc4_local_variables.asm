.386
.model flat, stdcall
option casemap :none
.stack 4096

includelib kernel32.lib

ExitProcess PROTO :DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetProcessHeap PROTO
HeapAlloc PROTO :DWORD, :DWORD, :DWORD
HeapFree PROTO :DWORD, :DWORD, :DWORD

; Các hằng số
STD_INPUT_HANDLE  equ -10
STD_OUTPUT_HANDLE equ -11
NULL    equ 0
MAX_BUFFER  equ 256

.data
    msg1    db "Plaintext: ", 0
    len1    equ $ - msg1
    
    msg2    db "Key: ", 0
    len2    equ $ - msg2

    crlf    db 13, 10, 0

.code

; ---------------------------------------------------------
; InputConsole: Nhập liệu an toàn vào buffer cục bộ
; ---------------------------------------------------------
inputconsole proc
    push ebp
    mov ebp, esp
    pusha                   ; Lưu tất cả thanh ghi

    ; --- Nhập Plaintext ---
    push NULL
    push [ebp+32]           ; &rwCount
    push len1
    push OFFSET msg1
    push [ebp+8]            ; hStdOut
    call WriteConsoleA

    ; --- Đọc Plaintext ---
    push NULL
    push [ebp+20]           ; &textlen
    push MAX_BUFFER
    push [ebp+16]           ; &plaintext
    push [ebp+12]           ; hStdIn
    call ReadConsoleA

    ; Trim CRLF Plaintext
    mov esi, [ebp+20]
    mov eax, [esi]
    cmp eax, 2
    jl  Skip_Trim_Text
    sub eax, 2
    mov [esi], eax
    mov edi, [ebp+16]
    mov byte ptr [edi + eax], 0
Skip_Trim_Text:

    ; --- Nhập Key ---
    push NULL
    push [ebp+32]
    push len2
    push OFFSET msg2
    push [ebp+8]
    call WriteConsoleA

    ; --- Đọc Key ---
    push NULL
    push [ebp+28]           ; &keylen
    push MAX_BUFFER
    push [ebp+24]           ; &key
    push [ebp+12]           ; hStdIn
    call ReadConsoleA

    ; Trim CRLF Key
    mov esi, [ebp+28]
    mov eax, [esi]
    cmp eax, 2
    jl Skip_Trim_Key
    sub eax, 2
    mov [esi], eax
    mov edi, [ebp+24]
    mov byte ptr [edi + eax], 0
Skip_Trim_Key:

    popa
    pop ebp
    ret 28
inputconsole endp

; ---------------------------------------------------------
; S_to_256: Khởi tạo S-box
; ---------------------------------------------------------
S_to_256 proc
    push ebp
    mov ebp, esp
    push esi
    push ecx

    mov esi, [ebp+8]        ; pSBox
    xor ecx, ecx

Loop_Fill:
    cmp ecx, 256
    je Loop_Done
    mov byte ptr [esi + ecx], cl 
    inc ecx
    jmp Loop_Fill

Loop_Done:
    pop ecx
    pop esi
    pop ebp
    ret 4
S_to_256 endp

; ---------------------------------------------------------
; KSA: Key Scheduling Algorithm (Đã sửa lỗi dùng EBP)
; ---------------------------------------------------------
KSA proc 
    push ebp
    mov ebp, esp
    pusha                   ; Lưu EAX, EBX, ECX, EDX, ESI, EDI, EBP...

    mov ecx, [ebp+16]       ; KeyLen
    cmp ecx, 0
    je End_KSA

    mov edi, [ebp+8]        ; S-Box
    mov esi, [ebp+12]       ; Key Buffer

    mov ecx, 256            ; Counter Loop
    xor ebx, ebx            ; j = 0
    xor edx, edx            ; i = 0 (Dùng EDX thay vì ESI để tránh lẫn lộn)

Swap_KSA:
    ; --- Tính: key[i % keylen] ---
    push edx                ; Lưu i
    mov eax, edx            
    xor edx, edx
    div dword ptr [ebp+16]  ; EDX = i % keylen
    
    movzx eax, byte ptr [esi + edx] ; EAX = key[i % len] (Dùng EAX thay EBP)
    pop edx                 ; Khôi phục i về EDX

    ; --- Tính j = (j + S[i] + key) % 256 ---
    add ebx, eax            ; j += key
    movzx eax, byte ptr [edi + edx] ; EAX = S[i]
    add ebx, eax            ; j += S[i]
    and ebx, 0FFh 

    ; --- Swap S[i], S[j] ---
    ; EAX đang chứa S[i] (low byte AL)
    ; Dùng AH để chứa tạm S[j]
    mov ah, byte ptr [edi + ebx]    ; AH = S[j]
    
    mov byte ptr [edi + edx], ah    ; S[i] = S[j]
    mov byte ptr [edi + ebx], al    ; S[j] = S[i]

    inc edx                 ; i++
    dec ecx                 ; counter--
    cmp ecx, 0
    jne Swap_KSA

End_KSA:
    popa
    pop ebp
    ret 12
KSA endp

; ---------------------------------------------------------
; PRGA: Encrypt (Đã sửa lỗi bpl)
; ---------------------------------------------------------
PRGA proc
    push ebp
    mov ebp, esp
    pusha

    mov ecx, [ebp+16]       ; TextLen
    cmp ecx, 0
    je End_PRGA

    mov edx, [ebp+8]        ; S-box Address
    mov edi, [ebp+12]       ; Plaintext Address
    
    xor esi, esi            ; i = 0
    xor ebx, ebx            ; j = 0
    xor ecx, ecx            ; k (index text)

PRGA_Loop:
    ; Kiểm tra vòng lặp: k < TextLen
    ; Lưu ý: KHÔNG ĐƯỢC làm hỏng EBP vì lệnh này cần đọc stack
    cmp ecx, [ebp+16]       
    jae End_PRGA

    ; i = (i + 1) % 256
    inc esi
    and esi, 0FFh

    ; j = (j + S[i]) % 256
    movzx eax, byte ptr [edx + esi] 
    add ebx, eax
    and ebx, 0FFh

    ; --- Swap S[i], S[j] (FIXED: Dùng AH thay vì BPL) ---
    movzx eax, byte ptr [edx + esi] ; AL = S[i], xoá sạch các bit cao
    mov ah, byte ptr [edx + ebx]    ; AH = S[j] (Dùng AH làm temp)
    
    mov byte ptr [edx + esi], ah    ; S[i] = S[j]
    mov byte ptr [edx + ebx], al    ; S[j] = S[i]

    ; --- K = S[ (S[i] + S[j]) % 256 ] ---
    add al, ah                      ; AL = S[i] + S[j]
    and eax, 0FFh                   ; Giữ lại 8 bit, xoá AH để dùng EAX làm index
    
    movzx eax, byte ptr [edx + eax] ; EAX = Keystream byte K

    ; XOR Plaintext
    xor byte ptr [edi + ecx], al

    inc ecx
    jmp PRGA_Loop

End_PRGA:
    popa
    pop ebp
    ret 12
PRGA endp

; ---------------------------------------------------------
; Helper Functions
; ---------------------------------------------------------
NibbleToChar proc
    cmp bl, 9
    ja Is_Letter
    add bl, 30h
    ret
Is_Letter:
    add bl, 37h
    ret
NibbleToChar endp

byte_2_hex proc
    push ebp
    mov ebp, esp
    pusha

    mov esi, [ebp + 16]     ; Src
    mov ecx, [ebp + 12]     ; Len
    mov edi, [ebp + 8]      ; Dest
    
    cmp ecx, 0
    je End_Hex_Func

Hex_Converter_Loop:
    xor eax, eax
    mov al, byte ptr [esi]
    push eax

    mov bl, al
    shr bl, 4
    call NibbleToChar
    mov byte ptr [edi], bl
    inc edi

    pop eax
    mov bl, al
    and bl, 0Fh
    call NibbleToChar
    mov byte ptr [edi], bl
    inc edi

    mov byte ptr [edi], 20h
    inc edi

    inc esi
    dec ecx
    cmp ecx, 0
    jne Hex_Converter_Loop

End_Hex_Func:
    mov byte ptr [edi], 0
    popa
    pop ebp
    ret 12 
byte_2_hex endp

; ---------------------------------------------------------
; Main
; ---------------------------------------------------------
main proc
    ; Biến cục bộ trên Stack
    LOCAL hStdIn:DWORD, hStdOut:DWORD, hHeap:DWORD
    LOCAL pSBox:DWORD, textLen:DWORD, keyLen:DWORD, rwCount:DWORD
    LOCAL txtBuf[256]:BYTE
    LOCAL keyBuf[256]:BYTE
    LOCAL hexBuf[1024]:BYTE

    ; 1. Handles
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, eax
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, eax

    ; 2. Input
    lea eax, rwCount
    push eax
    lea eax, keyLen
    push eax
    lea eax, keyBuf
    push eax
    lea eax, textLen
    push eax
    lea eax, txtBuf
    push eax
    push hStdIn
    push hStdOut
    call inputconsole

    ; 3. Heap Alloc S-box
    call GetProcessHeap
    mov hHeap, eax
    push 256
    push 8
    push hHeap
    call HeapAlloc
    mov pSBox, eax

    ; 4. Init & KSA
    push pSBox
    call S_to_256

    push keyLen
    lea eax, keyBuf
    push eax
    push pSBox
    call KSA

    ; 5. PRGA
    push textLen
    lea eax, txtBuf
    push eax
    push pSBox
    call PRGA

    ; 6. Hex Output
    lea eax, txtBuf
    push eax
    push textLen
    lea eax, hexBuf
    push eax
    call byte_2_hex

    mov eax, textLen
    mov ebx, 3
    mul ebx
    
    push NULL
    lea ecx, rwCount
    push ecx
    push eax
    lea eax, hexBuf
    push eax
    push hStdOut
    call WriteConsoleA

    push NULL
    lea ecx, rwCount
    push ecx
    push 2
    push offset crlf
    push hStdOut
    call WriteConsoleA

    ; 7. Cleanup
    push pSBox
    push 0
    push hHeap
    call HeapFree

    ; Pause
    push NULL
    lea eax, rwCount
    push eax
    push 1
    lea eax, txtBuf
    push eax
    push hStdIn
    call ReadConsoleA

    push 0
    call ExitProcess
main endp

end main