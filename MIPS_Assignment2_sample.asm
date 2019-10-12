.data
prompt: .asciiz "\n>> " # Prompt the user
userInput: .space 64 # Allocate the necessary space in memory for the user input
allowedCharacters: " ()0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-*/=" # Create the list of allowed characters to check against
alphaNumb: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
numbers: "0123456789"
ERROR: .asciiz "\nInvalid input\n" # Show this when an invalid character is caught
NOERROR: .asciiz "\nValid input\n" # Show this when all the characters in the user's input have been checked and are all valid
substring: .space 64
operatorAddresses: .space 64
orderOfOperationsBuffer: .space 64
intToString: .space 64
expressionLiteral: .space 64
visitedNumbers: .space 64
sortedOperatorAddresses: .space 64
.text 
main:
	la $a0, prompt # loading the prompt to display it to the IO window
	li $v0, 4 # system call code to print a string to the IO window
	syscall # excutues the pervious commands
	la $a0, userInput # loading adress of user input
	la $a1, userInput #loading the size of the userinput
	li $v0, 8  # system call to read string input
	syscall # excutues the pervious commands
	move $t0, $a0 # moving the adress of the user input to a temp location
	la $t0, userInput #moving the address of the user input into a better register
	la $t1, allowedCharacters #moving the address of the allowedcharacters to a better register
	j checkValidity #loop that checks if the user input is valid
main2:
	jal cleanAllRegistersAndBuffers
	la $t0, userInput
	jal parenthesesSearch
	beq $t2, $zero, noParenthesesAtAll
noParenthesesAtAllReturn:
	li $s3, 0
	j substringCreator
substringCreatorReturn:
	move $s1, $t2
	la $s0, substring
	j operatorSearch
operatorSearchReturn:
	la $t0, substring
	move $t4, $t0
	add $t4, $t4, $s5
	beqz $s3, numberEvaluation
	bnez $s3, orderOfOperations
orderOfOperationsReturn:
	jal cleanTempRegisters
	j expressionLiteralCreator
	#beqz $s3, numberToASCII was where old numberEvaluationReturn was
numberToASCIIReturn:
	
	#############################
	#la $a0, intToString
	#li $v0, 4
	#syscall		    	Only use this if you want to see how it works without operations
	#jal cleanAllRegistersAndBuffers
	#j main
	#############################
	
####################################################################################
expressionLiteralCreator:
	# Establishing buffers to work with
	la $t0, orderOfOperationsBuffer
	la $t1, operatorAddresses
	la $t2, visitedNumbers
	la $t7, sortedOperatorAddresses
	li $t3, 1 # Rank to look for
expressionLiteralMain:
	lb $t4, ($t0) # Loading each rank, seeing if it mataches with rank we're looking for
	beqz $t4, literalProgressPoint1
	beq $t4, $t3, foundRankOperator
	addi $t5, $t5, 1 # Represents number of hops to access certain operator
	addi $t0, $t0, 1
	j expressionLiteralMain
foundRankOperator:
	mul $t5, $t5, 4 # Because words not bytes
	add $t1, $t1, $t5 # Make the hop
	lw $t6, ($t1) # Grab address
	sw $t6, ($t7) # Store address
	li $t5, 0
	addi $t3, $t3, 1 #Look for next rank
	addi $t0, $t0, 1
	addi $t7, $t7, 4
	la $t1, operatorAddresses
	la $t0, orderOfOperationsBuffer
	j expressionLiteralMain
literalProgressPoint1:
	jal cleanTempRegisters
	la $t2, visitedNumbers
boundDecision: # Section is meant to decide between looking for left and right bounds, based on whether it has been found
	la $t0, sortedOperatorAddresses
	bnez $s6, boundException
	j exceptionSkip
boundException:
	move $t0, $s6 # Exception made for whether this is the first time or second time
exceptionSkip:
	la $t1, operatorAddresses
	beqz $t7, findLeftBound # t7 holds left bound, so if empty then left bound not found yet
	sub $s3, $s3, 1
	mul $s3, $s3, 4
	add $t1, $t1, $s3 # This whole process is to jump to end of operatorAddresses, so that it can be moved through in reverse
	div $s3, $s3, 4
	addi $s3, $s3 1
	beqz $t8, findRightBound # t8 holds right bound, so if empty then right bound not found yet
	j storeNumbersAndOperators
