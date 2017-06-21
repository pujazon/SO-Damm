# SO-Damm
Sistema operativo en SISA-S para el procesador PECi1.


3.1 Decision inicials.
 
Per a programar el nostre sistema operatiu primer hem hagut de decidir on mapejar els diferents programes i les seves dades dins de la nostra Memoria. 
 
Per a cada programa tenim 1 pàgina per a codi i 1 pàgina per a dades. A la pàgina de dades aprofitarem la part baixa per posar-hi la pila del programa, suposant que la pila mai creixerà el suficient com per sobrescriure sobre les dades.
 
Amb tot, tindrem 1 pàgina de codi de sistema, 1 pàgina amb les dades (i la pila, fem com amb els programes), les dues pàgines (0xA i 0xB) per a la VGA i la pàgina 0x9 per a la SD. Notem que si no necessitem la SD, per exemple en la demo comuna, només calen 8 pàgines i caben totes a la TLB, el qual simplifica molt el canvi de context. Podem veure l’organització de memòria a la Taula 3.1.1.
 
Address
Contingut
0x0000
0x1000
Codi Programa 1
0x2000
Dades Programa 2
0x3000
Codi Programa 2
0x4000
Dades Programa 1
0x5000
0x7000
0x8000
Dades S.O: PILA1 // PILA 2
0x9000
Buffer SD
0xA000
VGA
0xB000
VGA
0xC000
Codi S.O.
0xD000 - 0xE000

 
Taula 3.1.1. Distribució de les zones de memòria per part del Sistema Operatiu.
Les excepcions tenen un tractament molt senzill. En la gran majoria del casos, excepte divisions per zero i excepcions de coma flotant, el processador farà un HALT, i no es recuperarà. En els altres, farem un resume i tornarem al programa. No hi ha tractament d’excepcions de TLB perquè no tenim Copy-On-Write i totes les nostres pàgines caben perfectament a la TLB. Això vol dir que si hi ha una fallada de TLB, hi ha algun error de programació.
 
Abans de fer un HALT, el sistema guardarà al registre R1 la direcció de tornada i al registre R3 la direcció que provoca l’excepció en cas de TLB i memòria no alineada. Això és una característica de debug per poder identificar on hi pot haver un error de programació.
 
A la taula 3.1.2 podem veure el comportament del sistema pels diferents tipus d’excepcions.
 
 
D’interrupcions només programarem les de timer i les de keyboard, ja que són les que ens interessen per al corre_letras i per al fibonacci. Les demés tenen un tractament per defecte de seguir l’execució. Podem veure el comportament de les interrupcions a la Taula 3.1.3
 

Aquestes interrupcions actualitzen variables internes del Sistema per poder donar suport a les trucades a sistema explicades al punt 3.2.
 
Al Sistema tenim també una variable anomenada pila_swap la qual servirà per guardar el punter dels dos programes en funció si som sistema o programa per a poder fer el canvi de pila quan hi hagi un canvi de context.
 
Utilitzarem el registre de sistema S6 per mantenir el punter actual a la pila de sistema, i el registre de sistema S4 per poder fer el swap de R7 amb S6 sense perdre registres d’usuari.
 
Remarcar que tot el Sistema Operatiu i l’execució dels programes suporta paginació amb la TLB, encara que totes les pàgines han d’entrar d’inici.
 
 
3.2 Modificacions dels programes.
 
Per al corre_letras, el mateix programa accedia i actualitzava les variables de tics_timers i tecla_pulsada.  Al implementar el sistema operatiu, ara serà ell el que s’encarregui d’actualitzar-les i/o accedir-les. Per a poder fer-ho des del programa, que està en mode usuari, hem implementat dues crides a sistema que ens permeten fer-ho:

last_key: Torna l’última tecla polsada al teclat. Totes les trucades consecutives tornaràn 0 si no s’ha polsat cap tecla desde l’última trucada last_key.
tics_timer: Retorna el nombre d’interrupcions de timer que han passat des de l’ultima trucada tics_timer.

 
Inicialment no implementàvem les syscalls i quan hi havia una interrupció de timer directament s’accedia a la variable de ticks i s’actualitzaba. Això ens generaba un problema, doncs si en la concurrència de programes ens trobàvem a fibonacci i arribava una interrupció de timer, també actualitzaba la variable ticks, cosa que no ha de fer, i generaba un error a l’output.
 
