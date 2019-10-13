#trial run 3 for mips 2 bs, created by Mark M. Fahim on 10.8.2018


.data

inputString: .space 64	# set aside 64 bytes to store the input string
stringout: .asciiz "\nthis is for debugging, our counter is "
invalid: .asciiz "Invalid syntax" 

.text	
	
main: 
		
	la	$a0, inputString	# load $a0 with the address of inputString; procedure: $a0 = buffer, $a1 = length of buffer
	la	$a1, inputString	# maximum number of character
	li	$v0, 8	# The system call code to read a string input
	syscall
	
	move $t0, $a0 # store address of word in temporary register
	move $t8, $zero
	move $t9, $zero
		
## $a2 is input
## $a3 is output
	
	IsNumber:
	addi $a3, $zero, 0 # set the output to false
	addi $t4, $zero, 0x30 # Set to ascii 0
	addi $t5, $zero, 0x3A # Set to ascii 9 + 1
	L6:
	beq $a2, $t4, Output1 # If this char is in third block, branch
	addi $t4, $t4, 1 # increment t4, check next value
	bne $t4, $t5, L6 # If counter hasn't reached upper limit, loop
	j return1
	Output1:
	addi $a3, $zero, 1 # set the output to true
	return1:
	jr $ra

	
	IsLetter:
	addi $a3, $zero, 0 # set the output to false
	addi $t4, $zero, 0x41 # set t4 equal to ascii A
	addi $t5, $zero, 0x5B # Set t5 equal to ascii Z + 1
	L7:
	beq $a2, $t4, Output2 # If this char is A-Z
	addi $t4, $t4, 1 # increment t4, check next value
	bne $t4, $t5, L7 # If counter hasn't reached upper limit, loop
	
	addi $t4, $zero, 0x61 # set t4 equal to ascii a
	addi $t5, $zero, 0x7B # Set t5 equal to ascii z + 1
	L8:
	beq $a2, $t4, Output2  # If this char is a-z
	addi $t4, $t4, 1 # increment t4, check next value
	bne $t4, $t5, L8 # If counter hasn't reached upper limit, loop
	j return2
	Output2:
	addi $a3, $zero, 1 # set the output to true
	return2:
	jr $ra

	
################################ End ############################################		

	
validExpr:
	bne $t6, $zero, invalidExpr # if open and close bracket aren't even, invalid
	j evaluate
	
invalidExpr:
	la	$a0, invalid	# display the invalid message
	li	$v0, 4	# system call code to print a string to console
	syscall
	j main
	
	
########################## Convert ascii to numbers ################################

