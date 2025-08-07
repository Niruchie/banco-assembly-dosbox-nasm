; This program creates a simple bank menu application for a .COM executable in DOS.
; It uses 16-bit assembly and INT 21h for I/O operations.
; It's a complete, commented version that addresses the logical errors
; and missing functionality of the original code.

[bits 16]
org 0x100
jmp start

; --- Data Section ---
; This section stores all the messages and variables used by the program.
section .data
    ; --- Menu Options ---
    opt1_crear_cuenta        db 10, 13, "1. Crear cuenta$"
    opt2_ver_detalles        db 10, 13, "2. Ver cuenta$"
    opt3_editar              db 10, 13, "3. Editar cuenta$"
    opt4_retirar             db 10, 13, "4. Retirar dinero$"
    opt5_depositar           db 10, 13, "5. Depositar dinero$"
    opt6_salir               db 10, 13, "6. Salir$"

    ; --- General Messages ---
    titulo_banco_msg         db "--- Banco en Assembly ---$"
    menu_return              db 10, 13, "Presione <Enter> para volver al menu...$"
    imsg                     db 10, 13, "Opcion: $"
    enter_name_prompt        db 10, 13, "Ingrese el nombre de la cuenta (max 20 caracteres): $"
    enter_pin_prompt         db 10, 13, "Ingrese un PIN de 4 digitos: $"
    account_created_msg      db 10, 13, "Cuenta creada exitosamente!$"
    option_not_impl_msg      db 10, 13, "Funcion no implementada. Vuelva al menu.$"
    invalid_option_msg       db 10, 13, "Opcion invalida. Intente de nuevo.$"
    account_exists_msg       db 10, 13, "Ya existe una cuenta. No se puede crear otra.$"
    account_not_exist_msg    db 10, 13, "No hay una cuenta creada. Intente de nuevo.$"
    details_title_msg        db 10, 13, "--- Detalles de la cuenta ---$"
    account_name_label       db 10, 13, "Nombre: $"
    account_pin_label        db 10, 13, "PIN: $"
    account_balance_label    db 10, 13, "Saldo: $"
    dollar_sign              db "$$" ; To print the dollar symbol
    enter_deposit_prompt     db 10, 13, "Ingrese la cantidad a depositar: $"
    enter_withdraw_prompt    db 10, 13, "Ingrese la cantidad a retirar: $"
    deposit_success_msg      db 10, 13, "Deposito exitoso!$"
    withdraw_success_msg     db 10, 13, "Retiro exitoso!$"
    insufficient_funds_msg   db 10, 13, "Saldo insuficiente.$"
    reset_success_msg        db 10, 13, "Cuenta restablecida exitosamente!$"
    edit_success_msg         db 10, 13, "Cuenta editada exitosamente!$"
	pin_mismatch_msg         db 10, 13, "PIN incorrecto. Intente de nuevo.$"
    error_overflow_input_msg db 10, 13, "Numero demasiado grande. Intente de nuevo.$"
    error_char_input_msg     db 10, 13, "Entrada invalida. Solo se permiten digitos.$"
    error_no_accepted_funds_msg db 10, 13, "Error: Fondos no aceptados, tienes mucho dinero.$"

    ; --- Account Storage ---
    account_exists_flag      db 0       ; 0 = no account, 1 = account exists
    account_name             times 21 db 0 ; Max 20 chars + '$' terminator
    account_pin              times 5 db 0   ; 4 digits + '$' terminator
    account_balance          dw 0           ; A 16-bit double word for the balance

    ; --- Temporary Variables ---
	pin_buffer               times 5 db 0   ; Buffer for PIN input (4 digits + '$')
    number_buffer            times 6 db 0   ; Buffer for number to str (max 5 digits + '$')
    temp_buffer              times 21 db 0  ; Buffer for reading input (max 20 chars + '$')
    temp_number              dw 0           ; Temporary number storage

; --- Code Section ---
section .text
start:
    jmp menu_loop

