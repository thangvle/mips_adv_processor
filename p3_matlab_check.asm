

.data			# What follows will be data
	inputEquation: .space 64	# set aside 64 bytes to store the input equation
	prompt: .asciiz "\nEnter MATLAB expression\n"
	start: .asciiz ">>> "
	valid: .asciiz "Valid expression\n"
	invalid: .asciiz "Not a valid expression\n"
	testString: .asciiz "Valid Character!\n"
	
.text

main:
	# Display prompt
	la	$a0, prompt	# display the prompt to begin
	li	$v0, 4	# system call code to print a string to console
	syscall
	
	la	$a0, start	# display the start characters
	li	$v0, 4	# system call code to print a string to console
	syscall
	
	la	$a0, inputEquation	# load $a0 with the address of inputString; procedure: $a0 = buffer, $a1 = length of buffer
	la	$a1, inputEquation	# maximum number of character
	li	$v0, 8	# The system call code to read a string input
	syscall
	
	move $t1, $a0 # store address of word in temporary register
	move $t4, $zero # reset parenthesis counter
	move $t5, $zero # reset parenthesis counter

storeChar:
	lbu $t0, 0($t1) # store next char in t0
space:
	addi $t6, $zero, 0x20 # set t6 equal to space bar
	beq $t0, $t6, validChar # If this is space, branch
	
OpenParen:
	addi $t6, $zero, 0x28 # set t6 equal to (
	beq $t0, $t6, op2 # If equal, branc
	j CloseParen # skip adding to counter
op2: addi $t4, $t4, 1
	j validChar
	
CloseParen:
	addi $t6, $zero, 0x29 # set t6 to )
	beq $t0, $t6, cp2 # If equal, branc
	j MultiplyAndAdd # skip adding to counter
	cp2: addi $t5, $t5, 1
	j validChar
	
MultiplyAndAdd:
	addi $t6, $zero, 0x2A # set t6 equal to first value of first block
	addi $t7, $zero, 0x2C # Set t7 equal to last value of first block + 1
L1:
	beq $t0, $t6, validChar # If this char is in first block, branch
	addi $t6, $t6, 1 # increment t6, check next value
	bne $t6, $t7, L1 # If counter hasn't reached upper limit, loop
	
Subtract:
	addi $t6, $zero, 0x2D # set t6 equal to - 
	beq $t0, $t6, validChar # If equal, branch

Divide:
	addi $t6, $zero, 0x2F # set t6 equal /
	beq $t0, $t6, validChar # If equal, branch
	
Numbers:
	addi $t6, $zero, 0x30 #
	addi $t7, $zero, 0x3A # Set t7 equal to last value of third block + 1
L3:
	beq $t0, $t6, validChar # If this char is in third block, branch
	addi $t6, $t6, 1 # increment t6, check next value
	bne $t6, $t7, L3 # If counter hasn't reached upper limit, loop

Equals:
	addi $t6, $zero, 0x3D # set t6 equal to first value of fourth block
	beq $t0, $t6, validChar # If this char is in fourth block, branch
	
CapitalLetters:
	addi $t6, $zero, 0x41 # set t6 equal to first value of fifth block
	addi $t7, $zero, 0x5B # Set t7 equal to last value of fifth block + 1
L5:
	beq $t0, $t6, validChar # If this char is in fifth block, branch
	addi $t6, $t6, 1 # increment t6, check next value
	bne $t6, $t7, L5 # If counter hasn't reached upper limit, loop
	
LowercaseLetters:
	addi $t6, $zero, 0x61 # set t6 equal to first value of sixth block
	addi $t7, $zero, 0x7B # Set t7 equal to last value of sixth block + 1
L6:
	beq $t0, $t6, validChar # If this char is in fifth block, branch
	addi $t6, $t6, 1 # increment t6, check next value
	bne $t6, $t7, L6 # If counter hasn't reached upper limit, loop
	
