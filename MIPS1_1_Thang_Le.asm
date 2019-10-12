# Thang Le
# MIPS 1 Part 1
# Adv Processors 4612

.data 
	buffer: .space 64
	prompt: .asciiz "Enter a string: "
.text 

main: 
	# allocate memory for array 
	li $v0, 9
	la $a0, 32			# allocate memory for 1 word
	syscall
	
	add $s1, $zero, $v0 		# set the array address to $s1		
	

	# user input prompt
	li $v0, 4
	la $a0, prompt
	syscall

	jal readString

	# storing memory
	sw $a0, 0($s1) 			# storing string from array at address $s1 to $a0 
	add $s2, $zero, $s1		# copy address of $s1 to $s2
	lw $a0, 0($s2) 			# load string from address $s2 to $a0
	

	#printing output
	li $v0, 4
	syscall
	
	# end procedure
	li $v0, 10
	syscall

readString: 
	# getting user input
	li $v0, 8
	la $a0, buffer
	la $a1, buffer 
	syscall

	jr $ra
