 movi  r7, 0x00 ; Pila de sist: decreix en
 movhi r7, 0x30 ; 

 ; El retorn de la rutina principal
 movi  r5, lo( __exit )
 movhi r5, hi( __exit )

 ; Start main rutine
 movi  r6, lo( main )
 movhi r6, hi( main )
 jmp   r6
