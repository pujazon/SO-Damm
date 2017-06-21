#!/bin/bash


echo "Ensamblando ..."
#compila el ensamblador
sisa-as entrada.s -o entrada.o

echo "Compilando ..."
#compila el c (solo compila)  (para ver el codigo fuente entre el codigo desensamblado hay que compilar con la opcion -O0)
sisa-gcc -g3 -O0 -c -Wall corre_letras/corre_letras.c -o corre_letras.o
sisa-gcc -g3 -O0 -c -Wall fibonacci/fibonacci.c -o fibonacci.o

echo "Linkando ..."
#Linkamos los ficheros (la opcion -s es para que genere menos comentarios)
sisa-ld -s -T system.lds entrada.o corre_letras.o fibonacci.o -o sistema.o

#desensamblamos el codigo
sisa-objdump -d --section=.sistema sistema.o >sistema.code
sisa-objdump -s --section=.sysdata sistema.o >sistema.data

./limpiar.pl codigo sistema.code
./limpiar.pl datos sistema.data

sisa-objdump -d --section=.corre_code sistema.o >corre_letras.code
sisa-objdump -s --section=.corre_data sistema.o >corre_letras.data

./limpiar.pl codigo corre_letras.code
./limpiar.pl datos  corre_letras.data

sisa-objdump -d --section=.fibo_code sistema.o >fibonacci.code
sisa-objdump -s --section=.fibo_data sistema.o >fibonacci.data

./limpiar.pl codigo fibonacci.code
./limpiar.pl datos  fibonacci.data

#Linkamos los ficheros (sin la opcion -s es para que genere mas comentarios) y desensamblamos
#(para ver el codigo fuente entre el codigo desensamblado hay que haber compilado con la opcion -O0)
sisa-ld -T system.lds entrada.o -o sistema.o

sisa-objdump -S -x -w --section=.sistema sistema.o >sistema.dis
sisa-objdump -S -x -w --section=.sysdata sistema.o >>sistema.dis

#rm entrada.o sistema.o sistema.code sistema.data

