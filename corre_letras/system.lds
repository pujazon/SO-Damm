/*
 *  Canviem l'script per defecte
 *   per adequar-lo a l'arquitectura
 */
OUTPUT_FORMAT("elf32-sisa","elf32-sisa","elf32-sisa")
OUTPUT_ARCH(sisa)
SECTIONS
{
  /* CODIGO */
  . = 0x0000 ;

  /* text space */
  .code :
  {
    corre_letras.o(.text)
    corre_letras.o(.rodata)
    . = ALIGN(2);
  }
  __entry_point = main;

  PROVIDE (__user_start = .);
  . = 0x0 ; /* Part d'usuari */

  .user :
  {
  }
  __user_end = __user_start + SIZEOF(.user);
  
   /* Ens situem en la part de sistema */
  . = 0x1000 ;

  .data : {  corre_letras.o(.data)  }
}