findLeftBound:
# The process works by starting from the beginning of operatorAddresses, which is sorted by order of finding operators, and 
# incrementing through the range, looking for what is larger than the target address (which could be in the middle). Once larger
# value is found, two steps are taken back to move from the large value and from value itself.
	lw $t3, ($t0)
	lw $t4, ($t1)
	beqz $t4, foundLeft 
	bgt $t6, $s3, foundLeft
	sgt $t5, $t4, $t3
	bnez $t5, foundLeft
	addi $t1, $t1, 4
	addi $t6, $t6, 1 # Counter of hops
	j findLeftBound
foundLeft:
	li $t5, 0
	sub $t6, $t6, 2
	beq $t6, -1, foundLeftException # Exception here being when the left bound is the beginning of the substring
	mul $t6, $t6, 4
	la $t1, operatorAddresses
	add $t1, $t1, $t6
	lw $t7, ($t1)
	sw $t7, ($t2)
	addi $t2, $t2, 4
	addi $t7, $t7, 1
	li $t6, 0
	addi $t9, $t9, 1
	j boundDecision
foundLeftException:
	move $t7, $s0
	li $t6, 0
	addi $t9, $t9, 1
	j boundDecision
findRightBound:
# Similar to how left bound is found, but the inverse. The process starts from the top of the range and moves down, searching
# for a smaller value then taking two steps back to determine right bound.
	lw $t3, ($t0)
	lw $t4, ($t1)
	beqz $t4, foundRight
	slt $t5, $t4, $t3
	bnez $t5, foundRight
	subi $t1, $t1, 4
	addi $t6, $t6, 1
	j findRightBound
foundRight:
	li $t5, 0
	subi $t6, $t6, 2
	beq $t6, -1, foundRightException
	la $t1, operatorAddresses
	sub $s3, $s3, 1
	mul $s3, $s3, 4
	add $t1, $t1, $s3
	div $s3, $s3, 4
	addi $s3, $s3 1
	lw $t8, ($t1)
	mul $t6, $t6, 4
	sub $t8, $t8, $t6
	sw $t8, ($t2)
	addi $t2, $t2, 4
	li $t6, 0
	addi $t9, $t9, 1
	j boundDecision
foundRightException: # For when the end of the range is the substring end @
	move $t8, $s1
	li $t6, 0
	j boundDecision
storeNumbersAndOperators:
	move $s6, $t0
	move $t0, $t7
	subi $t9, $t9, 1
	mul $t9, $t9, 4
	la $t3, sortedOperatorAddresses
	add $t3, $t3, $t9
	lw $t4, ($t3)
	jal numberEvaluation
	la $t2, expressionLiteral
	sb $s4, ($t2)
	addi $t2, $t2, 1
	lb $t1, ($t4)
	sb $t1, ($t2)
	addi $t2, $t2, 1
	addi $t4, $t4, 1
	move $t0, $t4
	move $t4, $t8
	move $t6, $t2
	jal numberEvaluation
	sb $s4, ($t6)
	addi $t6, $t6, 1
	addi $s6, $s6, 4
	j literalProgressPoint1
####################################################################################
cleanTempRegisters: # Cleans all temporary registers so that it's easier to work other functions
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	jr $ra
####################################################################################
cleanAllRegistersAndBuffers: # Cleans all registers and buffers for the restart of the programs 
clearRegisters:
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	li $s5, 0
	li $s6, 0
	li $s7, 0
nextOne: # Running through the order of buffers to clean
	beqz $t3, intToStringClear
	beqz $t4, orderOfOperationsClear
	beqz $t5, operatorAddressesClear
	beqz $t6, substringClear
	beqz $t7, expressionLiteralClear
	beqz $t8, visitedNumbersClear
	beqz $t9, sortedOperatorAddressesClear
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	jr $ra
intToStringClear:
	li $t3, 1 # Each buffer has its own register to mark for cleaning, to check if the cleaning has been accomplished
	la $t1, intToString # t1 represents the address of the buffer to clean for each clean
	li $t2, 4 # t2 represents how many times to go through the address to clear all bytes, depending on potential size
	j clearBuffer
