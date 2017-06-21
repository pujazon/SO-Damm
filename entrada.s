; Incluimos las macros necesarias
.include "macros.s"

.set PILA, 0x9000                ; una posicion de memoria de una zona no ocupada para usarse como PILA (ojo con la inicializacion del TLB)
.set PILA2, 0x8500
.set PILA_USER1, 0x5000 ; pila prog 1
.set PILA_USER2, 0x3000 ; pila prog 2
.set CODIGO_PROG1, 0x31
.set CODIGO_PROG2, 0x33
.set DATOS_PROG1,  0x24
.set DATOS_PROG2,  0x22
.set MASCARA_TICS, 0x2000
.set ENTRADA_PROG1, main_corre
.set ENTRADA_PROG2, main_fibo
.set TOTAL_QUANTUM, 3

; S6 -> PILA DE SISTEMA
; S4 -> REGISTRO TEMPORAL PARA HACER SWAP CON R7

; seccion de datos
.data
    .balign 2                     ; por si acaso, pero no deberia ser necesario
    pila_swap: .word 0x0000
    remain_quantum: .word 0x00005
	ultima_tecla: .word 0xCACA
	sys_tics:     .word 0x0000	

    interrupts_vector:
        .word RSI__interrup_timer     ; 0 Interval Timer
        .word RSI_default_resume      ; 1 Pulsadores (KEY)
        .word RSI_default_resume      ; 2 Interruptores (SWITCH)
        .word RSI__interrup_keyboard  ; 3 Teclado PS/2

    exceptions_vector:
        .word RSE_default_halt    ;  0 Instruccion ilegal
        .word RSE_default_halt    ;  1 Acceso a memoria no alineado
        .word RSE_default_resume  ;  2 Overflow en coma flotante
        .word RSE_default_resume  ;  3 Division por cero en coma flotante
        .word RSE_default_halt    ;  4 Division por cero
        .word RSE_default_halt    ;  5 No definida
        .word RSE_excepcion_TLB   ;  6 Miss en TLB de instrucciones
        .word RSE_excepcion_TLB   ;  7 Miss en TLB de datos
        .word RSE_excepcion_TLB   ;  8 Pagina invalida al TLB de instrucciones
        .word RSE_excepcion_TLB   ;  9 Pagina invalida al TLB de datos
        .word RSE_default_halt    ; 10 Pagina protegida al TLB de instrucciones
        .word RSE_default_halt    ; 11 Pagina protegida al TLB de datos
        .word RSE_default_halt    ; 12 Pagina de solo lectura
        .word RSE_default_halt    ; 13 Excepcion de proteccion
        
    call_sys_vector:
        .word RSE_last_key  ; 0 Hay que definirla en el S.O.
        .word RSE_tics_timer  ; 1 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 2 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 3 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 4 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 5 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 6 Hay que definirla en el S.O.
        .word RSE_default_resume  ; 7 Hay que definirla en el S.O.

