.data 

prompt: .asciiz "\n>> " # Prompt the user
new_line: .asciiz "\n"
userInput: .space 64
syntax_error: .asciiz "Invalid Syntax\n"
invalidChar: .asciiz "Invalid character input\n" 

sign: .asciiz "+-*/"


.text
main: 
	la $s0, userInput 
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
	
	move $t0, $a0
	
	la $t1, sign 
	jal validityCheck 
	
	jal calculation 

	lw $t0, ($sp)		# Load result from stack
	move $a0, $t0
	#mtc1 $t0, $f12

	li	$v0, 1
	syscall
	la	$a0, new_line		# Print '\n'
	li	$v0, 4
	syscall				
		
	j main
readInputLoop: 
	lb $t0, ($a0) 		# load byte from input at $a0 to temp reg $t0 
	addi $a0, $a0, 1	# advance to next char
	beq $t0, 0, return 	# if input reached the end, return back to main 
	bne $t0, 10, readInputLoop	# if character is not "\n", go back to loop

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
	lb $a0, ($t0)		# Read character to parameter
	beq $a0, 0, returnValidCheck # Check if we are in the end of string.
	jal charCheck
	beq $v0, 1, returnValidCheck  # if $t3 = 1, return that string is illegal
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
	addi $t1, $t1, 4		# move to next sign	
	beq $t2, $a0, return		# exit if sign is found
	j sign_check 			# loop back if sign is not found

return:	jr $ra 


	
syntax_invalid: 
	li $v0, 4
	la $a0, syntax_error
	syscall 
	j main 
	
#######################################

# Calculation 

calculation:		
		addi	$sp, $sp, -4		# Write return address to calculation to stack
		sw	$ra, ($sp)
		jal	term
		
		# while ( read_char != '\0' and (read_char == '-' or read_char == '+') )
calculation_loop:
		lb	$t2, ($s0)		# Read char
		sne	$t3, $t2, 0		# check if char != \0 
		seq	$t4, $t2, 45		# check if char == '-' ?
		seq	$t5, $t2, 43		# check if char == '+' ?
		  
		addi	$sp, $sp, -4
		sw	$t5, ($sp)		# Save boolean "Is this addition(+) operation" to stack
				
		or	$t4, $t4, $t5		# char != '\0' and (char == '/' or char == '*')
		and	$t3, $t3, $t4
		beq	$t3, 0, calculation_return
		addi	$s0, $s0, 1		# Next char
		
		jal	term
		
		lw	$t4, ($sp)		# Load second operand
		addi	$sp, $sp, 4
		lw	$t5, ($sp)		# Load "Is this addition(+) operation" boolean
		addi	$sp, $sp, 4
		lw	$t6, ($sp)		# Load first operand

		#mtc1	$t6, $f2		# First operand -> $f2
		#mtc1	$t4, $f4		# Second operand -> $f4	
		beq	$t5, 1, calculation_add
		
calculation_sub:
		#sub.s	$f2, $f2, $f4		# Substitute the operands to $f2
		#swc1	$f2, ($sp)		# Move result to stack
		sub 	$t6, $t4, $t4
		sw	$t6, ($sp)
		j	calculation_loop
calculation_add:
		#add.s	$f2, $f2, $f4		# Add the operands to $f2
		#swc1	$f2, ($sp)		# Move result to stack	
		add	$t6, $t4, $t4
		sw 	$t6, ($sp) 
		j	calculation_loop

calculation_return:
		addi	$sp, $sp, 4
		lw	$t0, ($sp)		# Load result from stack
		addi	$sp, $sp, 4
		lw	$ra, ($sp)		# Load return address to calculation from stack
		sw	$t0, ($sp)		# Save result to stack(result now replaced the return address)
		jr	$ra

# Handles * and / operations
# term ::= number("*"|"/" number)*
term:		
		addi	$sp, $sp, -4		# Write return address to calculation to stack
		sw	$ra, ($sp)
		jal	number
		
		# while ( read_char != '\0' and (read_char == '/' or read_char == '*') )
term_loop:
		lb	$t2, ($s0)		# Read char
		sne	$t3, $t2, 0		# char != \0 ?
		seq	$t4, $t2, 47		# char == '/' ?
		seq	$t5, $t2, 42		# char == '*' ?
		
		addi	$sp, $sp, -4
		sw	$t5, ($sp)		# Save boolean "Is this multiply(*) operation" to stack
				
		or	$t4, $t4, $t5		# char != '\0' and (char == '/' or char == '*')
		and	$t3, $t3, $t4
		beq	$t3, 0, term_return
		addi	$s0, $s0, 1		# Next char
		
		jal	number
		
		lw	$t4, ($sp)		# Load second operand
		addi	$sp, $sp, 4
		lw	$t5, ($sp)		# Load "Is this multiply(*) operation" boolean
		addi	$sp, $sp, 4
		lw	$t6, ($sp)		# Load first operand

		#mtc1	$t6, $f2		# First operand -> $f2
		#mtc1	$t4, $f4		# Second operand -> $f4	
		beq	$t5, 1, term_mul
		
