### Text segment
		.text
start:
		la		$a0, matrix_24x24		# a0 = A (base address of matrix)
		li		$a1, 24    		    # a1 = N (number of elements per row)
									# <debug>
#		jal 	print_matrix	    # print matrix before elimination
#		nop							# </debug>
		jal 	gaussalize			# triangularize matrix!
		nop							# <debug>
#	  jal 	print_matrix		# print matrix after elimination
#		nop							# </debug>
		jal 	exit
exit:
		li   	$v0, 10          	# specify exit system call
      	syscall						# exit program

################################################################################
# eliminate - Triangularize matrix.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)

eliminate:
		# If necessary, create stack frame, and save return address from ra
		addiu	$sp, $sp, -4		# allocate stack frame
		sw		$ra, 0($sp)			# done saving registers
		
    jal gaussalize
    nop
		lw		$ra, 0($sp)			# done restoring registers
		addiu	$sp, $sp, 4			# remove stack frame

		jr		$ra					# return from subroutine
		nop							# this is the delay slot associated with all types of jumps

################################################################################
# getelem - Get address and content of matrix element A[a][b].
#
# Argument registers $a0..$a3 are preserved across calls
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)
#			$a2  - row number (a)
#			$a3  - column number (b)
#						
# Returns:	$v0  - Address to A[a][b]
#			$f0  - Contents of A[a][b] (single precision)
getelem:
		addiu	$sp, $sp, -12		# allocate stack frame
		sw		$s2, 8($sp)
		sw		$s1, 4($sp)
		sw		$s0, 0($sp)			# done saving registers
		
		sll		$s2, $a1, 2			# s2 = 4*N (number of bytes per row)
		multu	$a2, $s2			# result will be 32-bit unless the matrix is huge
		mflo	$s1					# s1 = a*s2
		addu	$s1, $s1, $a0		# Now s1 contains address to row a
		sll		$s0, $a3, 2			# s0 = 4*b (byte offset of column b)
		addu	$v0, $s1, $s0		# Now we have address to A[a][b] in v0...
		l.s		$f0, 0($v0)		    # ... and contents of A[a][b] in f0.
		
		lw		$s2, 8($sp)
		lw		$s1, 4($sp)
		lw		$s0, 0($sp)			# done restoring registers
		addiu	$sp, $sp, 12		# remove stack frame
		
		jr		$ra					# return from subroutine
		nop							# this is the delay slot associated with all types of jumps

################################################################################
# print_matrix
#
# This routine is for debugging purposes only. 
# Do not call this routine when timing your code!
#
# print_matrix uses floating point register $f12.
# the value of $f12 is _not_ preserved across calls.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N) 
print_matrix:
		addiu	$sp,  $sp, -20		# allocate stack frame
		sw		$ra,  16($sp)
		sw      $s2,  12($sp)
		sw		$s1,  8($sp)
		sw		$s0,  4($sp) 
		sw		$a0,  0($sp)		# done saving registers

		move	$s2,  $a0			# s2 = a0 (array pointer)
		move	$s1,  $zero			# s1 = 0  (row index)
loop_s1:
		move	$s0,  $zero			# s0 = 0  (column index)
loop_s0:
		l.s		$f12, 0($s2)        # $f12 = A[s1][s0]
		li		$v0,  2				# specify print float system call
 		syscall						# print A[s1][s0]
		la		$a0,  spaces
		li		$v0,  4				# specify print string system call
		syscall						# print spaces

		addiu	$s2,  $s2, 4		# increment pointer by 4

		addiu	$s0,  $s0, 1        # increment s0
		blt		$s0,  $a1, loop_s0  # loop while s0 < a1
		nop
		la		$a0,  newline
		syscall						# print newline
		addiu	$s1,  $s1, 1		# increment s1
		blt		$s1,  $a1, loop_s1  # loop while s1 < a1
		nop
		la		$a0,  newline
		syscall						# print newline

		lw		$ra,  16($sp)
		lw		$s2,  12($sp)
		lw		$s1,  8($sp)
		lw		$s0,  4($sp)
		lw		$a0,  0($sp)		# done restoring registers
		addiu	$sp,  $sp, 20		# remove stack frame

		jr		$ra					# return from subroutine
		nop							# this is the delay slot associated with all types of jumps
		