; seccion de codigo
.text
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Inicializacion
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    $MOVEI r1, RSG
    wrs    s5, r1      ;inicializamos en S5 la direccion de la rutina de atencion a la interrupcion
    $MOVEI r4, init_tlb ; preparamos salto a init_tlb
	jal    r6, r4
    ; Ahora debemos inicializar la pila del programa 2. La prepararemos para que se retorne desde un context switch.
    $MOVEI r4, init_prog2
    jal    r6, r4
    $MOVEI r7, PILA
    $MOVEI r6, ENTRADA_PROG1    ;direccion de la rutina principal
    wrs    s6, r7 ; S6 guarda la pila de sistema
    wrs    s1, r6 ; s1 direccion de salto al hacer reti
    $MOVEI r7, PILA_USER1
    ; Como que usamos reti para volver, necesitamos salvar en S0 la palabra de sistema
    ; con interrupciones hablitadas. Al hacer reti, las estamos activando implicitamente.
    ; Es esto feo??
    $MOVEI r1, 0x0002 ; Modo usuario + Interrupciones habilitadas.
    wrs    S0, r1
    reti


    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Rutina de salida
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    __exit:
        halt        ; Paramos la CPU


    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Rutinas de servicio por defecto
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    RSI_default_resume: JMP R6
    RSE_default_halt:   
       rds r0, S1 ; DEBUG
       rds r3, S3
       HALT
    RSE_default_resume: JMP R6

    RSE_excepcion_TLB:   ;fragmento de codigo
        rds r0, S1 ; DEBUG
        rds r3, S3
        HALT

    context_switch:
        ; Podemos machacar libremente todos los registros
        ; a excepcion de r6. Cuidado.
        $MOVEI r1, TOTAL_QUANTUM
        $MOVEI r2, remain_quantum
        st     0(r2), r1 ; Restauramos quantum.
        $MOVEI r1, pila_swap
        addi   r2, r7, 0 ; r2 = r7
        ld     r7, 0(r1) ; r7 = pila_swap
        st     0(r1), r2 ; pila_swap = old_r7
        jmp    r6 ; retornamos

    init_prog2:
        $MOVEI  r7, PILA2
        $MOVEI  r3, PILA_USER2
        $push   r3 ; Primer registro, pila usuario
        $MOVEI  r1, ENTRADA_PROG2 ; S1 = Entrada PROG2 para hacer reti
        $MOVEI  r2, 0x02 ; User mode, int enabled
        $MOVEI  r5, 0x00 ; Esta es la salida. De momento nada.
        $MOVEI  r3, 0x00 ; De momento nada tampoco.
        $push   r2, r2, r2, r2, r2, r5, r3 ; Registros usuario (valor inicial!)
        $push   r2, r1, r2 ; S1 = Entrada, S2 & S3 dont care.
        $MOVEI  r1, __finRSG ; Retorno.
        $push   r1
        $MOVEI  r1, pila_swap
        st      0(r1), r7 ; Para restaurar la pila de sistema!
        jmp     r6 ; retorno
    init_prog2_reti:
        reti

    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Rutina de servicio de interrupcion
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    .global RSG
    RSG: ; Salvar el estado
		 ; Primero cambiamos a la pila de sistema
		 wrs    S4, r6
		 addi   r6, r7, 0  ; Movemos r7 a r6
		 rds    r7, S6
		 $push  R6 ; Primer registro en guardarse es la pila
		 rds    r6, S4
         $push  R0, R1, R2, R3, R4, R5, R6
         rds    R1, S0
         rds    R2, S1
         rds    R3, S3
         $push  R1, R2, R3
         rds    R1, S2                    ;consultamos el contenido de S2
         movi   R2, 14
         cmpeq  R3, R1, R2                ;si es igual a 14 es una llamada a sistema
         bnz    R3, __call_sistema        ;saltamos a las llamadas a sistema si S2 es igual a 14
         movi   R2, 15
         cmpeq  R3, R1, R2                ;si es igual a 15 es una interrupción
         bnz    R3, __interrupcion        ;saltamos a las interrupciones si S2 es igual a 15
    __excepcion:
         movi   R2, lo(exceptions_vector)
         movhi  R2, hi(exceptions_vector)
         add    R1, R1, R1                ;R1 contiene el identificador de excepción
         add    R2, R2, R1
         ld     R2, 0(R2)
         jal    R6, R2
         bz     R3, __finRSG
    __call_sistema:
         rds    R1, S3                    ;S3 contiene el identificador de la llamada a sistema
         movi   R2,7
         and    r1,r1,r2     ; nos quedamos con los 3 bits de menor peso limitar el numero de servicios definidos por el S.O.
         add    R1, R1, R1
         movi   R2, lo(call_sys_vector)
         movhi  R2, hi(call_sys_vector)
         add    R2, R2, R1
         ld     R2, 0(R2)
         jal    R6, R2
	 rds	R1, S4
	 st	10(R7), R1 ; Valor de retorno de la rutina
         bnz    R3, __finRSG
    __interrupcion:
         getiid R1
         add    R1, R1, R1
         movi   R2, lo(interrupts_vector)
         movhi  R2, hi(interrupts_vector)
         add    R2, R2, R1
         ld     R2, 0(R2)
         jal    R6, R2
    __finRSG: ;Restaurar el estado
         $pop  R3, R2, R1
         wrs   S3, R3
         wrs   S1, R2
         wrs   S0, R1
         $pop  R6, R5, R4, R3, R2, R1, R0
         addi  R7, R7, 2
         wrs   S6, R7
         ld    r7, -2(R7) ; 0 segur daixo
         reti


    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Rutina interrupcion reloj
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    RSI__interrup_timer:
        $MOVEI r4, sys_tics      ;carga la direccion de memoria donde esta el dato sobre el # de ticks de reloj que han llegado
        ld     r3, 0(r4)           ;carga el numero de ticks
        addi   r3, r3, 1           ;lo incrementa en una unidad
        st     0(r4), r3           ;actualiza la variable sobre el numero de ticks. Esto da soporte a corre_letras!
        
		$MOVEI r4, remain_quantum  ; quantum actual
        ld     r3, 0(r4)
        addi   r3, r3, -1          ; le quitamos 1
        st     0(r4), r3
        bnz    r3, out_cont       ; si es 0, context switch  
        $push  r6
        $MOVEI r3, context_switch
        jal    r6, r3
        $pop   r6
