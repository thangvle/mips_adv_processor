.data 
	buffer: .space 64
	prompt: .asciiz "Enter a string: "
.text 

main: 
	li $v0, 9
	la $a0, 4
	syscall
	
	add $s1, $zero, $v0 
	add $s3, $zero, $s1

	# user input
	li $v0, 4
	la $a0, prompt
	syscall

	jal readString

	# storing memory
	sw $a0, 0($s1) 
	add $s3, $zero, $s1
	lw $a0, 0($s3) 
	

	#printing output
	li $v0, 4
	syscall
	

readString: 
	li $v0, 8
	la $a0, buffer
	la $a1, buffer 
	syscall

	jr $ra