#################### OUR CODE

# Gauss elimination
# t0 <= i
# t1 <= j
# t2 <= k
# t3 <= A
# t4 <= N - 1
# t5 <= N
# f1 <= 1
# s1 <= adress till konstanter
# s2 <= adress till A[k][k]

gaussalize:
      
      addiu $sp, $sp, -20
      sw    $ra, ($sp) 
      sw    $a0, 4($sp)
      sw    $a1, 8($sp)
      sw    $s1, 12($sp)
      sw    $s2, 16($sp)
      
      
      
      add   $t2, $zero, $zero   # k = 0
      add   $t3, $a0, $zero     # t3 <= A
      addi  $t4, $a1, -1        # t4 <= N - 1
      addi  $t5, $a1, 0         # t5 <= N
      la    $s1, zero
      lwc1  $f0, zero           # f0 <= 0.0
      lwc1  $f1, one            # f1 <= 1.0

outer1:
      beq   $t2, $t5, outer1_done # k < N ?
      # redan här borde vi kunna spara ner adressen till A[k][k]
      move  $a0, $t2            # a0 <= k
      jal   fetchaddress        # jump to fetchaddress and save position to $ra
      move  $a1, $t2            # a1 <= k DELAYSLOT
      move  $s2, $v0            # s2 <= adress till A[k][k]
      
      addi  $t1, $t2, 1       # j = k + 1
inner1:
      beq   $t1, $t5, inner1_done   # if t1 == $t5 then j == N, goto inner1_done
      nop
      
      # A[k][j] = A[k][j] / A[k][k]
      move  $a0, $t2           # a0 <= k
      jal   fetchaddress
      move  $a1, $t1           # a1 <= j DELAYSLOT
      
      lwc1  $f2, ($v0)        # f2 <= A[k][j]
      move  $t7, $v0          # sparar adressen till A[k][j]
      
      # läser in A[k][k]
#      move  $a1, $t2          # a1 <= k (a0 oförändrad!)
#      jal   fetchaddress
#      nop
#      lwc1  $f3, ($v0)        # f3 <= A[k][k]
      
      lwc1  $f3, ($s2)
        
      # f2 / f3
      div.s $f4, $f2, $f3
      swc1  $f4, ($t7)        # A[k][j] <= f2 / f3
      
      j inner1


inner1_done:
middle:
# A[k][k] = 1.0

#     Här kan vi använda adressen till A[k][k] som vi sparade undan tidigare

#      move  $a0, $t2          # a0 <= k
#      move  $a1, $t2          # a1 <= k
#      jal   fetchaddress      # v0 <= adressen till A[k][k]
#      nop
#      swc1  $f1, ($v0)       # (v0) <= 1.0

      swc1  $f1, ($s2)
      
# new loops

      addiu  $t0, $t2, 1     # i = k + 1      
inner2:
      beq    $t0, $t5, inner2_done  # i < N ?
      addiu  $t1, $t2, 1     # j = k + 1
inner3:
      beq   $t1, $t5, inner3_done  # j < N?
      # <---- begin float arithmetics ---->
      
      # A[i][j] = A[i][j] - A[i][k] * A[k][j]
      move  $a0, $t0        # a0 <= i
      jal   fetchaddress
      move  $a1, $t1        # a1 <= j DELAYSLOT
      lwc1  $f4, ($v0)      # f4 <= A[i][j]
      move  $t6, $v0        # t6 <= adress till A[i][j]
      
      # f6 <= A[k][j]
      move  $a0, $t2
      jal   fetchaddress
      move  $a1, $t1 # DELAYSLOT
      lwc1  $f6, ($v0)      # f6 <= A[k][j]
      
      # f2 <= A[i][k]
      move $a0, $t0
      jal fetchaddress
      move $a1, $t2 # DELAYSLOT
      lwc1 $f2, ($v0)
      
      #######
      # Vi borde kunna spara ner adressen till A[i][k] till register redan här
      # och använda när vi går till inner3_done
      #######
      
      # f3 <= A[i][k] * A[k][j]
      mul.s $f3, $f2, $f6
      
      # f5 <= A[i][j] - f3
      sub.s $f5, $f4, $f3
      
      # A[i][j] <= f5
      swc1  $f5, ($t6)
      
      # <---- end float arithmetics ---->
      
      addiu  $t1, $t1, 1       # j++
      j inner3
      nop
      
