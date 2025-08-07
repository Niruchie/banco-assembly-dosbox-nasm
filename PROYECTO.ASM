[bits 16]
org 0x100

; --- Data Section ---
section .data
    ; --- Menu Options ---
    opt1_crear_cuenta                             db 10, 13, "1. Crear cuenta$"
    opt2_ver_detalles                             db 10, 13, "2. Ver cuenta$"
    opt3_editar                                   db 10, 13, "3. Editar cuenta$"
    opt4_retirar                                  db 10, 13, "4. Retirar dinero$"
    opt5_depositar                                db 10, 13, "5. Depositar dinero$"
    opt6_salir                                    db 10, 13, "6. Salir$"

    ; --- General Messages ---
    menu_returno_msg                              db 10, 13, "Presione <Enter> para volver al menu...$"
    titulo_banco_msg                              db "--- Banco en Assembly ---$"
    titulo_detalles_msg                           db 10, 13, "--- Detalles de la cuenta ---$"

    option_msg                                    db 10, 13, "Opcion: $"
    existe_cuenta_msg                             db 10, 13, "Ya existe una cuenta. No se puede crear otra.$"
    edicion_cuenta_msg                            db 10, 13, "Cuenta editada exitosamente!$"
    retiro_exitoso_msg                            db 10, 13, "Retiro exitoso!$"
    reinicio_cuenta_msg                           db 10, 13, "Cuenta restablecida exitosamente!$"
    no_existe_cuenta_msg                          db 10, 13, "No hay una cuenta creada. Intente de nuevo.$"
    deposito_exitoso_msg                          db 10, 13, "Deposito exitoso!$"
    saldo_insuficiente_msg                        db 10, 13, "Saldo insuficiente.$"

    error_entrada_char_msg                        db 10, 13, "Entrada invalida. Solo se permiten digitos.$"
    error_pin_incorrecto_msg                      db 10, 13, "PIN incorrecto. Intente de nuevo.$"
    error_entrada_overflow_msg                    db 10, 13, "Numero demasiado grande. Intente de nuevo.$"
    error_fondos_no_aceptados_msg                 db 10, 13, "Error: Fondos no aceptados, tienes mucho dinero.$"

    cuenta_pin_label                              db 10, 13, "PIN: $"
    cuenta_balance_label                          db 10, 13, "Saldo: $"
    cuenta_nombre_label                           db 10, 13, "Nombre: $"

    retiro_prompt                                 db 10, 13, "Ingrese la cantidad a retirar: $"
    deposito_prompt                               db 10, 13, "Ingrese la cantidad a depositar: $"
    crear_cuenta_prompt                           db 10, 13, "Cuenta creada exitosamente!$"
    ingresar_pin_prompt                           db 10, 13, "Ingrese un PIN de 4 digitos: $"
    opcion_invalida_prompt                        db 10, 13, "Opcion invalida. Intente de nuevo.$"
    ingresar_nombre_prompt                        db 10, 13, "Ingrese el nombre de la cuenta (max 20 caracteres): $"
    no_implementado_prompt                        db 10, 13, "Funcion no implementada. Vuelva al menu.$"

section .bss
    ; --- Almacenamiento de Cuenta ---
    cuenta_existe_flag                            db 0                          ; 0 = cuenta no existe, 1 = cuenta existente
    cuenta_balance_store                          resw 1                        ; Palabra de 16 bits para el saldo de la cuenta
    cuenta_nombre_store                           resb 21                       ; Máx. 20 caracteres del nombre + '$' terminador
    cuenta_pin_store                              resb 5                        ; PIN de 4 dígitos + '$' terminador

    ; --- Variables Temporales ---
    buffer_entrada_numero                         resb 6                        ; Buffer para número (máx. 5 dígitos + '$')
    buffer_entrada_texto                          resb 21                       ; Buffer para entrada de texto (20 caracteres + '$')
    buffer_entrada_pin                            resb 5                        ; Buffer para PIN ingresado (4 dígitos + '$')
    numero_temporal                               resw 1                        ; Almacenamiento temporal de número