orderOfOperationsClear:
	li $t4, 1
	la $t1, orderOfOperationsBuffer
	li $t2, 4
	j clearBuffer
operatorAddressesClear:
	li $t5, 1
	la $t1, operatorAddresses
	li $t2, 16
	j clearBuffer
substringClear:
	li $t6, 1
	la $t1, substring
	li $t2, 64
	j clearBuffer
expressionLiteralClear:
	li $t7, 1
	la $t1, expressionLiteral
	li $t2, 24
	j clearBuffer
visitedNumbersClear:
	li $t8, 1
	la $t1, visitedNumbers
	li $t2, 40
	j clearBuffer
sortedOperatorAddressesClear:
	li $t9, 1
	la $t1, sortedOperatorAddresses
	li $t2, 16
	j clearBuffer
clearBuffer:
	beqz $t2, nextOne
	sb $t0, ($t1)
	addi $t1, $t1, 1
	sub $t2, $t2, 1
	j clearBuffer
####################################################################################
# This function allows for the conversion from a true value (value in register) to ASCII value (e.g., 13 to "13" as two separate
# characters)
numberToASCII: # Clearing necessary registers in use here
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	la $t0, intToString # Loading buffer where ASCII conversion is stored
numberToASCIIStrip:
	beqz $s4, numberToASCIIStore # Loop terminating conditon meaning once the full number has been chunked up
	addi $t6, $t6, 1 # Looking at number of registers to split the number up into, based on # of digits
	div $s4, $s4, 10 # Divide by ten to grab rightmost digit, leaving leftover in same register
	mfhi $t1 # Hi stores the remainder, which is that rightmost digit, so move it to t1 for temp holding
	addi $t1, $t1, 0x30 # Convert to ASCII equivalent
	beqz $t2, putIn$t2 # Label explains it
	beqz $t3, putIn$t3
	beqz $t4, putIn$t4
	beqz $t5, putIn$t5
putIn$t2:
	move $t2, $t1
	j numberToASCIIStrip
putIn$t3:
	move $t3, $t1
	j numberToASCIIStrip
putIn$t4:
	move $t4, $t1
	j numberToASCIIStrip
putIn$t5:
	move $t5, $t1
	j numberToASCIIStrip
numberToASCIIStore:
	beq $t6, 1, oneReg
	beq $t6, 2, twoReg
	beq $t6, 3, threeReg
	beq $t6, 4, fourReg
# Each sections accounts for whether the chunking resulted in 1 - 4 digits, and stores to buffer accordingly
oneReg:
	sb $t2, ($t0)
	j numberToASCIIReturn
twoReg:
	sb $t3, ($t0)
	addi $t0, $t0, 1
	sb $t2, ($t0)
	j numberToASCIIReturn
threeReg:
	sb $t4, ($t0)
	addi $t0, $t0, 1
	sb $t3, ($t0)
	addi $t0, $t0, 1
	sb $t2, ($t0)
	j numberToASCIIReturn
fourReg:
	sb $t5, ($t0)
	addi $t0, $t0, 1
	sb $t4, ($t0)
	addi $t0, $t0, 1
	sb $t3, ($t0)
	addi $t0, $t0, 1
	sb $t2, ($t0)
	j numberToASCIIReturn
####################################################################################
# Opposite of numberToASCII, where the ASCII value entered (such as '13', two characters of 1 & 3) is converted to true
# integer value (13 in a register)
numberEvaluationReturn:
	li $t5, 0
	jr $ra # Allows for calling as a normal function
numberEvaluation:
	la $t1, numbers # Load buffer of all 10 digits to check against
numberEvaluationDigitCheck:
	lb $t2, ($t0) # t0 is beginning address, loaded before the function
	lb $t3, ($t1) # Load a number from the # list to compare against
	beq $t0, $t4, numberEvaluationIntConversion # t4 end address
	beq $t2, $t3, foundANumber
	bne $t2, $t3, notANumberYet
foundANumber:
	addi $t5, $t5, 1 # t5 tracks digits
	addi $t0, $t0, 1 # Move onto next byte of selected section
	la $t1, numbers # Move back to beginning of numbers list
	j numberEvaluationDigitCheck
notANumberYet:
	addi $t1, $t1, 1 # Move onto next number on the list to check against
	j numberEvaluationDigitCheck