; # region Menu Functions
display_menu:
    mov dx, titulo_banco_msg
    mov ah, 9
    int 21h
    mov dx, opt1_crear_cuenta
    mov ah, 9
    int 21h
    mov dx, opt2_ver_detalles
    mov ah, 9
    int 21h
    mov dx, opt3_editar
	mov ah, 9
	int 21h
	mov dx, opt4_retirar
	mov ah, 9
	int 21h
	mov dx, opt5_depositar
	mov ah, 9
	int 21h
    mov dx, opt6_salir
    mov ah, 9
    int 21h
    mov dx, imsg
    mov ah, 9
    int 21h
    ret
get_option:
	; Read user option
    mov ah, 1
    int 21h
    sub al, '0' ; Convert ASCII digit to number
	ret
invalid_option:
    mov dx, invalid_option_msg
    mov ah, 9
    int 21h
    jmp return_to_menu
return_to_menu:
    mov dx, menu_return
    mov ah, 9
    int 21h
    mov ah, 1
    int 21h
    jmp menu_loop
menu_loop:
    call clear_screen
    call display_menu
	call get_option
    
    ; Compare with options and jump to the correct handler
    cmp al, 1
    je create_account
    cmp al, 2
    je view_account
    cmp al, 3
    je edit_account
    cmp al, 4
    je retirar_dinero
    cmp al, 5
    je depositar_dinero
    cmp al, 6
    je exit_program

    ; If not a valid option, fall through to invalid_option
    jmp invalid_option
    
; # endregion




create_account:
	; Check if account already exists
	call check_account_exists
	cmp al, 1
	je account_exists

	; Prompt for account name
	mov dx, enter_name_prompt
	mov ah, 9
	int 21h

	; Read account name
	mov cx, 20 ; Max 20 characters
	mov dx, account_name
	call store_string_to_address

	; Prompt for account PIN
	mov dx, enter_pin_prompt
	mov ah, 9
	int 21h

	; Read account PIN
	mov cx, 4 ; 4 digits for PIN
	mov dx, account_pin
	call store_string_to_address

	; Initialize account balance to 0
	mov dword [account_balance], 0

	; Set account exists flag
	call activate_account
	jmp return_to_menu

view_account:
	; Check if account exists
	call check_account_exists
	cmp al, 0
	je account_not_exists

	; Display account details
	mov dx, details_title_msg
	mov ah, 9
	int 21h

	; Account Name
	mov dx, account_name_label
	mov ah, 9
	int 21h

	mov dx, account_name
	mov ah, 9
	int 21h

	; Account PIN
	mov dx, account_pin_label
	mov ah, 9
	int 21h
	
	mov dx, account_pin
	mov ah, 9
	int 21h

	; Account Balance
	mov dx, account_balance_label
	mov ah, 9
	int 21h
	
	mov ax, [account_balance]
	mov si, number_buffer
	call number_to_string
	mov dx, number_buffer
	mov ah, 9
	int 21h

	jmp return_to_menu

edit_account:
	; Check if account exists
	call check_account_exists
	cmp al, 0
	je account_not_exists

	; Ask for pin to edit account
	call ask_for_pin
	cmp al, 0
	je account_pin_incorrect

	; Prompt for account name
	mov dx, enter_name_prompt
	mov ah, 9
	int 21h

	; Read account name
	mov cx, 20 ; Max 20 characters
	mov dx, account_name
	call store_string_to_address

	; Prompt for account PIN
	mov dx, enter_pin_prompt
	mov ah, 9
	int 21h

	; Read account PIN
	mov cx, 4 ; 4 digits for PIN
	mov dx, account_pin
	call store_string_to_address

	; Confirm edit success
	mov dx, edit_success_msg
	mov ah, 9
	int 21h

	jmp return_to_menu