; --- Code Section ---
section .text
    global _start

_start:
    jmp menu_loop

;-------------------------------------------------
; display_menu
;
; Muestra el menú principal, por medio de 
; interrupciones de DOS.
;
; DX = * Puntero a la cadena a mostrar
; AH = 09h (función de imprimir cadena de DOS)
; INT 21h - Llamada al sistema operativo 
;-------------------------------------------------
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
    mov dx, option_msg
    mov ah, 9
    int 21h
    ret

;-------------------------------------------------
; get_option
;
; Lee la opción del usuario
; de la entrada estándar.
;
; AH = 01h (función de leer carácter de DOS)
; INT 21h - Llamada al sistema operativo
;-------------------------------------------------
get_option:
    mov ah, 1                                     ; Esperar una tecla
    int 21h
    sub al, '0'                                   ; Convertir ASCII a número
    ret

;-------------------------------------------------
; invalid_option
;
; Maneja la opción inválida
; 
;-------------------------------------------------
invalid_option:
    mov dx, opcion_invalida_prompt                ; Imprimir opción inválida
    mov ah, 9
    int 21h

    jmp return_to_menu                            ; Salto: volver al menú

;-------------------------------------------------
; return_to_menu
;
; Espera a que el usuario presione Enter
; para volver al menú principal.
;-------------------------------------------------
return_to_menu:
    mov dx, menu_returno_msg                      ; Imprimir mensaje de retorno
    mov ah, 9
    int 21h

    mov ah, 1                                     ; Esperar una tecla
    int 21h

    jmp menu_loop                                 ; Salto: volver menú opciones

;-------------------------------------------------
; menu_loop
;
; Bucle principal del menú
;-------------------------------------------------
menu_loop:
    call clear_screen                             ; Limpiar pantalla
    call display_menu                             ; Mostrar menú
    call get_option                               ; Obtener opción del usuario

    cmp al, 1                                     ; Comparar opción (foreach)
    je create_account                             ;   CMP = AL - OPTION
    cmp al, 2                                     ;   AL == #OPTION ? ZF = 1
    je view_account
    cmp al, 3                                     ; foreach (OPT in OPTIONS)
    je edit_account                               ;   CMP = AL - OPTION
    cmp al, 4                                     ;   if (CMP == 0) ZF = 1
    je retirar_dinero                             ;   if (ZF == 1)
    cmp al, 5                                     ;     proceso()
    je depositar_dinero                           ;     break
    cmp al, 6                                     ; invalido()

    jmp invalid_option                            ; Salto: opción inválida

;-------------------------------------------------
; create_account
;
; Crea una nueva cuenta bancaria
;-------------------------------------------------
create_account:
    call check_account_exists                     ; Subrutina: verificar cuenta
    cmp al, 1                                     ; out Al = 1 | si existe
    je account_exists                             ; Salto: cuenta ya existe

    mov dx, ingresar_nombre_prompt                ; Pedir nombre de cuenta
    mov ah, 9
    int 21h

    mov cx, 20                                    ; CX = 20 | 20 caracteres
    mov dx, cuenta_nombre_store                   ; DX = * Puntero al storage
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov dx, ingresar_pin_prompt                   ; Pedir PIN de cuenta
    mov ah, 9
    int 21h

    mov cx, 4                                     ; CX = 4 | 4 dígitos
    mov dx, cuenta_pin_store                      ; DX = * Puntero al storage
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov dword [cuenta_balance_store], 0           ; Inicializar saldo a 0
    call activate_account                         ; Subrutina: Activar cuenta

    jmp return_to_menu                            ; Salto: volver al menú