NewLine:
	addi $t6, $zero, 0xA # New Line character/ end of expression
	beq $t6, $t0, syntaxloader # branch to valid expression
	
InvalidCharacter:
	j errorMsg # If char isn't in any block must be invalid
	
validChar:
	addi $t1, $t1, 1	# increment memory location counter
	j storeChar 	# jump
	
	
	
syntaxloader:
	move $t1, $a0  # reset character address counter
	lbu $t0, 0($t1) # load first character of expression into t0
syntaxcheck:
	# (
	addi $t6, $zero, 0x28 # load with (
	beq $t0, $t6, tsxChar   # if ( load next character
	# )
	addi $t6, $zero, 0x29 # load with )
	beq $t0, $t6, tsxChar   # if ) load next character
	# *
	addi $t6, $zero, 0x2A # load with *
	beq $t0, $t6, tsxChar   # if * load next character
	# +
	addi $t6, $zero, 0x2B # load with +
	beq $t0, $t6, tsxChar   # if + load next character
	# -
	addi $t6, $zero, 0x2D # load with -
	beq $t0, $t6, tsxChar   # if - load next character
	# /
	addi $t6, $zero, 0x2F # load with /
	beq $t0, $t6, tsxChar   # if / load next character
	condloop:
	addi $t1, $t1, 1 # Get address of next char
	lbu $t0, 0($t1) # Load next char
	addi $t6, $zero, 0xA # New Line character
	beq $t0, $t6, validExpr # If you see a new line character the expression is valid
	j syntaxcheck # If next character is not new line, repeat the process
	
tsxChar:
	addi $t3, $t1, 1 # get the address of the next character
	lbu $t2, 0($t3) # load next char into t2
	# special rules for )
	addi $t6, $zero, 0x29 # load with )
	beq $t0, $t6, parenthesiscnt # if ) go to special syntax rules

oppersyntax:

	addi $t6, $zero, 0x2A #  *
	beq $t2, $t6, errorMsg
	addi $t6, $zero, 0x2D #  -
	beq $t2, $t6, errorMsg
	addi $t6, $zero, 0x2F #  /
	beq $t2, $t6, errorMsg
	addi $t6, $zero, 0x29 #  )
	beq $t2, $t6, errorMsg
	addi $t6, $zero, 0x3D #  =
	beq $t2, $t6, errorMsg
	addi $t6, $zero, 0x2B #  +
	beq $t2, $t6, errorMsg
	
	j condloop

parenthesiscnt:
	# numbers loop
	addi $t6, $zero, 0x30 # first ascii value to check for numbers
	addi $t8, $zero, 0x3A # last ascii value to check for numbers + 1
	L7:
	beq $t2, $t6, errorMsg # if equal branch
	addi $t6, $t6, 1 # increment value
	bne $t6, $t8, L7 # if the counter hasn't reached the max, loop
	
	# uppercase letters loop
	addi $t6, $zero, 0x41 # first ascii value to check for numbers
	addi $t8, $zero, 0x5B # last ascii value to check for numbers + 1
	L8:
	beq $t2, $t6, errorMsg # if equal branch
	addi $t6, $t6, 1 # increment value
	bne $t6, $t8, L8 # if the counter hasn't reached the max, loop
	
	# lowercase letters loop
	addi $t6, $zero, 0x61 # first ascii value to check for numbers
	addi $t8, $zero, 0x7B # last ascii value to check for numbers + 1
	L9:
	beq $t2, $t6, errorMsg # if equal branch
	addi $t6, $t6, 1 # increment value
	bne $t6, $t8, L9 # if the counter hasn't reached the max, loop
	
	j condloop
	
validExpr:
	bne $t4, $t5, errorMsg # if open and close bracket aren't even, invalid
	la	$a0, valid	# display the invalid message
	li	$v0, 4	# system call code to print a string to console
	syscall
	
	j main
	
errorMsg:
	la	$a0, invalid	# display the invalid message
	li	$v0, 4	# system call code to print a string to console
	syscall
	
	j main