out_cont:
        jmp    r6         ; R6 contine (ya que no lo hemos modificado) la direccion de retorno para gacer el fin de la RSG (fin del servicio de interrupcion)



    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    ; Rutina interrupcion teclado PS/2
    ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    RSI__interrup_keyboard:
        in     r3, 15              ;leemos el valor correspondiente al caracter ASCII de la tecla pulsada
        $MOVEI r4, ultima_tecla   ;carga la direccion de memoria donde dejaremos el resultado de la tecla pulsada
        st     0(r4), r3           ;actualiza la variable con la nueva tecla pulsada
        jmp    r6         ; R6 contine (ya que no lo hemos modificado) la direccion de retorno para gacer el fin de la RSG (fin del servicio de interrupcion)
		
	RSE_last_key:
		$MOVEI r1, ultima_tecla
		ld	   r2, 0(r1)
		wrs	   S4, r2 ; Las syscalls ponen el valor de retorno en S4
		movi 	   r2, 0
		st	   0(r1), r2 ; reseteamos tecla pulsada
		jmp	   R6
		
	RSE_tics_timer:
		$MOVEI r1, sys_tics
		ld     r2, 0(r1)
		wrs	   S4, r2 ; S4 = TICS
		movi   r2, 0
		st	   0(r1), r2 ; tics = 0
		jmp    r6

	init_tlb:
		; TLB Instrucciones. Sistema ya esta
		$MOVEI r1, CODIGO_PROG1
		$MOVEI r2, 0
		wrvi   r2, r1 ; vtlb(0) = CODIGO PROGRAMA 1
		wrpi   r2, r1 ; ptlb(0) = CODIGO PROGRAMA 1 (ro, valid)
		$MOVEI r1, CODIGO_PROG2
		$MOVEI r2, 1
		wrvi  r2, r1 ; vtlb(1) = CODIGO PROGRAMA 2
		wrpi  r2, r1 ; ptlb(1) = CODIGO PROGRAMA 2 (ro, valid)
		; TLB Datos
		$MOVEI r1, DATOS_PROG1
		$MOVEI r2, 0
		wrvd  r2, r1 ; vtlb(0) = DATOS PROGRAMA 1
		wrpd  r2, r1 ; ptlb(0) = DATOS PROGRAMA 1 (valid)
		$MOVEI r1, DATOS_PROG2
		$MOVEI r2, 1
		wrvd  r2, r1 ; vtlb(1) = DATOS PROGRAMA 2
		wrpd  r2, r1 ; ptlb(1) = DATOS PROGRAMA 2
		; TAMBIEN CODIGOS POR SI HAY READ-ONLY DATA!
		$MOVEI r1, CODIGO_PROG1
		$MOVEI r2, 2
		wrvd   r2, r1 ; vtlb(2) = CODIGO PROGRAMA 1
		wrpd   r2, r1 ; ptlb(2) = CODIGO PROGRAMA 1 (ro, valid)
		; Entradas 3 y 4 ocupadas x sistema
		$MOVEI r1, CODIGO_PROG2
		$MOVEI r2, 5
		wrvd  r2, r1 ; vtlb(5) = CODIGO PROGRAMA 2
		wrpd  r2, r1 ; ptlb(5) = CODIGO PROGRAMA 2 (ro, valid)
		; DEBUG
        ;$MOVEI r1, 0x25
        ;$MOVEI r2, 5
        ;wrvd   r2, r1
        ;wrpd   r2, r1
        ; VGA (necesario?)
		$MOVEI r1, 0x002A
		$MOVEI r2, 6
		wrvd  r2, r1 ; vtlb(6) = VGA (1)
		wrpd  r2, r1 ; ptlb(6) = VGA (1, valid)
		$MOVEI r1, 0x002B
		$MOVEI r2, 7
		wrvd  r2, r1 ; vtlb(7) = VGA (2)
		wrpd  r2, r1 ; ptlb(7) = VGA (1, valid)
		jmp   r6 ; Retornamos!


