.386
.model flat, stdcall
option casemap:none

; --- Khai báo External WinAPI ---
EXTERN GetStdHandle@4 : PROC
EXTERN WriteConsoleA@20 : PROC
EXTERN ReadConsoleA@20 : PROC
EXTERN ExitProcess@4 : PROC

; --- Định nghĩa hằng số ---
STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11
; LƯU Ý: Giữ 100 để khớp với offset -100, -200, -300 bên dưới.
; Nếu muốn 1000, phải tăng stack và sửa offset.
MAX_DIGITS        EQU 100   

.data
    msgPrompt db "Nhap n: ", 0
    msgResult db "So Fibonacci thu n la: ", 0
    newline   db 13, 10, 0

.code

; --- Hàm chuyển chuỗi sang số ---
S_to_i proc
    push ebx
    push ecx
    xor eax, eax
    xor ecx, ecx

convert_loop:
    mov bl, byte ptr[esi]
    cmp bl, 13      ; Check Enter
    je done_convert
    cmp bl, 10      ; Check Line Feed
    je done_convert
    cmp bl, '0'
    jb done_convert
    cmp bl, '9'
    ja done_convert

    sub bl, '0'
    imul eax, eax, 10
    add eax, ebx

    inc esi
    jmp convert_loop

done_convert:
    pop ecx
    pop ebx
    ret
S_to_i endp

; --- Hàm cộng số lớn ---
big_add proc
    push ebp
    mov ebp, esp
    pusha

    mov esi, [ebp + 8]  ; f0
    mov edi, [ebp + 12] ; f1
    mov edx, [ebp + 16] ; fn (res)

    xor ecx, ecx
    xor ebx, ebx        ; Carry

add_loop:
    cmp ecx, MAX_DIGITS
    jge end_add

    mov al, byte ptr[esi + ecx]
    add al, byte ptr[edi + ecx]
    add al, bl

    cmp al, 10
    jl no_carry
    sub al, 10
    mov bl, 1
    jmp store_digits

no_carry:
    mov bl, 0

store_digits:
    mov byte ptr [edx + ecx], al
    inc ecx
    jmp add_loop

end_add:
    popa
    pop ebp
    ret 12
big_add endp

; --- Hàm chính ---
main proc
    push ebp
    mov ebp, esp

    sub esp, 400    ; Cấp phát stack

    push STD_INPUT_HANDLE
    call GetStdHandle@4
    mov edi, eax    ; edi = hstdin

    push STD_OUTPUT_HANDLE
    call GetStdHandle@4
    mov ebx, eax    ; ebx = hstdout

    ; --- In prompt ---
    push 0
    lea eax, [ebp - 336]
    push eax
    push 8
    push offset msgPrompt
    push ebx
    call WriteConsoleA@20

    ; --- Đọc n ---
    lea ecx, [ebp - 332] ; Buffer input
    push 0
    lea eax, [ebp - 336] ; Biến chứa số byte đã đọc
    push eax            
    push 30
    push ecx
    push edi
    call ReadConsoleA@20

    ; --- Xóa mảng (Init 0) ---
    lea edi, [ebp - 300] ; SỬA: stosd dùng EDI, không phải ESI
    xor eax, eax
    mov ecx, 75          ; 75 dwords = 300 bytes
    rep stosd
    
    ; --- Convert n sang số ---
    lea esi, [ebp - 332]
    call S_to_i
    mov edi, eax         ; edi = n

    mov byte ptr [ebp-200], 1 ; f1[0] = 1

    ; Xử lý trường hợp cơ bản
    cmp edi, 0
    je print_result_f0 ; In f0 (0)
    cmp edi, 1
    je print_result_f1 ; In f1 (1)

    ; --- Vòng lặp DP (i = 2 to n) ---
    mov ecx, 2 

main_loop:
    cmp ecx, edi    
    jg end_loop     

    ; Gọi big_add(f0, f1, fn)
    lea eax, [ebp-300] ; FN
    push eax
    lea eax, [ebp-200] ; F1
    push eax
    lea eax, [ebp-100] ; F0
    push eax
    
    call big_add    

    ; Copy F1 -> F0
    push ecx        
    push edi        
    
    lea esi, [ebp-200] 
    lea edi, [ebp-100] 
    mov ecx, MAX_DIGITS
    rep movsb

    ; Copy FN -> F1
    lea esi, [ebp-300] 
    lea edi, [ebp-200] 
    mov ecx, MAX_DIGITS
    rep movsb
    
    pop edi         
    pop ecx         

    inc ecx
    jmp main_loop

end_loop:
    jmp print_result_f1

print_result_f0:
    ; Xử lý in số 0 (để đơn giản ta nhảy tới exit hoặc in thủ công)
    jmp exit_prog

print_result_f1:
    ; --- In kết quả ---
    push 0
    lea eax, [ebp-336]
    push eax
    push 23         
    push offset msgResult
    push ebx
    call WriteConsoleA@20

    ; Tìm vị trí khác 0
    mov ecx, MAX_DIGITS
    dec ecx         
find_nonzero:
    cmp ecx, 0
    jl print_zero   
    mov al, byte ptr [ebp - 200 + ecx] 
    cmp al, 0
    jne start_print
    dec ecx
    jmp find_nonzero

start_print:
print_char_loop:
    mov al, byte ptr [ebp - 200 + ecx]
    add al, '0'     
    
    mov byte ptr [ebp-300], al 
    
    push ecx        
    push ebx        

    push 0          
    lea edx, [ebp-336]
    push edx        
    push 1          
    lea edx, [ebp-300]
    push edx        
    push ebx        
    call WriteConsoleA@20
    
    pop ebx
    pop ecx
    
    dec ecx
    cmp ecx, 0
    jge print_char_loop
    jmp exit_prog

print_zero:
    mov byte ptr [ebp-300], '0'
    push 0
    lea edx, [ebp-336]
    push edx
    push 1
    lea edx, [ebp-300]
    push edx
    push ebx
    call WriteConsoleA@20

exit_prog:
    ; In xuống dòng
    push 0
    lea edx, [ebp-336]
    push edx
    push 2
    push offset newline
    push ebx
    call WriteConsoleA@20

    push 0
    call ExitProcess@4

main endp       ; SỬA: start -> main
end main        ; SỬA: start -> main