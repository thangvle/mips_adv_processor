.data 

prompt: .asciiz "\n>> " # Prompt the user
userInput: .space 64
syntax_error: .asciiz "Invalid Syntax\n"
invalidChar: .asciiz "Invalid character input\n" 
quit: .asciiz "quit\n" 
sign: "+-*/"


.text
main: 
	# load prompt
	li $v0, 4
	la $a0, prompt 
	syscall

	la $a0, userInput # loading adress of user input
	la $a1, userInput #loading the size of the userinput
	li $v0, 8  # system call to read string input
	syscall

	# validity check 
	jal readInputLoop
	la $t0, userInput 
	jal validityCheck 

readInputLoop: 
	lb $t0, ($a0) 		# load byte from input at $a0 to temp reg $t0 
	addi $a0, $a0, 1	# advance to next char
	beq $t0, 0, return 	# if input reached the end, return back to main 
	bne $t0, 10, readInputLoop	# if character is not "\n", go back to loop

	li $t1, 0
	sb $t1, -1($a0) 

	jr $ra 

	
	
validityCheck: 
# li $v0 (0 true, 1 false) 
	addi $sp, $sp, -4
	sw $ra, ($sp) 
	
	li $v0, 0
check_loop:	
	lb $a0, ($t0)		# Read character to parameter
	beq $a0, 0, returnValidCheck # Check if we are in the end of string.
	jal charCheck
	beq $v0, 1, returnValidCheck  # $v0 = 1, return that string is illegal
	addi $t0, $t0, 1		# Next character
	j check_loop
		
	
returnValidCheck:
	lw $ra, ($sp)		# Load return address from stack
	addi $sp, $sp, 4
	jr $ra
	
charCheck:
	sle $t2, $a0, 57		# compare if input is less than 9 (ascii #57)
	sge $t3, $a0, 48		# compare if input is greater than 0 (ascii #48) 
	and $t3, $t2, $t2
	beq $t3, 1, return 

sign_check:
	lw $t2, ($t1)			# load sign
	beq $t2, 0, syntax_invalid 	# when sign is not found
	addi $t1, $t1, 1		# move to next sign	
	beq $t2, $a0, return		# exit if sign is found
	j sign_check 			# loop back if sign is not found

return:	jr $ra 
	
syntax_invalid: 
	li $v0, 4
	la $a0, syntax_error
	syscall 
	j main 
	

	
