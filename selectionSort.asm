.data
arquivo: .asciiz "/caminho/dados.txt"   
space: .asciiz " "
newline: .asciiz "\n"
buffer:   .space 1024     			# espaço para ler o arquivo
.align 2
numeros: .space 400 				# espaço para 100 inteiros
tempoExec: .asciiz "\nTempo de execusão: " 	# mensagem que ira aparecer jutamente com o tempo gasto para executar a ordenação
arrayOriginal: .asciiz "\nArray original: "
arrayOrdenado: .asciiz "\nArray ordenado: "
.text

main:
	#----------------------------------------------------------------------------
	# --- abrir arquivo ---
	li   $v0, 13           		# syscall open file
	la   $a0, arquivo
	syscall
	move $s0, $v0          		# guarda o identificador do arquivo

	# --- ler arquivo ---
	li   $v0, 14			# syscall read file
	move $a0, $s0			# identificador do arquivo aberto
	la   $a1, buffer		# destino
	li   $a2, 1024			# tamanho máx
	syscall
	move $t0, $v0			# salva quantidade de bytes realmente lidos

	# --- terminar buffer com zero (null-terminate) ---
    	la $t1, buffer
    	add $t1, $t1, $t0
    	sb $zero, 0($t1)

	# --- fechar arquivo ---
	li   $v0, 16			# código da syscall "close file"
	move $a0, $s0       		# decritor do arquivo a ser fechado
	syscall
	
	#----------------- converte de string para int ---------------------------------------
	la $t3, numeros   		# ponteiro onde os inteiros serão armazenados
	move $s2, $t3 			# guarda o inicio (onde fica o cabeçalho)
	addi $t3, $t3, 4 		#Pula o cabeçalho, e começa no segundo valor
	li $s1, 0
    	la $a1, buffer      		# ponteiro para o buffer de string de int
    	li $v0, 0    			# acumulador para o numero atual
    	li $t9, 0       		# flag: 0 = ainda não li cabeçalho, 1 = já li cabeçalho
	
	str_to_int:
	
	loop_char:			# Vai percorrer o arquivo transformando a string em inteiro
	lb $t2, 0($a1) 			# lê um byte de memória a partir do endereço do buffer que esta os valores
	beq $t2, $zero, endLoopChar 	# Se for falso, que o t2 é zero sai do loopStart (fim da string)
	
	beq $t2, 32, store_num      	# espaço ' '? salva número  
   	beq $t2, 10, store_num      	# newline '\n'? salva número    
	
	addi $t2, $t2, -48 		# Converte pro valor da tabela ASCII
	mul $v0, $v0, 10 		# Multiplica o resultado por 10
	add $v0, $v0, $t2 		# Adiciona o digito ao resultado
	
	addi $a1, $a1, 1		# Soma 1 no loop
	j loop_char             	# retorna ao incio do loop
	
	store_num:
	beq $t9, $zero, salvaCabecalho   # se ainda não tem cabeçalho, guarda lá
	
	# aqui já tem cabeçalho → grava número se não passou do limite
    	lw $t8, 0($s2)        		# lê quantidade do cabeçalho
    	bge $s1, $t8, ignora  		# se já preenchi todos, ignora este número
	
    	sw $v0, 0($t3)    	        # salva número no array numeros
    	addi $t3, $t3, 4            	# próximo slot
    	addi $s1, $s1, 1
    	
    	ignora:
    	li $v0, 0                   	# zera acumulador
    	addi $a1, $a1, 1            	# pula espaço/newline
    	j loop_char
    	
    	salvaCabecalho:
    	sw $v0, 0($s2)        		# salva quantidade no cabeçalho
    	li $t9, 1             		# marca que já temos cabeçalho
    	li $v0, 0
    	addi $a1, $a1, 1
    	j loop_char
	
	endLoopChar:
	
	#----------------------------- IMPRIME ARRAY ORIGINAL -----------------------------------------------
	sw $s1, 0($s2) 			# atualiza o primeiro espaço em numeros
	li $v0, 4          		# chama o syscall pra imprimir uma string
    	la $a0, arrayOriginal
    	syscall

    	# ---------- PARAMETROS PARA O PRINTARRAY
    	la $a0, numeros    		# ponteiro para o array
	lw $a1, 0($a0)     		# lê cabeçalho, quantidade de numeros no array
	addi $a0, $a0, 4   		# array real começa no segundo número
	jal printArray      		# chama a funcao para imprimir array

    	#----------------------------- INICIA A CONTAGEM DE TEMPO ---------------------

    	li $v0, 30         		# chama o syscal de tempo para calcular o tempo de execusão
    	syscall
    	move $s0, $a0      		# armazena no registrador s0 o tempo incial

	#-----------------------------  CHAMA SELEÇÃO -------------
	
   	la $a0, numeros      		# endereço do array
    	lw $a1, 0($a0)      		# quantidade de elementos, n
    	addi $a0, $a0, 4    		# ponteiro para o primeiro elemento do array (pula o primeiro numero, que é o tamanho do array)
    	jal selection			# chama a função da seleção

	#----------------------------- FINALIZA A CONTAGEM DE TEMPO ---------------------

    	li $v0, 30                 	# chama o syscall para obter o tempo final
    	syscall  
    	move $s1, $a0              	# armazena no registrador s1 o tempo final

    	# ----- IMPRIME ARRAY ORDENADO
    	li $v0, 4                  	# chama o syscall de imprimir
    	la $a0, arrayOrdenado
    	syscall
    	
    	la $a0, numeros            	# a0 aponta para o inicio do array
    	lw $a1, 0($a0)             	# le a quantidade de elemenetos e armazena em a1
    	addi $a0, $a0, 4           	# vai para o array, sem contar com o primeiro numero
    	jal printArray             	# chama a funcao de printArray
	
    	#--------- CALCULA E IMPRIME O TEMPO DE EXECUÇÃO PARA A ORDENAÇÃO DO ARRAY
    
    	sub $t0, $s0, $s1          	# realiza a subtracao do tempo gasto
                  
    	li $v0, 4                  	# chama o syscall de printar string
    	la $a0, tempoExec               # la(load address) carrega o valor da string, no caso o que foi escrito no regitrador a0
    	syscall
                  
    	li $v0, 1                  	# chama o syscall de printar inteiro
    	move $a0, $t0              	# copia o valor de t0 em a0 para poder imprimir o valor de execusão
    	syscall

    	li $v0, 10                 	# syscall para saida do programa
    	syscall

	#-----------------------------  SELEÇÃO -----------------------------------------------
	selection:
   	# entrada:
   	# $a0 = ponteiro para o primeiro elemento real do array (sem cabeçalho)
    	# $a1 = quantidade de elementos (n)

    	move $s0, $a0        		# guarda ponteiro do array
    	move $s1, $a1        		# guarda tamanho do array

   	li $t0, 0            		# i = 0 (índice)
	
	loopStart:
	#t0 é o nosso i
	slt $t1, $t0, $s1 		# comparar se i é menor que o tamanho que salvamos em s1
	beq $t1, $zero, endSelecao 	# se for falso, que o t1 é zero sai do loop externo
	
	move $t2, $t0               	# menor recebe o indice de i 
    	addi $t3, $t0, 1            	# loop interno, começa j=i+1

    	loopInterno:
    	slt $t4, $t3, $s1               # se j for menor que n, t4 recebe 1 e se não recebe 0
	beq $t4, $zero, internoEnd      # se j maior ou igual n, sai do loop interno

    	sll $t5, $t3, 2                 # t5 recebe j*4, a proxima posicao do array
    	add $t6, $s0, $t5               # t6 recebe o enderenço do array de j
    	lw $t7, 0($t6)                  # t7 recebe o valor do array de j

    	sll $t5, $t2, 2                 # t5 recebe o menor vezes 4, para ir pra proxima posicao
    	add $t6, $s0, $t5               # t6 recebe o endereco do array menor 
    	lw $t8, 0($t6)                  # t8 recebe o valor do array menor 

    	slt $t9, $t7, $t8               # A[j] < A[menor], se o valor do array de j for menor que o valor do array de menor, t9 recebe 1, se nao recebe 0
    	beq $t9, $zero, novoMenor       # se o valor de array de j for maior ou igual ao valor do array de menor, nao entra nesse loop
    	move $t2, $t3                   # menor recebe j, se for menor, marca j como o novo menor.

    	novoMenor:
    	addi $t3, $t3, 1                # incrementa j, j+1
    	j loopInterno                   # retorna ao incio do loop interno

    	internoEnd:                     # faz o swap, a troca
    	sll $t5, $t0, 2                 # t5 recebe i * 4, o primeiro numero do array
    	add $t6, $s0, $t5               # t6 recebe o endereco de i
    	lw $t7, 0($t6)                  # t7 recebe o valor do array de i

    	sll $t5, $t2, 2                 # t5 recebe o menor * 4
    	add $t8, $s0, $t5               # t8 recebe o endereco de array de menor
    	lw $t9, 0($t8)                  # t9 recebe o valor do array de menor

    	sw $t9, 0($t6)                  # array de i recebe array de menor
    	sw $t7, 0($t8)                  # array de menor recebe array de i

    	addi $t0, $t0, 1                # incrementa o i, i+1
    	j loopStart                     # volta para o incio do loop externo

    	endSelecao:
    	jr $ra                        # retorna da funcao

	#--------------------- IMPRIMIR ARRAY ----------------------------------
    	printArray:
    	move $s2, $a0                   # salva o endereco base do array
    	move $s3, $a1                   # salva a quantidade de elementos, na
    	li $t0, 0                       # i recebe 0

    	printLoop:
    	slt $t1, $t0, $s3               # se i for menor que n, quantidade de elementos
	beq $t1, $zero, endPrintLoop
	
    	sll $t2, $t0, 2                 # i * 4, para ir para a proxima posicao
    	add $t3, $s2, $t2               # endereco do array de i
    	lw $a0, 0($t3)                  # carrega o valor para a impressao

    	li $v0, 1                       # chama o syscall de print inteiro
    	syscall

    	li $v0, 4                       # chama o syscall de print string
    	la $a0, space
    	syscall

    	addi $t0, $t0, 1                # incrementa i, i+1
    	j printLoop                     # volta ao incio do loop

    	endPrintLoop:
    	li $v0, 4
    	la $a0, newline
    	syscall
    	jr $ra                          # retorna da funcao