;-------------------------------------------------
; view_account
;
; Muestra los detalles de la cuenta
;-------------------------------------------------
view_account:
    call check_account_exists                     ; Subrutina: verificar cuenta
    cmp al, 0                                     ; out Al = 0 | si no existe
    je account_not_exists                         ; Salto: cuenta no existe

    mov dx, titulo_detalles_msg                   ; Mostrar título detalles
    mov ah, 9
    int 21h

    mov dx, cuenta_nombre_label                   ; Mostrar nombre cuenta
    mov ah, 9
    int 21h

    mov dx, cuenta_nombre_store
    mov ah, 9
    int 21h

    mov dx, cuenta_pin_label                      ; Mostrar PIN cuenta
    mov ah, 9
    int 21h

    mov dx, cuenta_pin_store
    mov ah, 9
    int 21h

    mov dx, cuenta_balance_label                  ; Mostrar saldo cuenta
    mov ah, 9
    int 21h

    mov ax, [cuenta_balance_store]                ; AX = <saldo>
    mov si, buffer_entrada_numero                 ; SI = * Puntero al buffer
    call number_to_string                         ; Subrutina: número a texto

    mov dx, buffer_entrada_numero                 ; Mostrar saldo como texto
    mov ah, 9
    int 21h

    jmp return_to_menu                            ; Salto: volver al menú

;-------------------------------------------------
; edit_account
;
; Edita los detalles de la cuenta
;-------------------------------------------------
edit_account:
    call check_account_exists                     ; Subrutina: verificar cuenta
    cmp al, 0                                     ; out Al == 0 | si no existe
    je account_not_exists                         ; Salto: cuenta no existe

    call ask_for_pin                              ; Subrutina: solicitar PIN
    cmp al, 0                                     ; out Al == 0 | incorrecto
    je cuenta_pin_store_incorrect                 ; Salto: PIN incorrecto

    mov dx, ingresar_nombre_prompt                ; Pedir nuevo nombre
    mov ah, 9
    int 21h

    mov cx, 20                                    ; CX = 20 | Max 20 caracteres
    mov dx, cuenta_nombre_store                   ; DX = * Puntero al storage
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov dx, ingresar_pin_prompt                   ; Pedir nuevo PIN
    mov ah, 9
    int 21h

    mov cx, 4                                     ; CX = 4 | 4 dígitos
    mov dx, cuenta_pin_store                      ; DX = * Puntero al storage
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov dx, edicion_cuenta_msg                    ; Mostrar mensaje de edición
    mov ah, 9
    int 21h

    jmp return_to_menu                            ; Salto: volver al menú

;-------------------------------------------------
; retirar_dinero
;
; Retira dinero de la cuenta
;-------------------------------------------------
retirar_dinero:
    call check_account_exists                     ; Subrutina: verificar cuenta
    cmp al, 0                                     ; out Al == 0 | si no existe
    je account_not_exists                         ; Salto: cuenta no existe

    call ask_for_pin                              ; Subrutina: solicitar PIN
    cmp al, 0                                     ; out Al == 0 | incorrecto
    je cuenta_pin_store_incorrect                 ; Salto: PIN incorrecto

    mov dx, retiro_prompt                         ; Pedir monto a retirar
    mov ah, 9
    int 21h

    mov cx, 5                                     ; CX = 5 | 5 dígitos
    mov dx, buffer_entrada_numero                 ; DX = * Puntero al buffer
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov si, buffer_entrada_numero                 ; SI = * Puntero buffer in
    mov di, numero_temporal                       ; DI = * Puntero temporal out
    call texto_a_numero                           ; Subrutina: texto a número

    cmp bx, 2                                     ; BX = 2 | Overflow > 65535
    je error_overflow_input                       ; Salto: error overflow

    cmp bx, 1                                     ; BX = 1 | Carácter inválido
    je error_char_input                           ; Salto: error carácter

    clc                                           ; Limpiar bandera de acarreo
    mov ax, [cuenta_balance_store]                ; AX = <saldo>
    cmp ax, [numero_temporal]                     ; CMP: saldo < monto (resta)
    jl error_insufficient_funds                   ; Salto: saldo insuficiente

    sub ax, [numero_temporal]                     ; AX = AX - <monto>
    mov [cuenta_balance_store], ax                ; <saldo> = AX | Guardar saldo

    mov dx, retiro_exitoso_msg                    ; Mostrar mensaje de retiro
    mov ah, 9
    int 21h

    jmp return_to_menu                            ; Salto: volver al menú

