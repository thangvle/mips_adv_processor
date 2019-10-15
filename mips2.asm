.data 

prompt: .asciiz "\n>> " # Prompt the user
new_line: .asciiz "\n"
userInput: .space 64
syntax_error: .asciiz "Invalid Syntax\n"
invalidChar: .asciiz "Invalid character input\n" 

sign: .asciiz "+-*/"


.text
main: 
	la $s0, userInput			# load input to $s0 for string to int conversion usage
	
	# load prompt
	li $v0, 4
	la $a0, prompt 
	syscall

	la $a0, userInput 			# loading adress of user input
	la $a1, userInput 			# loading the size of the userinput
	li $v0, 8  				# system call to read string input
	syscall

	# validity check 
	jal readInputLoop
	
	move $t0, $a0
	
	la $t1, sign 				# load $t1 with sign char
	jal validityCheck 
	
	jal calculation 

	lw $t0, ($sp)				# Load result from stack
	move $a0, $t0				# move result from $t0 to $a0 for display
	
	li	$v0, 1
	syscall
	la	$a0, new_line			# Print '\n'
	li	$v0, 4
	syscall				
		
	j main
readInputLoop: 
	lb $t0, ($a0) 				# load byte from input at $a0 to temp reg $t0 
	addi $a0, $a0, 1			# advance to next char
	beq $t0, 0, return 			# if input reached the end, return back to main 
	bne $t0, 10, readInputLoop		# if character is not "\n", go back to loop

	li $t1, 0
	sb $t1, -1($a0) 

	jr $ra 


#################################

# Syntax check 
	
validityCheck: 
# li $v0 (0 true, 1 false) 
	addi $sp, $sp, -4
	sw $ra, ($sp) 
	
	li $v0, 0
check_loop:	
	lb $a0, ($t0)				# Read character to parameter
	beq $a0, 0, returnValidCheck 		# Check if we are in the end of string.
	jal charCheck
	beq $v0, 1, returnValidCheck  		# if $t3 = 1, return that string is illegal
	addi $t0, $t0, 1			# Next character
	j check_loop
		
	
returnValidCheck:
	lw $ra, ($sp)				# Load return address from stack
	addi $sp, $sp, 4
	jr $ra
	
charCheck:
	sle $t2, $a0, 57			# compare if input is less than 9 (ascii #57)
	sge $t3, $a0, 48			# compare if input is greater than 0 (ascii #48) 
	and $t3, $t2, $t2
	beq $t3, 1, return 

sign_check:
	lw $t2, ($t1)				# load sign
	beq $t2, 0, syntax_invalid 		# when sign is not found
	addi $t1, $t1, 4			# move to next sign	
	beq $t2, $a0, return			# exit if sign is found
	j sign_check 				# loop back if sign is not found

return:	jr $ra 


	
syntax_invalid: 
	li $v0, 4
	la $a0, syntax_error
	syscall 
	j main 
	
#######################################

# Calculation 

calculation:		
		addi $sp, $sp, -4		# Write return address to calculation to stack
		sw $ra, ($sp)
		jal high_priority
		
		
		# do add and subtract while (sign == "+" or "-")
calculation_loop:
		lb $t2, ($s0)			# load input from $s0
		sne $t3, $t2, 0			# check if char != \0 
		seq $t4, $t2, 45		# check if char == '-' 
		seq $t5, $t2, 43		# check if char == '+' 
		  
		addi $sp, $sp, -4
		sw $t5, ($sp)			# save the sign to the stack
				
		or $t4, $t4, $t5		# check if the sign is "*" or "/"
		and $t3, $t3, $t4		
		beq $t3, 0, calculation_return
		addi $s0, $s0, 1		# Next char
		
		jal term
		
		lw $t4, ($sp)			# Load second operand
		addi $sp, $sp, 4
		lw $t5, ($sp)			# Check if sign is "+"
		addi $sp, $sp, 4
		lw $t6, ($sp)			# Load first operand


		beq $t5, 1, calculation_add
		
calculation_sub:
		sub  $t6, $t4, $t4
		sw $t6, ($sp)
		j calculation_loop
calculation_add:
		add $t6, $t4, $t4
		sw $t6, ($sp) 
		j calculation_loop

calculation_return:
		addi $sp, $sp, 4
		lw $t0, ($sp)			# Load result from stack
		addi $sp, $sp, 4
		lw $ra, ($sp)			# Load return address to calculation from stack
		sw $t0, ($sp)			# Save result to stack(result now replaced the return address)
		jr $ra