retirar_dinero:
    ; Verificar si la cuenta existe
    call check_account_exists
    cmp al, 0
    je account_not_exists

    ; Pedir PIN para depositar dinero
    call ask_for_pin
    cmp al, 0
    je account_pin_incorrect

    ; Pedir monto a retirar
    mov dx, enter_withdraw_prompt
    mov ah, 9
    int 21h

    ; Leer monto a retirar
    mov cx, 5 ; Max 5 digits
    mov dx, number_buffer
    call store_string_to_address

    mov dx, number_buffer
    mov ah, 9
    int 21h

    ; Convertir el monto a número
    mov si, number_buffer        ; SI = * Punter al buffer de entrada
    mov di, temp_number          ; DI = * Punter al número temporal
    call texto_a_numero          ; Convertir texto a número
    cmp bx, 2
    je error_overflow_input
    cmp bx, 1
    je error_char_input

    ; Restar el monto del saldo de la cuenta
    clc                          ; Limpiar bandera de acarreo
    mov ax, [account_balance]    ; Cargar saldo actual
    cmp ax, [temp_number]        ; Comparar saldo con monto a retirar
    jl error_insufficient_funds  ; Si saldo < monto, saldo insuficiente
    sub ax, [temp_number]        ; Restar monto del saldo
    mov [account_balance], ax    ; Guardar nuevo saldo

    mov dx, withdraw_success_msg
    mov ah, 9
    int 21h

    jmp return_to_menu

depositar_dinero:
    ; Verificar si la cuenta existe
    call check_account_exists
    cmp al, 0
    je account_not_exists

    ; Pedir PIN para depositar dinero
    call ask_for_pin
    cmp al, 0
    je account_pin_incorrect

    ; Pedir monto a depositar
    mov dx, enter_deposit_prompt
    mov ah, 9
    int 21h

    ; Leer monto a depositar
    mov cx, 5 ; Max 5 digits
    mov dx, number_buffer
    call store_string_to_address

    ; Convertir el monto a número
    mov si, number_buffer        ; SI = * Punter al buffer de entrada
    mov di, temp_number          ; DI = * Punter al número temporal
    call texto_a_numero          ; Convertir texto a número
    cmp bx, 2
    je error_overflow_input
    cmp bx, 1
    je error_char_input

    ; Sumar el monto al saldo de la cuenta
    clc                        ; Limpiar bandera de acarreo
    mov ax, [account_balance]  ; Cargar saldo actual
    add ax, [temp_number]      ; Sumar monto a saldo
    jc error_no_accepted_funds ; Si hay acarreo, saldo insuficiente

    mov [account_balance], ax  ; Guardar nuevo saldo
    mov dx, deposit_success_msg
    mov ah, 9
    int 21h

    jmp return_to_menu

; --- Utility Routines ---
error_insufficient_funds:
    mov dx, insufficient_funds_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

error_no_accepted_funds:
    mov dx, error_no_accepted_funds_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

error_overflow_input:
	mov dx, error_overflow_input_msg
	mov ah, 9
	int 21h
	jmp return_to_menu

error_char_input:
    mov dx, error_char_input_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

ask_for_pin:
	; Prompt for PIN
	mov dx, enter_pin_prompt
	mov ah, 9
	int 21h

	; Read PIN
	mov cx, 4 ; 4 digits for PIN
	mov dx, pin_buffer
	call store_string_to_address

    lea si, pin_buffer     ; Puntero al PIN ingresado
    lea di, account_pin    ; Puntero al PIN almacenado

.compare_loop:
    lodsb                  ; Cargar byte de [SI] en AL y avanzar SI
    cmp al, [di]           ; Comparar con byte de [DI]
    jne .pin_mismatch      ; Si no son iguales, falla
    inc di
    cmp al, '$'            ; ¿Llegamos al final de la cadena?
    jne .compare_loop      ; Si no, seguir comparando

.pin_match:
    mov al, 1
    ret

.pin_mismatch:
    mov al, 0
    ret

account_pin_incorrect:
	mov dx, pin_mismatch_msg
	mov ah, 9
	int 21h
	jmp return_to_menu
account_not_exists:
	cmp byte [account_exists_flag], 0
	mov dx, account_not_exist_msg
	mov ah, 9
	int 21h
	jmp return_to_menu
account_exists:
	cmp byte [account_exists_flag], 1
	mov dx, account_exists_msg
	mov ah, 9
	int 21h
	jmp return_to_menu
