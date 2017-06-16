	; entry.s de zeos para SISA por Zeus Gómez Marmolejo
	

	.include "macros.s"

	PILA=0x6000 ;Si que cal per guardar estat

	.set SYSTEMA, 0xC032 ;En realidad es la direccion de inicio de SYSTEMA, sin el prologo inicial

	; seccion de datos
	.data
	    .balign 2                     ; por si acaso, pero no deberia ser necesario

	    interrupts_vector:
		.word RSI__interrup_timer     ; 0 Interval Timer        
	.word RSI_default_resume      ; 1 Pulsadores (KEY)
        .word RSI_default_resume      ; 2 Interruptores (SWITCH)
        .word RSI__interrup_keyboard  ; 3 Teclado PS/2


	.text
	    $MOVEI r1, RSG
	    wrs    s5, r1      ;SINO EN ESTADO SYS NO SABE DONDE IR
	 movi  r7, 0x00 ; Pila de sist: decreix en
	 movhi r7, 0x82 ;  RAM: 0x81fe, 0x81fc, ...
	 ;wrs   s6, r7   ; a s6: la pila de sistema

	 ; El retorn de la rutina principal
	 movi  r5, lo( __exit )
	 movhi r5, hi( __exit )

	 ; Start main rutine
	 movi  r6, lo( main )
	 movhi r6, hi( main )
	 ei
	 jmp   r6


	__exit:
	 ; Parem la CPU
	 halt


    .global RSG
    RSG: ; Salvar el estado
         $push  R0, R1, R2, R3, R4, R5, R6
         rds    R1, S0
         rds    R2, S1
         rds    R3, S3
         $push  R1, R2, R3
         rds    R1, S2                    ;consultamos el contenido de S2
         movi   R2, 15
         cmpeq  R3, R1, R2                ;si es igual a 15 es una interrupción
         bnz    R3, __interrupcion        ;saltamos a las interrupciones si S2 es igual a 15
   
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
         reti

	    RSI__interrup_timer:
		$MOVEI r4, tics_timer      ;@# ticks llegados
		ld     r3, 0(r4)           ;# ticks llegados
		$MOVEI r2, 0x1		   ;quantum (Ponemos 1 por el EMULADOR. MIRAR CON PLACA EL INTERVAL TIMER)
		cmpeq  R1, R3, R2          ;si #ticks == quantum -> CONTEXT SWITCHING
		bnz R1, context_switching
		addi   r3, r3, 1           ;lo incrementa en una unidad
		st     0(r4), r3           ;actualiza la variable sobre el numero de ticks
		out 6,r3        ; Solo para DEBUG; mostramos el valor por los leds rojos
		jmp    r6         ; R6 retorno para fin RSG

	context_switching:
	
		$MOVEI r4, tics_timer      ;@# ticks llegados
		$MOVEI r3, 0      	   ;Reiniciamos #ticks llegados
		st     0(r4), r3

		$MOVEI r0, 0x1000	; Direccion del otro programa para que salte directo

		

		;Ara aqui tenemos que poner guardar en s4 que sera el programa 0 a ejecutarse
	
		movi r3, 0 ;No caldria en realidad pq ya estaba arriba
			   ;Se podria hacer con mascara pillando la parte mas alta de r4 que ya la tendriamos
		$MOVEI r4, SYSTEMA
		jmp r4
		;Aqui tendra que saltar a systema




; PARA TODAS LAS DEMAS INTERRUPCIONES NO HACE NADA

    RSI__interrup_keyboard:
        jmp    r6       
    RSI_default_resume: JMP R6


