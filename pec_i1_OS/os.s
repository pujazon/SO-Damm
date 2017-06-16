.include "macros.s"


.set PILA, 0x8000               ;una posicion de memoria de una zona no ocupada para usarse como PILA


.text
        ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
        ;           Inicializacion
        ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

        $MOVEI r7, PILA    ;inicializamos R7 como puntero a la pila
        $MOVEI r6, inici   ;direccion de la rutina principal
	$MOVEI r0, 0x4000 ;(*)
	$MOVEI r3, 1;	   ;Es programa 1 al primero que accedemos

	;;Para el programa corre_letras, necesitamos mapear la pagina de la memoria de la pantalla, pero para qualquier
	;;Cosa estaria bien tener siempre mapeada esa zona por si nunca tenemos que usar pantalla para qualquier programa

	$MOVEI r1,0x6
	$MOVEI r2,0x2A
	wrpd r1,r2 ; 
	$MOVEI r2,0x0A
	wrvd r1,r2 ;

	$MOVEI r1,0x7
	$MOVEI r2,0x2B
	wrpd r1,r2 ; 
	$MOVEI r2,0x0B
	wrvd r1,r2 ;



        jmp    r6



       ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
       ; RUTINA PRINCIPAL SISTEMA OPERATIVO
       ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
inici: 
        $MOVEI r1,0x00
	cmpeq r2,r1,r3 ;Miro a que programa salto si al 0 o al 1 para hacer la traduccion de TLB
	bnz r2, salto_p0
	
	;Si sigo aqui es que salto_p1.
	; TLB P1: Pagina 4 para Instrucciones. Pagina 5 i 6 para datos i pila


	$MOVEI r1,0
	$MOVEI r2,0x24
	wrpi r1,r2 ; ppn(0 = indice del vpn) = 0x4 frame { v= 1, r=0, }
	$MOVEI r2,4
	wrvi r1,r2 ;Entrada vpn(0) = 0x4 pag

	$MOVEI r1,0
	$MOVEI r2,0x25
	wrpd r1,r2 ; ppn(0 indice del vpn) = 0x5 frame { v= 1, r=0, }
	$MOVEI r2,5
	wrvd r1,r2 ;Entrada tlb(0) = 0x5 vpn

	$MOVEI r1,1
	$MOVEI r2,0x26
	wrpd r1,r2 ; ppn(1 indice del vpn) = 0x6 frame { v= 1, r=0, }
	$MOVEI r2,6
	wrvd r1,r2 ;Entrada tlb(1) = 0x6 vpn
	

	jmp r0 		;HAY QUE HACERLO ES DE CAJON. PERO DE MIENTRAS R0 SERA PARA LAS DIRECCIONES (*)

salto_p0:


	; TLB P0: Pagina 1 para Instrucciones. Pagina 2 i 3 para datos i pila
	; La Pagina 1 en Instruccion si que esta perque només toco la 0. 
	; i de dades la Pagina 2 esta. NOMES FALTA LA 3


	$MOVEI r1,3
	$MOVEI r2,0x23
	wrpd r1,r2 ; ppn(0 indice del vpn) = 0x3 frame { v= 1, r=0, }
	$MOVEI r2,3
	wrvd r1,r2 ;Entrada tlb(0) = 0x3 vpn

	jmp r0 		;HAY QUE HACERLO ES DE CAJON. PERO DE MIENTRAS R0 SERA PARA LAS DIRECCIONES (*)