inner3_done:
# A[i][k] = 0.0
      move  $a0, $t0
      jal   fetchaddress        # jump to fetchaddress and save position to $ra
      move  $a1, $t2 # DELAYSLOT
      swc1  $f0, ($v0)

      addiu  $t0, $t0, 1       # i++
      j inner2
      nop
      
# End of outer for-loop
inner2_done:
      addiu  $t2, $t2, 1       # k++
      
      j     outer1
      nop
outer1_done:
# Restore shit from stack
      lw    $ra, 0($sp)
      lw    $a0, 4($sp)
      lw    $a1, 8($sp)
      lw    $s1, 12($sp)   # 
      
      
      addiu $sp, $sp, 16
      
      jr    $ra         # jump to $ra
      nop
      
      
##########################################################
# fetchaddress
# hämtar adressen till ett matriselement A[x][y]
# 
# args:
#   a0: row
#   a1: column
#   t5: N rader/kolumner i matrisen
#   t3: A - basadress till matrisen
##########################################################

fetchaddress:
      multu $a0, $t5          # a0 * N
      mflo  $v0               # v0 <= a0 * N
      addu  $v0, $v0, $a1     # v0 <= v0 + a1
      sll   $v0, $v0, 2       # v0 <= v0 * 4
      jr    $ra               # return
      addu  $v0, $v0, $t3     # v0 <= v0 + A DELAYSLOT

#################### END OUR CODE
### End of text segment

### Data segment 
		.data
		
### Constants

zero: 
    .float 0      
one:  
    .float 1.0

### String constants
spaces:
		.asciiz "   "   			# spaces to insert between numbers
newline:
		.asciiz "\n"  				# newline
		
message:
    .asciiz "HEIKON BACON"

## Input matrix: (4x4) ##
matrix_4x4:	
		.float 57.0
		.float 20.0
		.float 34.0
		.float 59.0
		
		.float 104.0
		.float 19.0
		.float 77.0
		.float 25.0
		
		.float 55.0
		.float 14.0
		.float 10.0
		.float 43.0
		
		.float 31.0
		.float 41.0
		.float 108.0
		.float 59.0
		
		# These make it easy to check if 
		# data outside the matrix is overwritten
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef

