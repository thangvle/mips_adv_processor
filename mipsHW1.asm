.data 
	prompt: .asciiz "Enter a string: " 
	userInput: .space 64 
	array: .space 64 
	
.text 

main: 
	#printing prompt
	li $v0, 4
	la $a0, prompt	
	syscall
	
	#getting user input
	li $v0, 8
	la $a0, userInput
	la $a1, userInput
	syscall
	
	
	#printing user input
	li $v0, 4
	la $a0, userInput
	syscall 
	
	
	
	# need function call: jal 
	# working on stack register 
	# end of program procedure 
	li $v0, 10
	syscall 
	#storing user input string to array 
		
strcpy:	addi $sp, $sp, -4	# allocate 1 word on the stack 
	sw $s0, 0($sp) 		# save $s0 in the upper one 
	add $s0, $zero, $zero 	# i = 0
	
L1:	add $t1, $s0, $a1 	# add address of y[i] in $t1 
	lbu $t2, 0($t1) 	# $t2 = y[i]
	add $t3, $s0, $a0	# add address of x[i] in $t3 
	sb $t2, 0($t3) 		# x[i] = y[i]
	beq $t2, $zero, L2 	# if y[i] == 0, exit 
	addi $s0, $s0, 1	# i = i + 1
	j L1			# jump back to loop 
	
L2: 	lw $s0, 0($sp) 		# load a word at 0($sp) into register $s0 
	addi $sp, $sp, 4	# restore stack pointer
	jr $ra			# jump back to where it 
	
	
	
