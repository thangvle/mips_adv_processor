.data
    .align 2
array:      .space  80
size:       .word   20

string:     .space  64       # [NEW]
op:         .asciiz "Enter the array length:"
prompt:     .asciiz "Enter a string:"
text:       .asciiz "The array of string is:"
newline:    .asciiz "\n"

    .text
    .globl main
main:
    # prompt user for array length
    li      $v0,4
    la      $a0,op
    syscall
    jal     new_line            # output newline

    # read in array count
    li      $v0,5
    syscall
    addi    $s0,$v0,0           # keep $v0 at 5

    add     $t0,$zero,$zero     # index of array
    addi    $t1,$zero,1         # counter=1
    la      $s2,string          # load address of string storage area [NEW]

read_string:
    bgt     $t1,$s0,L1          # if ($t1 > length) then array is done -- fly

    # prompt the user for next "string"
    li      $v0,4
    la      $a0,prompt
    syscall


    move    $a0,$s2             # place to store string 
    li      $a1,20
    li      $v0,8
    syscall

    # store pointer to string into array
    sw      $a0,array($t0)

    addi    $t0,$t0,4           # advance offset into pointer array
    addi    $t1,$t1,1           # advance iteration count
    addi    $s2,$s2,20          # advance to next string area [NEW]

    j       read_string

# printing array 
L1:
    add     $t0,$zero,$zero     # index of array
    addi    $t1,$zero,1         # counter = 1

    # output the title
    la      $a0,text
    li      $v0,4
    syscall
    jal     new_line

while:
    bgt     $t1,$s0,done        # more strings to output?  if no, fly
    lw      $t2,array($t0)      # get pointer to string

    # output the string
    li      $v0,4
    move    $a0,$t2
    syscall
    jal     new_line

    addi    $t0,$t0,4           # advance array index
    addi    $t1,$t1,1           # advance count
    j       while

# new_line 
new_line:
    la      $a0,newline
    li      $v0,4
    syscall
    jr      $ra

# program is done
done:
    li      $v0,10
    syscall