numberEvaluationIntConversion:
	# As the label names imply, this is chunked into the number of digits found and multiplies accordingly
	beq $t5, 1, oneDigit
	beq $t5, 2, twoDigit
	beq $t5, 3, threeDigit
	beq $t5, 4, fourDigit
oneDigit:
	addi $t0, $t0, -1 # This is to jump back to position of actual digit, as t0 is still being used in the same function
	lb $t1, ($t0)
	andi $s4, $t1, 0x0F # This mask allows for conversion from ASCII to actual integer
	j numberEvaluationReturn
twoDigit:
	addi $t0, $t0, -2
	lb $t1, ($t0)
	andi $s4, $t1, 0x0F
	mul $s4, $s4, 10 # Tens place, so x10
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	add $s4, $s4, $t1 
	j numberEvaluationReturn
threeDigit:
	addi $t0, $t0, -3
	lb $t1, ($t0)
	andi $s4, $t1, 0x0F
	mul $s4, $s4, 100 # Hundreds, so x100
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	mul $t1, $t1, 10
	add $s4, $s4, $t1
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	add $s4, $s4, $t1
	j numberEvaluationReturn
fourDigit:
	addi $t0, $t0, -4
	lb $t1, ($t0)
	andi $s4, $t1, 0x0F
	mul $s4, $s4, 1000 # Thousands, so x1000
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	mul $t1, $t1, 100
	add $s4, $s4, $t1
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	mul $t1, $t1, 10
	add $s4, $s4, $t1
	addi $t0, $t0, 1
	lb $t1, ($t0)
	andi $t1, $t1, 0x0F
	add $s4, $s4, $t1
	j numberEvaluationReturn
####################################################################################
# This section/function allows for determination of actual order of operations by taking the found operators and ranking
onlyOneOperator: # Exceptional case to make things easier, if there's only one operator no need to search for max and dupes,
		 # just declare the sole operator as the 1st operator
	lb $t4, ($t3)
	li $t4, 1
	j orderOfOperationsReturn
orderOfOperations:
	la $t0, operatorAddresses # Loading the locations of all the operators found in a substring
	la $t3, orderOfOperationsBuffer # Loading the buffer to store all the ranks of the operators, where the location of the 
					# rank says what operator it is (e.g., 3 1 2 means that the first operator found should be
					# be evaluated third, the second operator found should be evaluated first, third operator 
					# found should be evaluated second). 
orderOfOperationsMain:
	lw $t1, ($t0)
	li $t2, 0
	beqz $t1, cleanOrderBuffer
	lb $t2, ($t1) 
	beq $s3, 1, onlyOneOperator
	beq $t2, 42, orderOfOperationsMultiplier # As each label implies, checking for each type of alegbraic operator
	beq $t2, 47, orderOfOperationsDivider
	beq $t2, 43, orderOfOperationsAdder
	beq $t2, 45, orderOfOperationsSubtracter
	addi $t0, $t0, 4 # Adding 4 because addresses take a word, need to move by words
	j orderOfOperationsMain
orderOfOperationsMultiplier: # t4 in each section represents the rank of the multiplier based on PEMDAS
	li $t4, 1
	sb $t4, ($t3) # Store the rank into the buffer that holds ranks
	addi $t0, $t0, 4
	addi $t3, $t3, 1
	j orderOfOperationsMain
orderOfOperationsDivider:
	li $t4, 2
	sb $t4, ($t3)
	addi $t0, $t0, 4
	addi $t3, $t3, 1
	j orderOfOperationsMain
orderOfOperationsAdder:
	li $t4, 3
	sb $t4, ($t3)
	addi $t0, $t0, 4
	addi $t3, $t3, 1
	j orderOfOperationsMain
orderOfOperationsSubtracter:
	li $t4, 4
	sb $t4, ($t3)
	addi $t0, $t0, 4
	addi $t3, $t3, 1
	j orderOfOperationsMain
