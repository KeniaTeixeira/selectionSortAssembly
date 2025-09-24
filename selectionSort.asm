.data
arquivo: .asciiz "/home/kenia/Documentos/Trabalho1AC2/dados.txt"   
space: .asciiz " "
buffer:   .space 1024     # espaço para ler o arquivo
numeros: .space 400 		# espaço para 100 inteiros
.text

main:
	#----------------------------------------------------------------------------
	# --- abrir arquivo ---
	li   $v0, 13           # syscall open
	la   $a0, arquivo
	li   $a1, 0            # modo de abertura: 0 = leitura
	syscall
	#move $s0, $v0          # salva descritor do arquivo

	# --- ler arquivo ---
	li   $v0, 14		# syscall read
	#move $a0, $s0		# descritor do arquivo aberto
	la   $a1, buffer	# destino
	li   $a2, 1024		# tamanho máx
	syscall
	move $t0, $v0		# salva quantidade de bytes realmente lidos

	# --- fechar arquivo ---
	li   $v0, 16		# código da syscall "close file"
	move $a0, $s0
	syscall
	
	#----------------------------------------------------------------------------
	la $t3, numeros   	# ponteiro onde os inteiros convertidos serão armazenados
	# -- transformar em inteiro os valores do arquivo
	
	str_to_int:
	li $v0, 0 		#Inicializando o resultado com zero
	li $t1, 0		#Inicializar o indice 'i' do nosso arquivo com zero
	
	loop_char:			#Vai percorrer o arquivo transformando a string em inteiro
	lb $t2, 0($a1) 			#lê um byte de memória a partir do endereço do buffer que esta os valores
	beq $t2, $zero, endLoopChar 	#Se for falso, que o t2 é zero sai do loopStart (fim da string)
	
	beq $t2, 32, store_num      # espaço ' '? salva número
   	beq $t2, 10, store_num      # newline '\n'? salva número
	
	addi $t2, $t2, -48 		#Converte pro valor da tabela ASCII
	mul $v0, $v0, 10 		#Multiplica o resultado por 10
	add $v0, $v0, $t2 		#Adiciona o digito ao resultado
	
	addi $a1, $a1, 1		#Soma 1 no loop
	j loop_char
	
	store_num:
    	sw $v0, 0($t3)              # salva número no array
    	addi $t3, $t3, 4            # próximo slot
    	li $v0, 0                   # zera acumulador
    	addi $a1, $a1, 1            # pula espaço/newline
    	j loop_char
	
	endLoopChar:
	
	#----------------------------------------------------------------------------
		
	la $t3, numeros    # início do array
	lw $t4, 0($t3)     # lê cabeçalho
	addi $a0, $t3, 4   # array real começa no segundo número
	move $a1, $t4      # quantidade de elementos (vem do cabeçalho)

	#-----------------------------  CHAMA SELEÇÃO E DEPOIS FECHA O PROGRAMA -------------
	
	jal selection		#Chama a função da seleção
	# terminar
	li   $v0, 10		# código da syscall "exit"
	syscall
	
	#-----------------------------  SELEÇÃO -----------------------------------------------
	selection:
   	# entrada:
   	# $a0 = ponteiro para o primeiro elemento real do array (sem cabeçalho)
    	# $a1 = quantidade de elementos

    	move $s0, $a0        # guarda ponteiro do array
    	move $s1, $a1        # guarda tamanho do array

   	li $t0, 0            # i = 0 (índice)
	
	loopStart:
	#t0 é o nosso i
	slt $t1, $t0, $s1 		#Comparar se i é menor que o tamanho que salvamos em s1
	beq $t1, $zero, loopEnd 	#Se for falso, que o t1 é zero sai do loopStart
	
	#Logica do trem
	
	#Imprimindo
	sll $t2, $t0, 2       # t2 = i * 4
    	add $t3, $s0, $t2     # # t3 = s0 + i*4 -> endereço de array[i]
    	lw $a0, 0($t3)       # carrega array[i] em $a0

    	li $v0, 1             # print_int porque o outro é de string
    	syscall
	
	# espaço entre os valores
    	li $v0, 4
    	la $a0, space
    	syscall
	
	addi $t0, $t0, 1 #Incrementa 1 no i
	
	j loopStart 	#Saindo do primeiro for
	loopEnd: #Quando for falso, vem pra cá

	#Parte que usao o print_string, mudar ele para o ordenado
	# --- imprimir o conteúdo lido ---
	#li   $v0, 4		# syscall print_string
	#la   $a0, buffer	# endereço do buffer
	#syscall

	#sll $t2, $t0, 2       # t2 = i * 4
    	#add $t3, $s0, $t2     # # t3 = s0 + i*4 -> endereço de array[i]
    	#lw $a0, 0($t3)       # carrega array[i] em $a0

    	#li $v0, 1             # print_int porque o outro é de string
    	#syscall
	
	# espaço
    	#li $v0, 4
    	#la $a0, space
    	#syscall