# Handles * and / operations

high_priority:		
		addi $sp, $sp, -4		# Write return address to calculation to stack
		sw $ra, ($sp)
		jal number
		
		# Do multiplication and division while input != \0 and sign == "*" or "/"
term_loop:
		lb $t2, ($s0)			# Read char
		sne $t3, $t2, 0			# check if input reached the end
		seq $t4, $t2, 47		# char == '/' ?
		seq $t5, $t2, 42		# char == '*' ?
		
		addi $sp, $sp, -4
		sw $t5, ($sp)			# Save sign to stack 
				
		or $t4, $t4, $t5		
		and $t3, $t3, $t4
		beq $t3, 0, priority_return
		addi $s0, $s0, 1		# Next char
		
		jal number
		
		lw $t4, ($sp)			# Load second operand
		addi $sp, $sp, 4
		lw $t5, ($sp)			# Check if multiplication
		addi $sp, $sp, 4
		lw $t6, ($sp)			# Load first operand
		beq $t5, 1, muliply
		
divide:
		div $t6, $t4, $t4
		sw $t6, ($sp)
		j term_loop

muliply:	
		mul $t6, $t4, $t4
		sw $t6, ($sp) 
		j term_loop

priority_return:
		addi $sp, $sp, 4
		lw $t0, ($sp)			# Load result from stack
		addi $sp, $sp, 4
		lw $ra, ($sp)			# Load return address to calculation from stack
		sw $t0, ($sp)			# Save result to stack(result now replaced the return address)
		jr $ra

#######################################
# String to integer conversion 

# Check if there is parenthesis 

number:
		addi $sp, $sp, -4
		sw $ra, ($sp)			# Save return address to term to stack
		
		lb $t0, ($s0)			# Read character		
		bne $t0, 40, no_parenthesis  	# Check if there is a parenthesis
		
		addi $s0, $s0, 1		# Next character
		jal calculation			# Recursively start new calculation
		lb $t0, ($s0)			# Read character
		sne $t1, $t0, 41		
		seq $t2, $t0, 0
		or $t1, $t1, $t2		# If char != ')' or char == '\0'
		bne $t1, 0, syntax_invalid

		addi $s0, $s0, 1		# Next character
		j number_return

no_parenthesis:		
		jal atoi
		
number_return:	lw $t0, ($sp)			 
		addi $sp, $sp, 4
		lw $ra, ($sp)			# load result from $ra (atoi)
		sw $t0, ($sp)			# and save to $t0 
		jr $ra


# Reads number from input string, converts it to integers and writes the integers to stack

atoi:		
		lb $t1, ($s0)			# Read character
		sle $t2, $t1, 57		# Check if character is '0' - '9'
		sge $t3, $t1, 48
		and $t3, $t2, $t3
		beq $t3, 0, syntax_invalid 
		
		li $t0, 0			# Save length of number to $t0
		
atoi_loop:	lb $t1, ($s0)			# Read character
		sle $t2, $t1, 57
		sge $t3, $t1, 48
		and $t3, $t2, $t3		# Check if digit is in the range 0-9
		
		addi $t0, $t0, 1		# Extend the length by 1
		addi $s0, $s0, 1		# Advance to next char
		beq $t3, 1, atoi_loop		# Check if char is a digit
		
		addi $t0, $t0, -1		# Subtract the spare loop interation
		move $t1, $t0			# Move the length of the number to $t1
		li $t5, 1
		li $t6, 0			# Total value of number
		li $t7, 10
		addi $s0, $s0, -2		# Go back to the last digit.
		
		
convert_loop:	lb $t4, ($s0)			# Read digit
		addi $t4, $t4, -48		# Convert digit to number '0' ascii is 48, 48 - 48 == 0
		addi $t1, $t1, -1		
		mul $t4, $t4, $t5		# $t4 = $t4 * $t5 
		add $t6, $t6, $t4		# add digit together
	
		mul $t5, $t5, $t7		# $t5 = $t5 * 10
		addi $s0, $s0, -1		# Move to previous digit
		bne $t1, 0, convert_loop
		
		add $s0, $s0, $t0		# Go back to last digit
		addi $s0, $s0, 1		# Next char
						
atoi_return:	
		addi $sp, $sp, -4
		sw  $t6, ($sp) 		# save conversion result to stack 
		jr $ra			# Jump back to number

	