A més a més, un sistema operatiu ideal no hauria de tenir codi especialitzat pels programes que executa en aquell moment i no hauria d’accedir lliurement a zones de memòria d’usuari per incrementar variables.
Així doncs, vem implementar dues syscalls, i amb aquesta implementació aquest problema desapareix ja que l’actualització dels ticks ve donada per la syscall i no per la interrupció del timer. 
 
Dels programes inicials, al implementar el nostre Sistema Operatiu que s’encarrega de tractar totes les interrupcions i excepcions, la part d’entrada.s que tenien no ens fa falta i la hem eliminat. Comencen directament des del .main.
 
 
3.3 Implementació del SO
 
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
    $MOVEI r1, 0x0002 ; Modo usuario + Interrupciones habilitadas.
    wrs    S0, r1
    reti
 
Aquesta és l’entrada del nostre Sistema Operatiu. Posa a S5 la direcció de la RSG per quan haguem de tracter excepcions o interrupcions i seguidament va a init_tlb. 
 
A la TLB d’instruccions escriurà les pàgines de codi del corre_letras i fibonacci, ja que la de sistema ja està hardcoded inicialment. A la TLB de dades posara les pàgines de dades (i piles) de corre_letras, fibonacci, sistema i també les de VGA i SD (A les pàgines que s’expliquen a l’apartat 1).
Després salta a init_prog2. Init_prog2 carrega a la PILA2 el context (pila del programa 2, registres… veure taula 3.3.1). També guarda en pila_swap la direcció de la PILA2. Això ho fa per a poder fer el canvi de context, canviar de pila de sistema i poder canviar de programa com veurem més endevant.
 
@fi_RSG
Registres s0-s2
Registres r0-r6
@Pila usuari
 
Taula 3.3.1. Contingut de les piles de sistema (PILA1, PILA2).
 
 
Detalls de la pila de sistema serien quan guarda els registres r0-r6, el r7 no el guarda bàsicament perquè allà esta el punter de la pila el qual guarda primer. També veiem com el valor del top de la pila es la @fi_RSG perquè el necessita al sortir d ela rutina de context switch i poder anar al punt de fi_RSG per restaurar valors i sortir de sistema.
 
 
Finalment preparem per a poder saltar al corre_letras per al qual posem a S1 la direcció d’inici i a S6 la pila de sistema i con el reti ejecuta corre_letras.
 
Amb el corre_letras en execució, quan ens arriba una interrupció de timer, anem a la RSG i entrarà en el tractament d’interrupció de timer. En el tractament del interrupt timer mira el remaining quantum i li resta 1. Si aquest arriba a 0, vol dir que ha passat el quantum, saltarem al context switch, sinó tornarà a la RSG i acabarà tornant al programa.
 
En el cas del context switch fa el següent:
Primer de tot reinicia el quantum per a que torni a començar el compte des de l’inici.
 
El següent es canviar el punter de la pila actual per al que hi ha en la variable pila_swap, que és el de l’altre programa. De manera que ara el punter apunta a la pila amb l’estat de l’altre programa al que volem saltar. Així quan restauri els valors de la pila i el S1, al fer reti canviarà de programa. Aquest es el canvi de context.
Per poder fer altres canvis de context hem de guardar a pila_swap el punter de la pila del programa que estàvem executant.
 
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
 
 
 
 
Aquest procés de rebre les interrupcions de timer per actualitzar el context switch i un cop arribi al TOTAL_QUANTUM fer el context switch i al canviar de pila de sistema amb l’estat del programa al que volem canviar per restaurar el seu context i saltar de programa és la funció prinicpal del nostre sistema operatiu.
 




./sisa-emu sistema.code.DE1.hex sistema.data.DE1.hex -l addr=0x1000,file=corre_letras.code.DE1.hex -l addr=0x4000,file=corre_letras.data.DE1.hex -l addr=0x3000,file=fibonacci.code.DE1.hex -l addr=0x2000,file=fibonacci.data.DE1.hex -s 5000 -v -k -t -e 