## Input matrix: (24x24) ##
matrix_24x24:
		.float	 92.00 
		.float	 43.00 
		.float	 86.00 
		.float	 87.00 
		.float	100.00 
		.float	 21.00 
		.float	 36.00 
		.float	 84.00 
		.float	 30.00 
		.float	 60.00 
		.float	 52.00 
		.float	 69.00 
		.float	 40.00 
		.float	 56.00 
		.float	104.00 
		.float	100.00 
		.float	 69.00 
		.float	 78.00 
		.float	 15.00 
		.float	 66.00 
		.float	  1.00 
		.float	 26.00 
		.float	 15.00 
		.float	 88.00 

		.float	 17.00 
		.float	 44.00 
		.float	 14.00 
		.float	 11.00 
		.float	109.00 
		.float	 24.00 
		.float	 56.00 
		.float	 92.00 
		.float	 67.00 
		.float	 32.00 
		.float	 70.00 
		.float	 57.00 
		.float	 54.00 
		.float	107.00 
		.float	 32.00 
		.float	 84.00 
		.float	 57.00 
		.float	 84.00 
		.float	 44.00 
		.float	 98.00 
		.float	 31.00 
		.float	 38.00 
		.float	 88.00 
		.float	101.00 

		.float	  7.00 
		.float	104.00 
		.float	 57.00 
		.float	  9.00 
		.float	 21.00 
		.float	 72.00 
		.float	 97.00 
		.float	 38.00 
		.float	  7.00 
		.float	  2.00 
		.float	 50.00 
		.float	  6.00 
		.float	 26.00 
		.float	106.00 
		.float	 99.00 
		.float	 93.00 
		.float	 29.00 
		.float	 59.00 
		.float	 41.00 
		.float	 83.00 
		.float	 56.00 
		.float	 73.00 
		.float	 58.00 
		.float	  4.00 

		.float	 48.00 
		.float	102.00 
		.float	102.00 
		.float	 79.00 
		.float	 31.00 
		.float	 81.00 
		.float	 70.00 
		.float	 38.00 
		.float	 75.00 
		.float	 18.00 
		.float	 48.00 
		.float	 96.00 
		.float	 91.00 
		.float	 36.00 
		.float	 25.00 
		.float	 98.00 
		.float	 38.00 
		.float	 75.00 
		.float	105.00 
		.float	 64.00 
		.float	 72.00 
		.float	 94.00 
		.float	 48.00 
		.float	101.00 

		.float	 43.00 
		.float	 89.00 
		.float	 75.00 
		.float	100.00 
		.float	 53.00 
		.float	 23.00 
		.float	104.00 
		.float	101.00 
		.float	 16.00 
		.float	 96.00 
		.float	 70.00 
		.float	 47.00 
		.float	 68.00 
		.float	 30.00 
		.float	 86.00 
		.float	 33.00 
		.float	 49.00 
		.float	 24.00 
		.float	 20.00 
		.float	 30.00 
		.float	 61.00 
		.float	 45.00 
		.float	 18.00 
		.float	 99.00 

		.float	 11.00 
		.float	 13.00 
		.float	 54.00 
		.float	 83.00 
		.float	108.00 
		.float	102.00 
		.float	 75.00 
		.float	 42.00 
		.float	 82.00 
		.float	 40.00 
		.float	 32.00 
		.float	 25.00 
		.float	 64.00 
		.float	 26.00 
		.float	 16.00 
		.float	 80.00 
		.float	 13.00 
		.float	 87.00 
		.float	 18.00 
		.float	 81.00 
		.float	  8.00 
		.float	104.00 
		.float	  5.00 
		.float	 57.00 

		.float	 19.00 
		.float	 26.00 
		.float	 87.00 
		.float	 80.00 
		.float	 72.00 
		.float	106.00 
		.float	 70.00 
		.float	 83.00 
		.float	 10.00 
		.float	 14.00 
		.float	 57.00 
		.float	  8.00 
		.float	  7.00 
		.float	 22.00 
		.float	 50.00 
		.float	 90.00 
		.float	 63.00 
		.float	 83.00 
		.float	  5.00 
		.float	 17.00 
		.float	109.00 
		.float	 22.00 
		.float	 97.00 
		.float	 13.00 

		.float	109.00 
		.float	  5.00 
		.float	 95.00 
		.float	  7.00 
		.float	  0.00 
		.float	101.00 
		.float	 65.00 
		.float	 19.00 
		.float	 17.00 
		.float	 43.00 
		.float	100.00 
		.float	 90.00 
		.float	 39.00 
		.float	 60.00 
		.float	 63.00 
		.float	 49.00 
		.float	 75.00 
		.float	 10.00 
		.float	 58.00 
		.float	 83.00 
		.float	 33.00 
		.float	109.00 
		.float	 63.00 
		.float	 96.00 

		.float	 82.00 
		.float	 69.00 
		.float	  3.00 
		.float	 82.00 
		.float	 91.00 
		.float	101.00 
		.float	 96.00 
		.float	 91.00 
		.float	107.00 
		.float	 81.00 
		.float	 99.00 
		.float	108.00 
		.float	 73.00 
		.float	 54.00 
		.float	 18.00 
		.float	 91.00 
		.float	 97.00 
		.float	  8.00 
		.float	 71.00 
		.float	 27.00 
		.float	 69.00 
		.float	 25.00 
		.float	 77.00 
		.float	 34.00 

		.float	 36.00 
		.float	 25.00 
		.float	  8.00 
		.float	 69.00 
		.float	 24.00 
		.float	 71.00 
		.float	 56.00 
		.float	106.00 
		.float	 30.00 
		.float	 60.00 
		.float	 79.00 
		.float	 12.00 
		.float	 51.00 
		.float	 65.00 
		.float	103.00 
		.float	 49.00 
		.float	 36.00 
		.float	 93.00 
		.float	 47.00 
		.float	  0.00 
		.float	 37.00 
		.float	 65.00 
		.float	 91.00 
		.float	 25.00 

		.float	 74.00 
		.float	 53.00 
		.float	 53.00 
		.float	 33.00 
		.float	 78.00 
		.float	 20.00 
		.float	 68.00 
		.float	  4.00 
		.float	 45.00 
		.float	 76.00 
		.float	 74.00 
		.float	 70.00 
		.float	 38.00 
		.float	 20.00 
		.float	 67.00 
		.float	 68.00 
		.float	 80.00 
		.float	 36.00 
		.float	 81.00 
		.float	 22.00 
		.float	101.00 
		.float	 75.00 
		.float	 71.00 
		.float	 28.00 

		.float	 58.00 
		.float	  9.00 
		.float	 28.00 
		.float	 96.00 
		.float	 75.00 
		.float	 10.00 
		.float	 12.00 
		.float	 39.00 
		.float	 63.00 
		.float	 65.00 
		.float	 73.00 
		.float	 31.00 
		.float	 85.00 
		.float	 31.00 
		.float	 36.00 
		.float	 20.00 
		.float	108.00 
		.float	  0.00 
		.float	 91.00 
		.float	 36.00 
		.float	 20.00 
		.float	 48.00 
		.float	105.00 
		.float	101.00 

		.float	 84.00 
		.float	 76.00 
		.float	 13.00 
		.float	 75.00 
		.float	 42.00 
		.float	 85.00 
		.float	103.00 
		.float	100.00 
		.float	 94.00 
		.float	 22.00 
		.float	 87.00 
		.float	 60.00 
		.float	 32.00 
		.float	 99.00 
		.float	100.00 
		.float	 96.00 
		.float	 54.00 
		.float	 63.00 
		.float	 17.00 
		.float	 30.00 
		.float	 95.00 
		.float	 54.00 
		.float	 51.00 
		.float	 93.00 

		.float	 54.00 
		.float	 32.00 
		.float	 19.00 
		.float	 75.00 
		.float	 80.00 
		.float	 15.00 
		.float	 66.00 
		.float	 54.00 
		.float	 92.00 
		.float	 79.00 
		.float	 19.00 
		.float	 24.00 
		.float	 54.00 
		.float	 13.00 
		.float	 15.00 
		.float	 39.00 
		.float	 35.00 
		.float	102.00 
		.float	 99.00 
		.float	 68.00 
		.float	 92.00 
		.float	 89.00 
		.float	 54.00 
		.float	 36.00 

		.float	 43.00 
		.float	 72.00 
		.float	 66.00 
		.float	 28.00 
		.float	 16.00 
		.float	  7.00 
		.float	 11.00 
		.float	 71.00 
		.float	 39.00 
		.float	 31.00 
		.float	 36.00 
		.float	 10.00 
		.float	 47.00 
		.float	102.00 
		.float	 64.00 
		.float	 29.00 
		.float	 72.00 
		.float	 83.00 
		.float	 53.00 
		.float	 17.00 
		.float	 97.00 
		.float	 68.00 
		.float	 56.00 
		.float	 22.00 

		.float	 61.00 
		.float	 46.00 
		.float	 91.00 
		.float	 43.00 
		.float	 26.00 
		.float	 35.00 
		.float	 80.00 
		.float	 70.00 
		.float	108.00 
		.float	 37.00 
		.float	 98.00 
		.float	 14.00 
		.float	 45.00 
		.float	  0.00 
		.float	 86.00 
		.float	 85.00 
		.float	 32.00 
		.float	 12.00 
		.float	 95.00 
		.float	 79.00 
		.float	  5.00 
		.float	 49.00 
		.float	108.00 
		.float	 77.00 

		.float	 23.00 
		.float	 52.00 
		.float	 95.00 
		.float	 10.00 
		.float	 10.00 
		.float	 42.00 
		.float	 33.00 
		.float	 72.00 
		.float	 89.00 
		.float	 14.00 
		.float	  5.00 
		.float	  5.00 
		.float	 50.00 
		.float	 85.00 
		.float	 76.00 
		.float	 48.00 
		.float	 13.00 
		.float	 64.00 
		.float	 63.00 
		.float	 58.00 
		.float	 65.00 
		.float	 39.00 
		.float	 33.00 
		.float	 97.00 

		.float	 52.00 
		.float	 18.00 
		.float	 67.00 
		.float	 57.00 
		.float	 68.00 
		.float	 65.00 
		.float	 25.00 
		.float	 91.00 
		.float	  7.00 
		.float	 10.00 
		.float	101.00 
		.float	 18.00 
		.float	 52.00 
		.float	 24.00 
		.float	 90.00 
		.float	 31.00 
		.float	 39.00 
		.float	 96.00 
		.float	 37.00 
		.float	 89.00 
		.float	 72.00 
		.float	  3.00 
		.float	 28.00 
		.float	 85.00 

		.float	 68.00 
		.float	 91.00 
		.float	 33.00 
		.float	 24.00 
		.float	 21.00 
		.float	 67.00 
		.float	 12.00 
		.float	 74.00 
		.float	 86.00 
		.float	 79.00 
		.float	 22.00 
		.float	 44.00 
		.float	 34.00 
		.float	 47.00 
		.float	 25.00 
		.float	 42.00 
		.float	 58.00 
		.float	 17.00 
		.float	 61.00 
		.float	  1.00 
		.float	 41.00 
		.float	 42.00 
		.float	 33.00 
		.float	 81.00 

		.float	 28.00 
		.float	 71.00 
		.float	 60.00 
		.float	101.00 
		.float	 75.00 
		.float	 89.00 
		.float	 76.00 
		.float	 34.00 
		.float	 71.00 
		.float	  0.00 
		.float	 58.00 
		.float	 92.00 
		.float	 68.00 
		.float	 70.00 
		.float	 57.00 
		.float	 44.00 
		.float	 39.00 
		.float	 79.00 
		.float	 88.00 
		.float	 74.00 
		.float	 16.00 
		.float	  3.00 
		.float	  6.00 
		.float	 75.00 

		.float	 20.00 
		.float	 68.00 
		.float	 77.00 
		.float	 62.00 
		.float	  0.00 
		.float	  0.00 
		.float	 33.00 
		.float	 28.00 
		.float	 72.00 
		.float	 94.00 
		.float	 19.00 
		.float	 37.00 
		.float	 73.00 
		.float	 96.00 
		.float	 71.00 
		.float	 34.00 
		.float	 97.00 
		.float	 20.00 
		.float	 17.00 
		.float	 55.00 
		.float	 91.00 
		.float	 74.00 
		.float	 99.00 
		.float	 21.00 

		.float	 43.00 
		.float	 77.00 
		.float	 95.00 
		.float	 60.00 
		.float	 81.00 
		.float	102.00 
		.float	 25.00 
		.float	101.00 
		.float	 60.00 
		.float	102.00 
		.float	 54.00 
		.float	 60.00 
		.float	103.00 
		.float	 87.00 
		.float	 89.00 
		.float	 65.00 
		.float	 72.00 
		.float	109.00 
		.float	102.00 
		.float	 35.00 
		.float	 96.00 
		.float	 64.00 
		.float	 70.00 
		.float	 83.00 

		.float	 85.00 
		.float	 87.00 
		.float	 28.00 
		.float	 66.00 
		.float	 51.00 
		.float	 18.00 
		.float	 87.00 
		.float	 95.00 
		.float	 96.00 
		.float	 73.00 
		.float	 45.00 
		.float	 67.00 
		.float	 65.00 
		.float	 71.00 
		.float	 59.00 
		.float	 16.00 
		.float	 63.00 
		.float	  3.00 
		.float	 77.00 
		.float	 56.00 
		.float	 91.00 
		.float	 56.00 
		.float	 12.00 
		.float	 53.00 

		.float	 56.00 
		.float	  5.00 
		.float	 89.00 
		.float	 42.00 
		.float	 70.00 
		.float	 49.00 
		.float	 15.00 
		.float	 45.00 
		.float	 27.00 
		.float	 44.00 
		.float	  1.00 
		.float	 78.00 
		.float	 63.00 
		.float	 89.00 
		.float	 64.00 
		.float	 49.00 
		.float	 52.00 
		.float	109.00 
		.float	  6.00 
		.float	  8.00 
		.float	 70.00 
		.float	 65.00 
		.float	 24.00 
		.float	 24.00 

### End of data segment