;-------------------------------------------------
; depositar_dinero
;
; Deposita dinero en la cuenta
;-------------------------------------------------
depositar_dinero:
    call check_account_exists                     ; Subrutina: verificar cuenta
    cmp al, 0                                     ; out Al == 0 | si no existe
    je account_not_exists                         ; Salto: cuenta no existe

    call ask_for_pin                              ; Subrutina: solicitar PIN
    cmp al, 0                                     ; out Al == 0 | incorrecto
    je cuenta_pin_store_incorrect                 ; Salto: PIN incorrecto

    mov dx, deposito_prompt                       ; Pedir monto a depositar
    mov ah, 9
    int 21h

    mov cx, 5                                     ; CX = 5 | 5 dígitos
    mov dx, buffer_entrada_numero                 ; DX = * Puntero al buffer
    call store_string_to_address                  ; Subrutina: Guardar entrada

    mov si, buffer_entrada_numero                 ; SI = * Puntero buffer in
    mov di, numero_temporal                       ; DI = * Puntero temporal out
    call texto_a_numero                           ; Subrutina: texto a número

    cmp bx, 2                                     ; BX = 2 | Overflow > 65535
    je error_overflow_input                       ; Salto: error overflow

    cmp bx, 1                                     ; BX = 1 | Carácter inválido
    je error_char_input                           ; Salto: error carácter

    clc                                           ; Limpiar bandera de acarreo
    mov ax, [cuenta_balance_store]                ; AX = <saldo>
    add ax, [numero_temporal]                     ; AX = AX + <monto>
    jc error_no_accepted_funds                    ; Salto: error fondos | CF = 1

    mov [cuenta_balance_store], ax                ; <saldo> = AX | Guardar saldo
    mov dx, deposito_exitoso_msg                  ; Mostrar mensaje de depósito
    mov ah, 9
    int 21h

    jmp return_to_menu                            ; Salto: volver al menú

; --- Utility Routines ---
error_insufficient_funds:
    mov dx, saldo_insuficiente_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

error_no_accepted_funds:
    mov dx, error_fondos_no_aceptados_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

error_overflow_input:
    mov dx, error_entrada_overflow_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

error_char_input:
    mov dx, error_entrada_char_msg
    mov ah, 9
    int 21h
    jmp return_to_menu

ask_for_pin:
    ; Prompt for PIN
    mov dx, ingresar_pin_prompt
    mov ah, 9
    int 21h

    ; Read PIN
    mov cx, 4 ; 4 digits for PIN
    mov dx, buffer_entrada_pin
    call store_string_to_address

    lea si, buffer_entrada_pin     ; Puntero al PIN ingresado
    lea di, cuenta_pin_store    ; Puntero al PIN almacenado

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

cuenta_pin_store_incorrect:
    mov dx, error_pin_incorrecto_msg
    mov ah, 9
    int 21h
    jmp return_to_menu
account_not_exists:
    cmp byte [cuenta_existe_flag], 0
    mov dx, no_existe_cuenta_msg
    mov ah, 9
    int 21h
    jmp return_to_menu
account_exists:
    cmp byte [cuenta_existe_flag], 1
    mov dx, existe_cuenta_msg
    mov ah, 9
    int 21h
    jmp return_to_menu
activate_account:
    mov byte [cuenta_existe_flag], 1
    mov dx, crear_cuenta_prompt
    mov ah, 9
    int 21h
    ret
check_account_exists:
    mov al, [cuenta_existe_flag]
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