evaluate:
	la $t0, equWithoutWhite # reset string position, evaluate equation without spaces
	move $t1, $zero
	la $t2, equWithNumbers # set address of equation with numbers
	move $t3, $zero
	beq $t8, $zero, L9 # if equals flag is set put variable in register
	lb $t9, 0($t0) 
	addi $t0, $t0, 2 # increment address counter 2 spaces
	
	L9:
	lb $t1, 0($t0)  # load char from equation without white space

	move $a2, $t1  # see if char is a number
	jal IsNumber
	beq $a3, $zero, checkVariable # if its a number continue, else branch
	L10:
	addi $t1, $t1, -48 # convert ascii to decimal
	add $t3, $t3, $t1 # add the value to the running total
	addi $t0, $t0, 1 # increment address counter
	lb $t1, 0($t0) # load the next character
	move $a2, $t1 # check if the next character is a number
	jal IsNumber
	beq $a3, $zero, E1 # if it isn't a number store what you have
	mul $t3, $t3, 10 # if it is a number, x10
	j L10 # jump to start of loop
	E1:
	sw $t3, 0($t2) # store the word
	addi $t2, $t2, 4 # increment to next word
	move $t3, $zero # reset running total
	j L9
	
	checkVariable:
	# a2 already loaded with character
	jal IsLetter
	beq $a3, $zero, checkPlusMinus # if its not a variable check for an opperand
	la $t5, variables # if it is a letter, check if its a stored variable
	L11:
	lw $t6, 0($t5)
	beq $t6, $t1, N13 # if variable is in memory, retrieve value
	beq $t6, $zero, undefinedVar # if you reach null, the variable is undefined
	addi $t5, $t5, 4 # move address pointer to next word
	j L11 # loop, check next variable
	N13:
	addi $t5, $t5, 64 # get the address of the variable
	lw $t6, 0($t5) # load the variable from memory
	sw $t6, 0($t2) # store the variable value
	addi $t2, $t2, 4 # increment to next word
	addi $t0, $t0, 1 # increment to next byte
	j L9
	undefinedVar:
	la $a0, undefined # display the undefined message
	li $v0, 4 # system call code to print a string to console
	syscall
	j main
	
	
	checkPlusMinus:
	move $t3, $zero
	beq $t1, '+', plusMinus
	beq $t1, '-', plusMinus
	j checkMulDivParen
	plusMinus:
	addi $t0, $t0, 1
	lb $t3, 0($t0)
	beq $t3, '+', plusMinus # after you increment is there another + or -
	beq $t3, '-', L12 # if there is a minus jump to function to reverse
	N14:
	lw $t3, -4($t2) # get the char that came before this + or -
	beq $t3, $zero, N16
	beq $t3, '(', N16
	beq $t3, '*', N16
	beq $t3, '/', N16
	N15:
	sw $t1, 0($t2) # if there isn't, store word
	addi $t2, $t2, 4 # increment counter for equation with numbers
	move $t3, $zero # reset t3
	j L9 # jump to top of loop
	N16:
	beq $t1, '-', N17
	move $t3, $zero
	j L9
	N17:
	lb $t3, 0($t0)
	addi $t3, $t3, -48
	mul $t3, $t3, -1
	sw $t3, 0($t2)
	addi $t2, $t2, 4
	addi $t0, $t0, 1
	move $t3, $zero
	j L9
	L12: 
	beq $t1, '+', ptm  # is current value +
	beq $t1, '-', mtp  # is current value -
	ptm: addi $t1, $zero, 45  # load t1 with -
	j plusMinus
	mtp: addi $t1, $zero, 43  # load t1 with +
	j plusMinus
	
		
	checkMulDivParen:
	beq $t1, '*', N18
	beq $t1, '/', N18
	beq $t1, '(', N18
	beq $t1, ')', N18
	j checkNewLine
	N18:
	sw $t1, 0($t2) # if there isn't, store word
	addi $t2, $t2, 4 # increment counter for equation with numbers
	addi $t0, $t0, 1 # increment counter for ascii equation
	move $t3, $zero # reset t3
	j L9 # jump to top of loop
	
	checkNewLine: # if you reach the newline character, move to next section
	sw $t1, 0($t2)
	j analyzer
	
	
	
c_reset:
 	add $s2, $zero, $zero
		j analyzer
		
analyzer:
		#assuming operand1 = $t0, operator1 = $t1, operand2 = $t2, operator2 = $t3, operand3 = $t4, priority = $t5
		la $t5, equWithNumbers # reset string position, evaluate equation without spaces
		lw $t0, 0($t5)
		lw $t1, 4($t5)
		lw $t2, 8($t5)
		lw $t3, 12($t5)
		lw $t4, 16($t5)
			
		beq $t1, '*', first
		beq $t1, '/', first
		beq $t3, '*', second
		beq $t3, '/', second

first:		
		#perform operation1 on operand1 and operand2
		#set priority to 1 for default operations
		li $t5, 1
		move $a0, $t0
		move $a1, $t2	
		beq $t1, '+', addit1
		beq $t1, '-', subtr1
		beq $t1, '*', multi1
		beq $t1, '/', divis1
		
first2:
		#perform operation2 on result and operand3
		#place operand in $a1
		move $a1, $t4
				
		beq $t3, '+', addit1
		beq $t3, '-', subtr1
		beq $t3, '*', multi1
		beq $t3, '/', divis1
		
		move $t1, $a0
		sw $t1, equWithNumbers
		j end

second:		#perform operation2 on operand2 and operand3
		#set priority to 2 for default operations
		li $t5, 2
		move $a0, $t2
		move $a1, $t4
		beq $t3, '+', addit2
		beq $t3, '-', subtr2
		beq $t3, '*', multi2
		beq $t3, '/', divis2	
second2:
		#perform operation 1 on operand1 and result 
		move $a1, $a0	#puts result into $a1
		move $a3, $a0	#saves result in case it's lost on 2nd pass
		move $a0, $t0
		beq $t1, '+', addit1
		beq $t1, '-', subtr1
		beq $t1, '*', multi1
		beq $t1, '/', divis1		 
	
		move $a0, $a3	#retains result
		move $t1, $a0
		sw $t1, equWithNumbers
		j end