activate_account:
	mov byte [account_exists_flag], 1
	mov dx, account_created_msg
	mov ah, 9
	int 21h
	ret
check_account_exists:
	mov al, [account_exists_flag]
	ret

store_string_to_address:
    ; Store a string from the input buffer to a specific address
    ; CX = size of the string
    ; DX = address to store the string
    push ax
    push bx
    mov bx, dx ; Store destination address in BX
.next_char:
    cmp cx, 0       ; Check if we've reached the maximum characters
    je .done_input   ; If CX=0, we're done
    mov ah, 1
    int 21h
    cmp al, 13      ; Enter key
    je .done_input
    mov byte [bx], al
    inc bx
    dec cx          ; Decrease character count manually
    jmp .next_char   ; Continue reading without using loop instruction
.done_input:
    mov byte [bx], '$' ; Null-terminate the string
    pop bx
    pop ax
    ret


number_to_string:
    ; Entradas:
    ;   AX = número de 16 bits a convertir
    ;   SI = dirección del buffer donde se escribirá la cadena
    ;
    ; Salidas:
    ;   El número como cadena decimal ASCII en [SI]
    ;   Terminada en '$' (para impresión con int 21h, AH=09h)

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov     di, si          ; DI = puntero al buffer destino
    mov     bx, 10          ; Divisor (base 10)
    xor     cx, cx          ; CX = contador de dígitos

.convert_loop:
    xor     dx, dx          ; Limpiar DX antes de dividir
    div     bx              ; AX ÷ 10 → AX = cociente, DX = resto
    add     dl, '0'         ; Convertir resto a carácter ASCII
    push    dx              ; Guardar carácter en la pila
    inc     cx              ; Contar dígito
    test    ax, ax
    jnz     .convert_loop   ; Repetir mientras AX > 0

.output_loop:
    pop     ax              ; Recuperar carácter ASCII
    stosb                   ; Escribir en [DI], avanzar DI
    loop    .output_loop

    mov     byte [di], '$'  ; Terminador estilo DOS

    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret


texto_a_numero:
    push ax
    push cx
    push dx
    xor ax, ax      ; AX = 0 → acumulador del número
    xor bx, bx      ; BX = 0 → sin error
    xor cx, cx      ; CX = 0 → operaciones
    mov ax, 0       ; Inicializar AX a 0
    mov bx, 0       ; Inicializar BX a 0 (código de error)
    mov cx, 0

.next_char_to_num:
    mov cl, [si]    ; Leer siguiente carácter
    inc si

    cmp cl, '$'     ; Verificar fin de cadena
    je .terminado_texto_numero

    cmp cl, '0'     ; Verificar si es un dígito
    jb .error_texto_numero
    cmp cl, '9'     ; Entre 0 y 9
    ja .error_texto_numero

    sub cl, '0'

    ; AX no cambia, y se multiplica por 10
    mov bx, 10 ; BX = 10 (base decimal)
    mul bx     ; AX = AX * BX = AX * 10

    ; Ahora la multiplicación usa el espacio completo de 32 bits en DX:AX
    cmp dx, 0                  ; Verificar espacio 'high' de DX:AX
    jne .overflow_texto_numero ; Verificar desbordamiento (si AX > 0xFFFF)

    movzx cx, cl               ; Expandir CL a CX (de 8 bits a 16 bits)
    add ax, cx                 ; AX = AX + CL (dígito actual)
    jc .overflow_texto_numero  ; Si hay acarreo, desbordamiento

    jmp .next_char_to_num

.error_texto_numero:
    mov bx, 1
    xor ax, ax
    mov ax, 0x0
    jmp .guardar_resultado

.overflow_texto_numero:
    mov bx, 2
    xor ax, ax
    mov ax, 0x0
    jmp .guardar_resultado

.terminado_texto_numero:
.guardar_resultado:
    mov [di], ax      ; Guardar resultado de 16 bits en dirección DI
    pop dx
    pop cx
    pop ax
    ret



clear_screen:
    mov ah, 0
    mov al, 3
    int 10h
    ret

exit_program:
    mov ax, 4c00h
    int 21h

