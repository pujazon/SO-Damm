# SO-Damm
Sistema operativo en SISA-S para el procesador PECi1.

Inicialmente solo multiprocesado entre 2 procesos.
Este es el dibujo de las paginas mapeadas en Memoria.
La TLB esta hecha en funcion de esta, teniendo en cuenta que solo es de 8 entradas.

Memoria:
		*********************************
	0	*	X			*
		*********************************				
	1	*	CODE P0			*
		*********************************
	2	*	DATA P0			*
		*********************************
	3	*	PILA P0			*
		*********************************
	4	*	CODE P1			*
		*********************************
	5	*	DATA P1			*
		*********************************
	6	*	PILA P1			*
		*********************************
	7	*	X			*
		*********************************
	8	*	PILA SYSTEMA		*
		*********************************
	9	*	X			*
		*********************************
	A	*	VGA1			*
		*********************************
	B	*	VGA2			*
		*********************************
	C	*	CODE SYSTEMA		*
		*********************************
	D	*	X #DATA SYSTEMA		*	
		*********************************
	E	*	X			*
		*********************************				*				*	
	F	*	X 			*
		*				*
		*				*		
		*********************************