# This sections of cleaning the order buffer has two steps: cleaning based on maximum value found, and cleaning based on duplicates.
# If the max is > the actual amount of operators, decrease the rank of all operators (bar 1 so no 0 is made) to accommodate. Then
# Start looking for duplicate values, because of there are two twos, then whatever comes last is now a higher rank (so if there is
# a + then +, this is done left to right normally, meaning the first + is done before second +.). Repeat these cleaning processes
# until there are no duplicates and there are no maximums that exceed actual # of operators.
cleanOrderBuffer:
	la $t0, orderOfOperationsBuffer
	li $t4, 0 # This checks whether a new max was calculated
	li $t5, 0 # This checks wheter a duplicate was found
cleanOrderBufferSizeCheck:
	lb $t1, ($t0)
	beqz $t1, cleanOrderBufferSizeReadjustment
	slt  $t3, $t2, $t1
	beq $t3, 1, newMaximum
	addi $t0, $t0, 1
	j cleanOrderBufferSizeCheck
newMaximum:
	move $t2, $t1
	addi $t0, $t0, 1
	j cleanOrderBufferSizeCheck
cleanOrderBufferSizeReadjustment:
	sle $t3, $t2, $s3
	bnez $t3, cleanOrderBufferDuplicateSearch
	la $t0, orderOfOperationsBuffer
	li $t4, 1
cleanOrderBufferSizeReadjustmentMain: # Once improper max is found, decrementing the values (except 1)
	lb $t1, ($t0)
	beqz $t1, cleanOrderBufferDuplicateSearch
	beq $t1, 1, cleanOrderBufferSizeReadjustmentSkip
	addi $t1, $t1, -1
	sb $t1, ($t0)
cleanOrderBufferSizeReadjustmentSkip:
	addi $t0, $t0, 1
	j cleanOrderBufferSizeReadjustmentMain
cleanOrderBufferDuplicateSearch:
	la $t0, orderOfOperationsBuffer
cleanOrderBufferDuplicateSearchMain:
	lb $t1, ($t0)
	addi $t0, $t0, 1
	lb $t2, ($t0)
	beqz $t2, cleanOrderBufferIntermediate
	beq $t1, $t2, duplicateFound
	j cleanOrderBufferDuplicateSearchMain
duplicateFound:
	li $t5, 1
	addi $t2, $t2, 1
	sb $t2, ($t0)
	addi $t0, $t0, 1
	j cleanOrderBufferDuplicateSearchMain	
cleanOrderBufferIntermediate:
	bnez $t4, cleanOrderBuffer # If new max was found, do clean again
	bnez $t5, cleanOrderBuffer # If dupe was found, do clean again
	j orderOfOperationsReturn # Reached only if there were no issues found after whole run
####################################################################################
operatorSearch:
	la $t0, substring
	la $t2, operatorAddresses
operatorSearchMain:
	lb $t1, ($t0)
	beq $t1, 42, operatorTrack
	beq $t1, 47, operatorTrack
	beq $t1, 43, operatorTrack
	beq $t1, 45, operatorTrack
	beq $t1, $zero, operatorSearchReturn
	addi $t0, $t0, 1
	j operatorSearchMain
operatorTrack:
	addi $s2, $s2, 1
	addi $s3, $s3, 1
	sw $t0, ($t2)
	addi $t2, $t2, 4
	addi $t0, $t0, 1
	j operatorSearchMain
####################################################################################
substringCreator:
	la $t2, substring
	move $t0, $s0
substringCreatorMain:
	lb $t1, ($t0)
	bne $t1, 40, noParenthesesSkip
noSkip:
	addi $t0, $t0, 1
noParenthesesSkip:
	lb $t1, ($t0)
	beq $t0, $s1, substringCreatorReturn
	beq $t1, 32, noSkip
	sb $t1, ($t2)
	addi $s5, $s5, 1
substringCreatorException:
	addi $t2, $t2, 1
	j noSkip
####################################################################################
noParenthesesAtAll:
	la $s0, userInput
	j noParenthesesAtAllReturn
parenthesesSearch:
	lb $t1, ($t0)
	beq $t1, 40, foundParenthesis
	beq $t1, 41, stopSearch
	beq $t1, 0xa, stopSearch
	addi $t0, $t0, 1
	j parenthesesSearch
foundParenthesis:
	li $t2, 1
	la $s0, ($t0)
	addi $t0, $t0, 1
	j parenthesesSearch
stopSearch:
	la $s1, ($t0)
	jr $ra