term_div:	#div.s	$f2, $f2, $f4		# Divide the operands to $f2
		#swc1	$f2, ($sp)		# Move result to stack
		div	$t6, $t4, $t4
		sw	$t6, ($sp)
		j	term_loop

term_mul:	#mul.s	$f2, $f2, $f4		# Multiply the operands to $f2
		#swc1	$f2, ($sp)		# Move result to stack	
		mul 	$t6, $t4, $t4
		sw 	$t6, ($sp) 
		j	term_loop

term_return:	addi	$sp, $sp, 4
		lw	$t0, ($sp)		# Load result from stack
		addi	$sp, $sp, 4
		lw	$ra, ($sp)		# Load return address to calculation from stack
		sw	$t0, ($sp)		# Save result to stack(result now replaced the return address)
		jr	$ra


# Returns number to term
# number ::= ("0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|",")+
number:
		addi	$sp, $sp, -4
		sw	$ra, ($sp)		# Save return address to term to stack
		
		lb	$t0, ($s0)		# Read character		
		bne	$t0, 40, no_new_calculation  # If char != '(', skip section
		
		addi	$s0, $s0, 1		# Next character
		jal	calculation		# Recursively start new calculation
		lb	$t0, ($s0)		# Read character
		sne	$t1, $t0, 41		
		seq	$t2, $t0, 0
		or	$t1, $t1, $t2		# If char != ')' or char == '\0'
		bne	$t1, 0, syntax_invalid

		addi	$s0, $s0, 1		# Next character
		j	number_return

no_new_calculation:		
		jal	atof
		
number_return:	lw	$t0, ($sp)
		addi	$sp, $sp, 4
		lw	$ra, ($sp)
		sw	$t0, ($sp)
		jr	$ra


# Reads number from input string, converts it to float and writes the float to stack
# Maximum number is 2^31 - 1 = 2147483647
# If string is '123', it counts the length of string = 3
# then it loops from the last digit to first:
# $t6 += 3 * 1
# $t6 += 2 * 10
# $t6 += 1 * 100
# Then $t6 = 123
atof:		
		lb	$t1, ($s0)		# Read character
		sle	$t2, $t1, 57		# Check that character is '0' - '9'
		sge	$t3, $t1, 48
		and	$t3, $t2, $t3
		beq	$t3, 0, syntax_invalid 
		
		
		li	$t0, 0			# Save length of number to $t0
atof_loop:	lb	$t1, ($s0)		# Read character
		sle	$t2, $t1, 57
		sge	$t3, $t1, 48
		and	$t3, $t2, $t3		# $t3 = character is '0' - '9'
		
		addi	$t0, $t0, 1		# Increase length
		addi	$s0, $s0, 1		# Next character
		beq	$t3, 1, atof_loop	# Read character was a digit, read next character
		
		addi	$t0, $t0, -1		# Loop adds 1 times too much
		move	$t1, $t0		# Length of the number to $t1
		li	$t5, 1
		li	$t6, 0			# Total value of number
		li	$t7, 10
		addi	$s0, $s0, -2		# Loop adds too muchs, go back to the last digit.
		
		li	$v0, 0
convert_loop:	lb	$t4, ($s0)		# Read digit
		addi	$t4, $t4, -48		# Convert it to number '0' ascii is 48, 48 - 48 == 0
		addi	$t1, $t1, -1		#
		mul	$t4, $t4, $t5		# $t4 = $t4 * $t5, number * 10^x
		add	$t6, $t6, $t4		# Add number to total value
		#beq	$v0, 1, error_overflow
		mul	$t5, $t5, $t7		# $t5 = $t5 * 10
		addi	$s0, $s0, -1		# Move to previous digi
		bne	$t1, 0, convert_loop
		
		add	$s0, $s0, $t0		# Move cursor back to last digit
		addi	$s0, $s0, 1		# Next char
						
atof_return:	#mtc1	$t6, $f0		# Move total number to coprocessor
		#cvt.s.w	$f0, $f0
		addi	$sp, $sp, -4
		#swc1	$f0, ($sp)		# Save converted number to stack
		sw 	$t6, ($sp) 
		jr	$ra			# Jump back to number

	