addit1:		
		#place the operands in $a0 and $a1
		#reset operation
		li $t1, 0
		jal addition

addit2:		
		#place the operands in $a0 and $a1
		#reset operation
		li $t3, 0
		
		jal addition
	
subtr1:		#place the operands in $a0 and $a1
		#reset operation
		li $t1, 0
		
		jal subtraction
	
subtr2:		#place the operands in $a0 and $a1
		#reset operation
		li $t3, 0
		
		jal subtraction

multi1:		#place the operands in $a0 and $a1
		#reset operation
		li $t1, 0
		
		jal multiplication

multi2: 	#place the operands in $a0 and $a1
		#reset operation
		li $t3, 0
		
		jal multiplication
		
divis1:		#place the operands in $a0 and $a1
		#reset operation
		li $t1, 0
		
		jal division
		
divis2:  	#place the operands in $a0 and $a1
		#reset operation
		li $t3, 0
		
		jal division
		
addition:
		#take the operands perform addition
		add $a0, $a0, $a1
		
		beq $t5, 1, Jumpfirst
		beq $t5, 2, Jumpsecond

subtraction:	#take the operands perform subtraction
		sub $a0, $a0, $a1
		
		beq $t5, 1, Jumpfirst
		beq $t5, 2, Jumpsecond

multiplication:  #take the operands perform multiplication
		mult $a0, $a1
		mflo $a0

		beq $t5, 1, Jumpfirst
		beq $t5, 2, Jumpsecond

division:	#take the operands perform division
		div $a0, $a0, $a1
		
		beq $t5, 1, Jumpfirst
		beq $t5, 2, Jumpsecond

Jumpfirst:
		j first2

Jumpsecond:
		j second2
	
#####################################################################
end:
	beq $t8, $zero, end1 # if this was not an equality
	# if it is an equality
	la $t5, variables # if it is a letter, check if its a stored variable
	end2:
	lw $t6, 0($t5)
	beq $t6, $t9, storeVar # if variable is in memory, replace value
	beq $t6, $zero, storeVar # if you reach null, the variable is undefined
	addi $t5, $t5, 4 # otherwise, move address pointer to next word
	j end2 # loop, check next variable
	storeVar:
	sw $t9, 0($t5) # store the variable ascii value
	lw $t0, equWithNumbers # get the final answer
	sw $t0, 64($t5)
	# print variable  
	move $a0, $t5
	li $v0, 4
	syscall 
	la $a0, spaceEqualsSpace
	li $v0, 4
	syscall
	
	
	end1:
	
	lw $t0, equWithNumbers # get the final answer
	li $t2, 10 # set $t2 to 10 for division purposes
	div $t0, $t2 # divide by 10 to get least significant (1s)
	mfhi $t1 # move remainder to output
	addi $t1, $t1, 48
	add $t3, $t3, $t1
	sll $t3, $t3, 8
	mflo $t0 # move quotent to be calculated
	div $t0, $t2 # divide by 10 to get least significant(10s)
	mfhi $t1 # move remainder to output
	addi $t1, $t1, 48
	add $t3, $t3, $t1
	sll $t3, $t3, 8
	mflo $t0 # move quotent to be calculated
	div $t0, $t2 # divide by 10 to get least significant(100s)
	mfhi $t1 # move remainder to output
	addi $t1, $t1, 48
	add $t3, $t3, $t1
	sll $t3, $t3, 8
	mflo $t0 # move quotent to be calculated
	div $t0, $t2 # divide by 10 to get least significant(1000s)
	mfhi $t1 # move remainder to output
	addi $t1, $t1, 48
	add $t3, $t3, $t1
	# final answer stored in $t3
	sw $t3, equWithNumbers
	
	
	la	$a0, equWithNumbers	# display the prompt to begin
	li	$v0, 4	# system call code to print a string to console
	syscall

	# clear memory
	la $a2, equWithoutWhite # load address as input
	jal eraseMem # jump to function
	la $a2, equWithNumbers
	jal eraseMem # jump to function

	j main

	# clear memory function
	eraseMem:
	lw $a3, 0($a2)
	beq $a3, $zero erased
	sw $zero, 0($a2)
	addi $a2, $a2, 4
	j eraseMem
	erased:
	jr $ra
		
		
