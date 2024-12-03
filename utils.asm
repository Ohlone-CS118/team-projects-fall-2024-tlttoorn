.include "definitions.asm"
.data
	.extern imageDirectory 8
	.extern partBuffer 4
	.extern partExtension 6
	
	.extern stencilDirectory 10
	.extern stencilExtension 7
	.eqv MARGIN_OF_SAFETY 20

	.macro return
	jr $ra			# Legibility of jr $ra
	.end_macro

	.macro exit
	li $v0 10
	syscall
	.end_macro

	.macro malloc(%bytes)
	li $v0 9
	add $a0 $zero %bytes
	syscall
	.end_macro

	.macro push(%item)
	sw %item -4($sp)
	subi $sp $sp 4
	.end_macro

	.macro pop(%reg)
	lw %reg ($sp)
	addi $sp $sp 4
	.end_macro
	
	.macro destroy(%args)
	add $t0 $zero %args
	mul $t0 $t0 4
	add $sp $sp $t0
	.end_macro

	.macro top(%reg)
	lw %reg ($sp)
	.end_macro
	
	.macro below_top(%reg)
	lw %reg 4($sp)
	.end_macro

	.macro enable_keyboard()
	li $t0 2
	sw $t0 0xffff0000 # Update the memory mapped receiver control register
	.end_macro

	.macro disable_keyboard()
	sw $zero 0xffff0000
	.end_macro
	
	.macro start_music()
	jal music_setup
	jal note_setup
	.end_macro

	.macro get_arg(%argAt, %reg)
	li %reg 4
	mul %reg %reg %argAt
	sub %reg $fp %reg
	lw %reg (%reg)
	.end_macro

	# overhead macro to speed up process of setting frame pointer and stack in a function
	# Precondition: %args is the number of arguments loaded onto the stack
	# Postcondition: ra and fp are added onto stack; fp is shifted before arguments
	.macro overhead(%args)
	add $t0 $zero %args
	sw $ra -4($sp)		# Store ra and fp
	sw $fp -8($sp)

	mul $t0 $t0 4	# Calculate number of bytes given non-dobule args

	add $fp $sp $t0		# Shift fp back before arguments using calculated bytes
	subi $sp $sp 8		# Allocate 8 bytes
	.end_macro

	# cleanup macro to speed up process of restoring frame pointer and return address
	# Precondition: %args is the number of arguments loaded onto the stack
	# Postcondition: ra and fp are restored back to their original values
	.macro cleanup(%args)
	add $t0 $zero %args
	mul $t0 $t0 4		# Calculate number of bytes fp was thrown back based on argument count
	sub $fp $fp $t0		# Move fp right before overhead

	lw $ra -4($fp)		# Load back ra and fp
	lw $fp -8($fp)

	addi $sp $sp 8		# Destroy 8 bytes
	.end_macro

	# Set the time of the last note played to "currently"
	# Precondition: None
	# Postcondition: Set lastNoteTime to $a0
	.macro set_time()
	li $v0 30
	syscall 				# Get the ms since epoch time and write to lo (a0) hi (a1)
	move lastNoteTime $a0
	.end_macro

	.macro is_time()
	li $v0 30
	syscall
	sub $t0 $a0 lastNoteTime
	subi $t1 nextNoteTime MARGIN_OF_SAFETY
	sub $t0 $t0 $t1
	bltz $t0 not_yet
	push($ra)
	jal queue_note
	pop($ra)
	not_yet:
	.end_macro

	.macro char(%int, %buffer)
	add $t0 $zero %int
	li $t1 10			# 10 Divisor
	li $t2 0			# Number of bytes to allocate
	# Quotient (lo) Remainder (hi)
	# If quotient but 0 remainder (divisible by 10)
	# quotient 0-9 -> 2 bytes
	# quotient 10-99 -> 3 bytes
	# If remainder but not quotient: end
	# Else continue
	allocation_loop:
	div $t0 $t1
	mflo $t0
	mfhi $t3
	addi $t3 $t3 48
	sb $t3 -1($sp)
	subi $sp $sp 1
	addi $t2 $t2 1
	beqz $t0 allocation_end
	j allocation_loop
	allocation_end:
	la $t1 %buffer
	move_bytes:
	lb $t0 ($sp)
	sb $t0 ($t1)
	addi $sp $sp 1
	addi $t1 $t1 1
	subi $t2 $t2 1
	beqz $t2 end_move
	j move_bytes
	end_move:
	sb $zero ($t1)
	.end_macro

	.macro lower(%reg)
	blt %reg 65 else
	bgt %reg 90 else
	addi %reg %reg 32
	else:
	.end_macro

	.macro validate_input(%reg)
	beq %reg 32 valid
	sle $t0 %reg 122
	sge $t1 %reg 97
	seq $t0 $t0 $t1
	mul %reg %reg $t0
	valid:
	.end_macro

	.macro append(%label, %buffer, %offset)
	la $a0 %label
	append_reg($a0, %buffer, %offset)
	.end_macro

	.macro append_reg(%reg, %buffer, %offset)
	move $a0 %reg
	add $t0 $zero %offset
	write_to_buffer($a0, %buffer, %offset)
	subi $v0 $v0 1
	.end_macro

	.macro write_to_buffer(%reg, %buffer, %offset)
	move $a0 %reg
	la $a1 %buffer
	add $a1 $a1 %offset
	li $v0 0
	write:
	lb $t0 ($a0)
	sb $t0 ($a1)
	addi $a0 $a0 1
	addi $a1 $a1 1
	addi $v0 $v0 1
	bnez $t0 write
	.end_macro

	.macro append_char(%reg, %buffer, %offset)
	move $a0 %reg
	la $a1 %buffer
	add $a1 $a1 %offset
	sb $a0 ($a1)
	li $v0 1
	.end_macro

	.macro strstr(%string_reg, %sub_reg)
	move $a0 %string_reg
	move $a1 %sub_reg
	move $t0 $a0
	move $t1 $a1
	li $v0 1
	j find_sub
	shift_start:
	addi $v0 $v0 1
	addi $a0 $a0 1
	move $t0 $a0
	move $t1 $a1
	find_sub:
	lb $t2 ($t0)
	lb $t3 ($t1)
	lower($t2)
	lower($t3)
	beqz $t3 end_find
	beqz $t2 end_find
	bne $t2 $t3 shift_start
	addi $t0 $t0 1
	addi $t1 $t1 1
	j find_sub
	end_find:
	seq $t2 $zero $t3
	mul $v0 $v0 $t2
	subi $v0 $v0 1
	.end_macro
	
	.macro directory_conversion(%buffer_reg, %new_buffer_lab)
	move $a0 %buffer_reg
	la $a1 %new_buffer_lab
	subi $a0 $a0 1
	subi $a1 $a1 1
	convert:
	addi $a0 $a0 1
	addi $a1 $a1 1
	lb $t0 ($a0)
	beqz $t0 end_conversion
	lower($t0)
	sb $t0 ($a1)
	bne $t0 32 convert
	li $t0 95
	sb $t0 ($a1)
	j convert
	end_conversion:
	li $t0 47
	sb $t0 ($a1)
	sb $zero 1($a1)
	.end_macro

	.macro draw_input(%character_reg)
	subi $a0 %character_reg 97
	bltz $a0 end
	mul $a0 $a0 4
	la $t0 stencilList
	add $t0 $t0 $a0
	lw $t0 ($t0)
	mul $a0 inputBufferOffset 14
	addi $a0 $a0 TYPING_CORNER_X
	li $a1 TYPING_CORNER_Y
	addi $t1 $t0 STENCIL_SIZE
	drawing_loop:
	lw $a2 ($t0)
	addi $t0 $t0 4
	bgt $t0 $t1 end
	beq $a2 0xFFFFFF skip_square
	beq $a2 0x7F7F7F wrap_around
	push($a0)
	push($a1)
	push($t0)
	push($t1)
	draw_pixel($a0, $a1, $a2)
	pop($t1)
	pop($t0)
	pop($a1)
	pop($a0)
	skip_square:
	addi $a0 $a0 1
	j drawing_loop
	wrap_around:
	addi $a1 $a1 1
	mul $a0 inputBufferOffset 14
	addi $a0 $a0 TYPING_CORNER_X
	j drawing_loop
	end:
	.end_macro
	
	.macro draw_pixel(%x, %y, %color)
	add $a0 $zero %x
	add $a1 $zero %y
	add $a2 $zero %color
	mul $a1 $a1 LINE_SIZE
	mul $a0 $a0 4
	add $a0 $a0 $a1
	addi $a0 $a0 DISPLAY
	sw $a2 ($a0)
	.end_macro

	# Open file in read mode
	# Precondition: %path is a string of the path
	# Postcondition: v0 holds the file descriptor of the open file
	.macro file_open_read(%path)
	li $v0 13			# Open file syscall
	move $a0 %path		# Load Filename
	li $a1 0			# Set flag to read
	li $a2 0			# Mode is ignored
	syscall
	.end_macro

	# Display the compiled image from the provided path
	# Precondition: %directory is a string path
	# Postcondition: Image is loaded into display buffer
	.macro read_image(%image)
	disable_keyboard()
	la $a0 %image			# Load path
	jal line_by_line_draw	# Make a call to readFile

	fix_endian()
	enable_keyboard()
	.end_macro

	.macro fix_endian()
	li $t0 DISPLAY
	addi $t1 $t0 LINE_SIZE
	li $t2 0
	fix_endian_loop:
	lw $t3 ($t0)
	sw $t3 ($t0)
	addi $t0 $t0 4
	blt $t0 $t1 fix_endian_loop
	addi $t1 $t1 LINE_SIZE
	addi $t2 $t2 1
	push($t0)
	push($t1)
	push($t2)
	is_time()
	pop($t2)
	pop($t1)
	pop($t0)
	blt $t2 LINE_COUNT fix_endian_loop
	.end_macro

	# Closes a file from a provided descriptor
	# Precondition: %file is a file descriptor provided by syscall 13
	# Postcondition: File is now closed
	.macro close_file(%file)
	li $v0 16
	move $a0 %file
	syscall
	.end_macro

