.data 
	array: .space 80
	string: .space 64
	prompt: .asciiz "\nEnter a string: \n"
	output: .asciiz "String: "
.text 

main: 
	# prompt user
	li $v0, 4
	la $a0, prompt
	syscall
	
	# read and store string
	li $v0, 8
	la $a1, string
	la $a0, string 
	
	
	syscall 

	sw      $a0,array($t0)

   	addi    $t0,$t0,4           # advance offset into pointer array
    	addi    $t1,$t1,1           # advance iteration count
    	addi    $s2,$s2,20          # advance to next string area [NEW]

L1:
    add     $t0,$zero,$zero     # index of array
    addi    $t1,$zero,1         # counter = 1

    # output the title
    la      $a0,output
    li      $v0,4
    syscall
   

while:
    bgt     $t1,$s0,done        # more strings to output?  if no, fly
    lw      $t2,array($t0)      # get pointer to string

    # output the string
    li      $v0,4
    move    $a0,$t2
    syscall
    

    addi    $t0,$t0,4           # advance array index
    addi    $t1,$t1,1           # advance count
    j       while

done: 
	li      $v0,10
    	syscall