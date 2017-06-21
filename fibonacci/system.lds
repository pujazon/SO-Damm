/*
 *  Canviem l'script per defecte
 *   per adequar-lo a l'arquitectura
 */
OUTPUT_FORMAT("elf32-sisa","elf32-sisa","elf32-sisa")
OUTPUT_ARCH(sisa)
SECTIONS
{
  /* Ens situem a la part de flash */
  . = 0x2000 ;

  /* text space */
  .code :
  {
    fibonacci.o(.text)
    fibonacci.o(.rodata)
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
  . = 0x3000 ;

  .data : {  fibonacci.o(.data)  }
}