.text
# Read in the file from the given path and store it in a buffer
# precondition: a0 holds file path
# postcondition: buffer holds info from file
line_by_line_draw:
	push($a0)
	append(imageDirectory, finalPath, 0)
	pop($a0)
	push($v0)
	append_reg($a0, finalPath, $v0)
	pop($v1)
	add $v0 $v0 $v1
	li $t0 0
	li $t1 1
	push($t0)
	push($t1)
	push($v0)
	# Stack: [$t0 display offset, $t1 lines read, $v0 path offset]
line_by_line:
	char($t1, partBuffer)
	top($v0)
	append(partBuffer, finalPath, $v0)
	top($v1)
	add $v0 $v0 $v1
	append(partExtension, finalPath, $v0)
	la $a0 finalPath
	file_open_read($a0)		# Open file in read mode

	move $a0 $v0			# Returns file descriptor

	pop($t2)
	pop($t1)
	pop($t0)

	li $v0 14				# Read file
	la $a1 DISPLAY
	add $a1 $a1 $t0
	add $a2 $zero LINE_SIZE
	syscall

	add $t0 $t0 $a2
	addi $t1 $t1 1

	push($t0)
	push($t1)
	push($t2)

	close_file($a0)			# Close file

	is_time()
	below_top($t1)
	ble $t1 256 line_by_line

	return					# Return

get_likely_country:
	overhead(COUNTRY_COUNT)
	li $t0 1
	li $t1 INPUT_BUFFER_SPACE
	li $v0 -1
lowest_index_search:
	bgt $t0 COUNTRY_COUNT end_index_search
	get_arg($t0, $a0)
	addi $t0 $t0 1
	beq $a0 -1 lowest_index_search
	bgt $a0 $t1 lowest_index_search
	move $t1 $a0
	subi $v0 $t0 2
	beqz $a0 end_index_search
	j lowest_index_search
end_index_search:	
	cleanup(COUNTRY_COUNT)
	return
