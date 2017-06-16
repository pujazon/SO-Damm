.include "macros.s"


.set PILA, 0x8000               ;una posicion de memoria de una zona no ocupada para usarse como PILA


.text
        ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
        ;           Inicializacion
        ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

        $MOVEI r7, PILA    ;inicializamos R7 como puntero a la pila
        $MOVEI r6, inici   ;direccion de la rutina principal
	$MOVEI r0, 0x1000 ;(*)
        jmp    r6


       ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
       ; RUTINA PRINCIPAL SISTEMA OPERATIVO
       ; *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
inici: 
       	ei                 ;activa las interrupciones NOSE YO
binf:       
	jmp r0 		;HAY QUE HACERLO ES DE CAJON. PERO DE MIENTRAS R0 SERA PARA LAS DIRECCIONES (*)

