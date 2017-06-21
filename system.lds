/*
 *  Canviem l'script per defecte
 *   per adequar-lo a l'arquitectura
 */
OUTPUT_FORMAT("elf32-sisa","elf32-sisa","elf32-sisa")
OUTPUT_ARCH(sisa)
SECTIONS
{
  /* Ens situem a la part de flash */
  . = 0xc000 ;

  /* text space */
  .sistema :
  {
    entrada.o(.text) 
    entrada.o(.rodata)
    . = ALIGN(2);
  }
  __entry_point = LOADADDR(.sistema);

  PROVIDE (__user_start = .);
  . = 0x0 ; /* Part d'usuari */

  .user :
  {
  }
  __user_end = __user_start + SIZEOF(.user);
  
   /* Ens situem en la part de sistema */
  . = 0x8000 ;

  .sysdata : {  entrada.o(.data)  }

  . = 0x4000 ;

  .corre_data : {
      corre_letras.o(.data)
      corre_letras.o(COMMON)
      corre_letras.o(.bss)
  }

  . = 0x1000 ;

  .corre_code : { corre_letras.o(.text) corre_letras.o(.rodata) }

  . = 0x2000 ;

  .fibo_data : { 
      fibonacci.o(.data)
      fibonacci.o(COMMON)
      fibonacci.o(.bss)
    }

  . = 0x3000 ;

  .fibo_code : { fibonacci.o(.text) }

}