####################################################################################
checkValidity:
	lb $t2, ($t0) #load a character from the userinput
	lb $t3, ($t1) #loading a character from the allowedcharacters list
	beq $t4, -1, invalid # Checking for inbalance of parenthesis. If -1, that means too many right parenthesis
	beq $t2, 10, fullValid #when you see the "\n" (a in hex, 10 in decimal) that means it is the end of the user's string.
	beq $t3, $zero, invalid # if the loaded value is 0, we know we are at the end of list
	beq $t2, 40, leftParenthesisTracker # As the name implies, checks for "("
	beq $t2, 41, rightParenthesisTracker # As the name implies, checks for ")"
	beq $t2, 42, operatorTracker # Checking for "*"
	beq $t2, 43, operatorTracker # Checking for "+"
	beq $t2, 45, operatorTracker # Checking for "-"
	beq $t2, 47, operatorTracker # Checking for "/"
	beq $t2, $t3, validCharacter  # checking to see if a charcter from user input is equal to one of the allowed characters
	bne $t2, $t3, notValidYet # if the two characters are not equal
leftParenthesisTracker:
	addi $t4, $t4, 1 # $t4 is the register that will track the proper amount of parenthesis. If left, +1, if right, -1
	addi $t0, $t0, 1 # Stepping $t0 forward to look at character ahead of the parenthesis
	j operatorCheck
operatorTracker:
	addi $t0, $t0, 1 # Looking at character ahead
	j operatorCheck
rightParenthesisTracker:
	addi $t0, $t0, 1 # First we look ahead of right parenthesis
	lb $t2, ($t0) # loading that next character into $t2
	la $s0, alphaNumb # loading the address of alphaNumb into $s0
	back2: # This allows for a loop that moves through the alphaNumb list to check
	lb $s1, ($s0) # Loading the character from the alphaNumb list
	beq $s1, $zero, skip # If the end of the alphaNumb list has been reached, stop searching and comparing
	beq $t2, $s1, invalid # If the next character is an alphanumerical character, then the input is invalid
	bne $t2, $s1, nextAlpha # Move to next character in alphaNumb list to compare against
	skip: 
	addi $t4, $t4, -1 # -1 for a right parenthesis in the parenthesis tracking register, $t4
	addi $t0, $t0, -2 # Stepping back to the character behind the right parenthesis to check for operators
	addi $t6, $zero, 1 # Setting a temp. flag that was found to be necessary because of the structure of the program
	lb $t2, ($t0) # Actually load the character behind the parenthesis to see if the right parenthesis is the first character of the user input
	beq $t2, $zero, invalid # If it is the first character, then input is invalid
	j operatorCheck
nextAlpha:
	addi $s0, $s0, 1 # Shifting $s0 to access that next character
	j back2
operatorCheck: # Whole section is for checking if "*" or "/" comes before/after an operator or parenthesis
	lb $t2, ($t0) # Loading that next character to check
	li $t5, 42 # Checking for "*"
	beq $t2, $t5, invalid
	li $t5, 47 # Checking for "/"
	beq $t2, $t5, invalid
	beq $t6, 1, rightFix # If current character (not next character) is ")", then apply fix
	j checkValidity # Move on to check validity of the rest of the user string
rightFix:
	addi $t0, $t0, 2 # Step forward to character after right parenthesis, as that is what occurs for the other cases
	addi $t6, $zero, 0 # Clear the flag
	j checkValidity # Move on to check validity of the rest of the user string
validCharacter:
	addi $t0, $t0, 1 #move on to the next character in the allowed characters list
	la $t1, allowedCharacters #bringing it back to the beginning of the allowed characters list to begin the search again
	j checkValidity  #jump back to look for see if there is a match
notValidYet: 
	addi $t1, $t1, 1 #move on to the next character in the allowed characters list
	j checkValidity # jump back to look for see if there is a match
fullValid:
	sge $t2, $t4, 1
	beq $t2, 1, invalid
	add $t4, $zero, $zero
	j main2 # repeat the program 
invalid:
	la $a0, ERROR #loading the prompt to display it to the IO window
	li $v0, 4 # system call code to print a string to the IO window
	syscall ## excutues the pervious commands
	add $t4, $zero, $zero # Resetting parenthesis counter
	j main # repeat the program 
