.data 
	prompt: .asciiz "\nEnter number for factorial: \n"
	ans: .asciiz "Result: "
	
	
.text

main: 
	# printing prompt
	li $v0, 4
	la $a0, prompt
	syscall
	
	# getting input from user 
	li $v0, 5
	
	syscall
	
	# store input to $t0
	move $t0, $v0 
	
	li $t1, 1		# store $t1 as 1 for multiplication 
	jal factorial
	
	# ending program procedure
	li $v0, 10
	syscall
	
factorial: 
	mul $t1, $t1, $t0 	# store product of $t0 and $t1 in $t1
	sub $t0, $t0, 1		# decrease $t0 by 1
	bnez $t0, factorial 	# check if $t0 reach 0, if not, repeat multiplication
	j print			# if $t0 == 0, jump to print
	
	# return to caller
	jr $ra
	
print: 

	# copy value from $t1 (product) to $a0 for displaying argument
	li $v0, 1
	move $a0, $t1
	syscall
	
	# print ans 
	li $v0, 4
	la $a0, ans
	syscall
	
	# return to caller
	jr $ra 
