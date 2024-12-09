# Stencil: Daniel
.include "utils.asm"
.data
	stencilDirectory: .asciiz "stencils/"	# Main stencil directory
	stencilExtension: .asciiz ".stncl"		# stencil file extension
	.align 2
	letterA: .space STENCIL_SIZE			# All 26 letters + backspace "character" allocated into the data section
	letterB: .space STENCIL_SIZE			# Backspace is the character "{" (123) the value after Z (122)
	letterC: .space STENCIL_SIZE
	letterD: .space STENCIL_SIZE
	letterE: .space STENCIL_SIZE
	letterF: .space STENCIL_SIZE
	letterG: .space STENCIL_SIZE
	letterH: .space STENCIL_SIZE
	letterI: .space STENCIL_SIZE
	letterJ: .space STENCIL_SIZE
	letterK: .space STENCIL_SIZE
	letterL: .space STENCIL_SIZE
	letterM: .space STENCIL_SIZE
	letterN: .space STENCIL_SIZE
	letterO: .space STENCIL_SIZE
	letterP: .space STENCIL_SIZE
	letterQ: .space STENCIL_SIZE
	letterR: .space STENCIL_SIZE
	letterS: .space STENCIL_SIZE
	letterT: .space STENCIL_SIZE
	letterU: .space STENCIL_SIZE
	letterV: .space STENCIL_SIZE
	letterW: .space STENCIL_SIZE
	letterX: .space STENCIL_SIZE
	letterY: .space STENCIL_SIZE
	letterZ: .space STENCIL_SIZE
	backspace: .space STENCIL_SIZE
	# The actual list of the stencils
	.globl stencilList
	stencilList: .word letterA, letterB, letterC, letterD, letterE, letterF, letterG, letterH, letterI, letterJ, letterK, letterL, letterM, letterN, letterO, letterP, letterQ, letterR, letterS, letterT, letterU, letterV, letterW, letterX, letterY, letterZ, backspace
	
	# Take in a label "path" and register "stencil_buffer" and read the file in path into the buffer
	# Precondition: %path_lab is a complete file path, %stencil_buffer_reg is an allocated space for a stencil
	# Postcondition: file at %path_lab is fully and correctly read into %stencil_buffer_reg address
	.macro read_stencil(%path_lab, %stencil_buffer_reg)
	move $a1 %stencil_buffer_reg						# Store register in a1 to prevent overwrites
	la $a0 %path_lab									# Store adress of label in a0
	push($a1)											# Push register onto the stack to prevent overwrites
	file_open_read($a0)									# Open file at the given path for reading
	move $a0 $v0										# Store file descriptor back in a0
	top($a1)											# Restore the register address of the buffer
	
	li $v0 14
	li $a2 STENCIL_SIZE									# Actually read in the stencil file
	syscall
	
	close_file($a0)										# Close the file
	pop($a1)											# Pop the stencil buffer address back of the stack
	
	fix_stencil($a1)									# "Fix" the read in file
	is_time()											# Check if it's time to play the next note
	.end_macro
	
	# Move every byte of memory off and on to the stencil again (MIPS file reading issues)
	# Precondition: %stencil_buffer_reg is the address of a given stencil buffer
	# Postcondition: The buffer is fixed
	.macro fix_stencil(%stencil_buffer_reg)
	move $a0 %stencil_buffer_reg			# Store the register to prevent overwrites
	fix_endian_loop:
	lw $t0 ($a0)							# Pop off the buffer
	sw $t0 ($a0)							# Push back onto the buffer
	addi $a0 $a0 4							# Go to the next space
	blt $a0 STENCIL_SIZE fix_endian_loop	# Loop until the end of the buffer is reached
	.end_macro

.text

.globl load_letters
# Load all stencils for the alphabet + backspace from their given file into their respective buffer
# Precondition: None
# Postcondition: All stencil buffers are filled with the data loaded in from their respective files
load_letters:
	append(stencilDirectory, finalPath, 0)		# Append stencil directory to the beginning of the file path
	li $t0 97									# Load the integer representation of the character a
	push($t0)									# Store current character
	push($v0)									# Store current file path buffer offset
	load_loop:
	append_char($t0, finalPath, $v0)			# Append character to the file path
	top($v1)									# Restore the value of the offset
	add $v0 $v0 $v1								# Add old offset to the written characters
	append(stencilExtension, finalPath, $v0)	# File path obtained
	below_top($t0)								# Restore the current character
	subi $t0 $t0 97								# Convert the character into an index offset into stencilList
	mul $t0 $t0 4
	la $t1 stencilList							# Load start of stencilList
	add $t1 $t1 $t0								# Index into stencillist
	lw $t0 ($t1)								# Get buffer for current character
	read_stencil(finalPath, $t0)				# Read the file from file path into the buffer address at t0
	pop($v0)									# Pop until we get t0
	pop($t0)
	addi $t0 $t0 1								# t0 holds the value of the next character to get
	push($t0)
	push($v0)									# Push the values back onto the stack
	ble $t0 123 load_loop						# Until character 123 is reached, continue to load in stencils
	
	return										# Return
