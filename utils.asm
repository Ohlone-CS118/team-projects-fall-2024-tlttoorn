# Original Subroutines: Angel & Daniel
# Macro conversion and other unnecessary optimizations: Angel
.include "definitions.asm"
.data
	# All extern values are values accessed from main
	.extern inputBuffer INPUT_BUFFER_SPACE
	.extern imageDirectory 8
	.extern partBuffer 4
	.extern partExtension 6
	
	.extern dataBuffer DATA_BUFFER_SPACE
	.extern dataDirectory 6
	.extern dataExtension 5
	
	# Within how many miliseconds is nextNoteTime considered close enough to execute
	.eqv MARGIN_OF_SAFETY 20
	
	# Angel
	.macro return
	jr $ra			# Legibility of jr $ra
	.end_macro
	# Angel
	.macro exit
	li $v0 10		# Legibility of exiting the program
	syscall
	.end_macro
	
	# Angel
	# Takes in an immediate or register and allocates that much space on the heap
	# Precondition %bytes is an intger or register
	# Postcondition $v0 holds the address to the allocated space
	.macro malloc(%bytes)
	li $v0 9
	add $a0 $zero %bytes
	syscall
	.end_macro
	
	# Angel
	# A simple function to add a newline after printing something
	# Precondition: None
	# Postconditin: Newline printed
	.macro newline()
	li $v0 11
	li $a0 10
	syscall
	.end_macro
	
	# Angel
	# Pushes the register to the stack, without register mutation
	# Precondition: %reg is a register
	# Postcondition: %reg is added to the stack
	.macro push(%reg)
	sw %reg -4($sp)
	subi $sp $sp 4
	.end_macro
	
	# Angel
	# Pops the last item from the stack into a register, without register mutation
	# Precondition: %reg is the register to store the stack item into
	# Postcondition: %reg holds the popped value
	.macro pop(%reg)
	lw %reg ($sp)
	addi $sp $sp 4
	.end_macro
	
	# Angel
	# Destroys a number of values from the top of the stack
	# Precondition: %args is an immediate or register
	# Postcondition: sp has been moved closer to base to "destroy" %args number of word aligned items 
	.macro destroy(%args)
	add $t0 $zero %args
	mul $t0 $t0 4
	add $sp $sp $t0
	.end_macro
	
	# Angel
	# Gets the item at the top of the stack and store it into a register, without register mutation
	# Precondition: %reg is the register to store the stack item into
	# Postcondition: %reg holds the topped value
	.macro top(%reg)
	lw %reg ($sp)
	.end_macro
	
	# Angel
	# Gets the item right below the top of the stack and store it into a register, without register mutation
	# Precondition: %reg is the register to store the stack item into
	# Postcondition: %reg holds the value below the top
	.macro below_top(%reg)
	lw %reg 4($sp)
	.end_macro
	
	# Daniel
	# Enables the keyboard to read keypresses
	# Precondition: None
	# Postcondition: Keyboard tracks keypresses
	.macro enable_keyboard()
	li $t0 2					# t0 = 2
	sw $t0 0xffff0000			# Update the memory mapped receiver control register
	.end_macro
	
	# Daniel
	# Disables the keyboard to ignore keypresses
	# Precondition: None
	# Postcondition: Keyboard ignores keypresses
	.macro disable_keyboard()
	sw $zero 0xffff0000 # Update the memory mapped receiver control register to ignore inputs
	.end_macro
	
	# Angel
	# Sets up the music for the program to begin playing it
	# Precondition: None
	# Postcondition: 
	#		- nextDoubleMeasure is set to first music double measure
	#		- currentNote is set to the first note / data of the music
	#		- sustain is set to default max value
	#		- lastNoteTime is set to current millisecond
	# 		- nextNoteTime is set to the time in milliseconds with the next note should play
	.macro start_music()
	jal music_setup			# Set up the first double measure, first note, and sustain
	jal note_setup			# Play the first note in the track, determine current time and time till next note
	.end_macro
	
	# Angel
	# If using a stack funciton, grabs the given argument and puts it into the given register, without register mutation
	# Precondition: %argAt is an immediate or register and %reg is a different register 
	# Postcondition: %reg holds the argument number requested
	.macro get_arg(%argAt, %reg)
	li %reg 4						# Load word indexing multiplier
	mul %reg %reg %argAt			# Multiply it by argument number requested
	sub %reg $fp %reg				# Offset this value from fp which points to before arguments on stack
	lw %reg (%reg)					# Load value at offset into register
	.end_macro
	
	# Angel
	# overhead macro to speed up process of setting frame pointer and stack in a function
	# Precondition: %args is the number of arguments loaded onto the stack
	# Postcondition: ra and fp are added onto stack; fp is shifted before arguments
	.macro overhead(%args)
	add $t0 $zero %args
	sw $ra -4($sp)			# Store ra and fp
	sw $fp -8($sp)

	mul $t0 $t0 4			# Calculate number of bytes given non-dobule args

	add $fp $sp $t0			# Shift fp back before arguments using calculated bytes
	subi $sp $sp 8			# Allocate 8 bytes
	.end_macro
	
	# Angel
	# cleanup macro to speed up process of restoring frame pointer and return address
	# Precondition: %args is the number of arguments loaded onto the stack
	# Postcondition: ra and fp are restored back to their original values
	.macro cleanup(%args)
	add $t0 $zero %args
	mul $t0 $t0 4			# Calculate number of bytes fp was thrown back based on argument count
	sub $fp $fp $t0			# Move fp right before overhead

	lw $ra -4($fp)			# Load back ra and fp
	lw $fp -8($fp)

	addi $sp $sp 8			# Destroy 8 bytes
	.end_macro
	
	# Angel
	# Set the time of the last note played to "currently"
	# Precondition: None
	# Postcondition: Set lastNoteTime to $a0
	.macro set_time()
	li $v0 30
	syscall 				# Get the ms since epoch time and write to lo (a0) hi (a1)
	move lastNoteTime $a0	# lastNoteTime = a0
	.end_macro
	
	# Angel
	# Check if it is almost time to play the next note
	# Precondition: lastNoteTime and nextNoteTime are already set
	# Postcondition: If time, plays the given note, potentially modifying all the same values present in start_music()
	.macro is_time()
	li $v0 30
	syscall									# Get the ms since epoch time and write to lo (a0) hi (a1)
	sub $t0 $a0 lastNoteTime				# Get the ms since the last note was played
	subi $t1 nextNoteTime MARGIN_OF_SAFETY	# Get amount of ms that should pass for the next note to play within margin
	sub $t0 $t0 $t1							# Condition (currentTime - lastNoteTime) > nextNoteTime
	bltz $t0 not_yet						# If not enough time has passed, skip note call
	push($ra)
	jal queue_note							# Otherwise store return address, and play note
	pop($ra)
	not_yet:
	.end_macro
	
	# Angel
	# Convert an integer into a character/string and write it to a buffer
	# Precondition: %int is an immediate or register of an integer < 1000 and %buffer_lab is a label of for an address
	# Postcondition: %buffer_lab holds the converted intger
	.macro char(%int, %buffer_lab)
	add $t0 $zero %int				# Move %int into t0
	li $t1 10						# t1 = 10 Divisor
	li $t2 0						# t2 =  Number of bytes to allocate
	allocation_loop:
	div $t0 $t1						# t0 / t1 --> | lo = quotient | hi = remainder
	mflo $t0						# t0 = quotient
	mfhi $t3						# t3 = remainder
	addi $t3 $t3 48					# convert intger to character | char(t3) = t3
	sb $t3 -1($sp)					# Store t3 to next byte on stack
	subi $sp $sp 1					# Allocate 1 byte on stack
	addi $t2 $t2 1					# t2++ | One more byte to allocate
	beqz $t0 allocation_end			# if t0 == 0, end
	j allocation_loop				# else, loop
	allocation_end:
	la $t1 %buffer_lab				# Load buffer address into t1
	move_bytes:
	lb $t0 ($sp)					# top of sp -> next free byte of t1
	sb $t0 ($t1)
	addi $sp $sp 1					# Destroy last value from stack
	addi $t1 $t1 1					# Move to the next free byte of the buffer
	subi $t2 $t2 1					# t2-- | One less byte to allocate
	beqz $t2 end_move				# if no more bytes to allocate, end
	j move_bytes					# else, loop
	end_move:
	sb $zero ($t1)					# Store null terminator at the end of the buffer
	.end_macro
	
	# Daniel
	# Lower a character, mutates the given register. E.g. A --> a
	# Precondition: %reg is a register holding a character value
	# Postcondition: %reg holds a "lower" character value
	.macro lower(%reg)
	blt %reg 65 else	# If character is not between capital A
	bgt %reg 90 else	# or capital Z, skip
	addi %reg %reg 32	# Else, add 32 to convert ascii character to its "lower" form
	else:
	.end_macro
	
	# Daniel
	# Validates input from the keyboard before adding it to the input buffer, mutates register
	# Precondition: %reg is a register holding a keyboard input
	# Postcondition: %reg stays the same if valid and holds 0 otherwise
	.macro validate_input(%reg)
	beq %reg 32 valid			# If %reg is a space, the input is valid
	sle $t0 %reg 122			# If %reg is between 122 (z)	| t0 = T or F
	sge $t1 %reg 97				# and 97 (a)					| t1 = T or F
	seq $t0 $t0 $t1				# The input is valid			| t0 = (t0 and t1) --> t0 = 0 or 1
	mul %reg %reg $t0			# Otherwise, set %reg to 0		| reg *= t0 --> reg = reg or 0
	valid:
	.end_macro
	
	# Angel
	# Appends the first label buffer to the second label buffer at the location offset
	# Precondition: %label and %buffer_lab are labels to a buffer | %offset is an immediate or register
	# Postcondition: %buffer_lab holds %label starting from %offset
	.macro append(%label, %buffer_lab, %offset)
	la $a0 %label								# Convert %label into a register
	append_reg($a0, %buffer_lab, %offset)		# Call append register function
	.end_macro
	
	# Angel
	# Appends the register buffer to the label buffer at the location offset
	# Precondition: %buffer_reg and %buffer_lab are addresses to a buffer | %offset is an immediate or register
	# Postcondition: %buffer_lab holds %buffer_reg starting from %offset  | $v0 holds the number of characters written
	.macro append_reg(%buffer_reg, %buffer_lab, %offset)
	move $a0 %buffer_reg									# Move %buffer_reg to a0 to prevent overwrite
	la $a1 %buffer_lab										# Load %buffer_lab into a1
	add $a1 $a1 %offset										# Adjust a1 address to %offset
	li $v0 0												# Set number of character written to 0 | v0 = 0
	write:
	lb $t0 ($a0)											# Move next register byte to next label byte | a0 --> a1
	sb $t0 ($a1)
	addi $a0 $a0 1											# Move buffer register address over | a0++
	addi $a1 $a1 1											# Move buffer label address over	| a1++
	addi $v0 $v0 1											# Add character written to counter	| v0++
	bnez $t0 write											# While (t0 != 0)
	subi $v0 $v0 1											# When loop ends, don't count null terminator | v--
	.end_macro
	
	# Angel
	# Append the character in the register to the buffer at label at the given offset
	# Precondition: %reg --> char value, %buffer_lab --> buffer address, %offset --> immediate or register
	# Postcondition: %buffer_lab has %reg appended to the end | No null terminator | $v0 return one character written
	.macro append_char(%reg, %buffer_lab, %offset)
	move $a0 %reg									# Move %reg to a0 to prevent overwrite
	la $a1 %buffer_lab								# Load %buffer_lab into a1
	add $a1 $a1 %offset								# Adjust a1 address to %offset
	sb $a0 ($a1)									# Store character at a1
	li $v0 1										# v0 = 1
	.end_macro
	
	# Daniel
	# Returns the location of a substring in a string or -1 if not found. Equivalent to C/C++ strstr()
	# Precondition: %string_reg and %sub_reg are both registers with addresses to string buffers
	# Postcondition: v0 holds the index of the substring of -1 if it was not found
	.macro strstr(%string_reg, %sub_reg)
	move $a0 %string_reg					# Move %string_reg to a0 to prevent overwrite
	move $a1 %sub_reg						# Move %sub_reg to a1 to prevent overwrite
	move $t0 $a0							# Create mutable versions of the addresses | t0 = a0 and t1 = a1
	move $t1 $a1
	li $v0 1								# Set current index to 1
	j find_sub
	shift_start:
	addi $v0 $v0 1							# Shift index of substring location over by 1
	addi $a0 $a0 1							# Shift start of string over by 1
	move $t0 $a0							# Move new string starting point to t0
	move $t1 $a1							# Restore substring starting point to t1
	find_sub:
	lb $t2 ($t0)							# Get next value of string 		| t2 = t0[0]
	lb $t3 ($t1)							# Get next value of substring	| t3 = t1[0]
	lower($t2)								# lower(t2) and lower(t3)
	lower($t3)
	beqz $t3 end_find						# If t3 == 0, end search --> you've found the whole substring
	beqz $t2 end_find						# If t2 == 0, end search --> you've searched the whole string
	bne $t2 $t3 shift_start					# If t2 != t3, shift_start --> Mismatch, shift starting position over by 1
	addi $t0 $t0 1							# Else: comapre the next byte of t0 and t1
	addi $t1 $t1 1							# t0++ | t1++
	j find_sub								# Loop substring search
	end_find:
	seq $t2 $zero $t3						# The substring search is only valid if t3 is the null terminator
	mul $v0 $v0 $t2							# v0 holds the index or -1	| v0 *= t2 --> v0 = index + 1 or 0
	subi $v0 $v0 1							# Remove original preset 1	| v0--	   --> v0 = index or -1
	.end_macro
	
	# Daniel
	# Takes a string buffer reg and writes its appropriate directory form to a different buffer
	# Precondition: %buffer_reg and %buffer_lab both hold buffer addresses in their respective formats
	# Postcondition: %buffer_lab filled with the directory location based on the given string in %buffer_reg
	.macro directory_conversion(%buffer_reg, %buffer_lab)
	move $a0 %buffer_reg									# Move %buffer_reg to a0 to prevent overwrite
	la $a1 %buffer_lab										# Load %buffer_lab into a1
	subi $a0 $a0 1											# Move a0 and a1 back in preparation for loop
	subi $a1 $a1 1											# a0-- and a1--
	convert:
	addi $a0 $a0 1											# Move to next character					| a0++
	addi $a1 $a1 1											# Move to next avaliable space in buffer	| a1++
	lb $t0 ($a0)											# Load next character into t0
	beqz $t0 end_conversion									# If t0 == 0, end loop
	lower($t0)												# Else, lower(t0)
	sb $t0 ($a1)											# Store t0 in next buffer location
	bne $t0 32 convert										# If not reading in a space character, loop
	li $t0 95												# Else, overwrite last buffer location with an underscore
	sb $t0 ($a1)											# All values are lowered and all spaces are underscored
	j convert												# Loop
	end_conversion:
	li $t0 47
	sb $t0 ($a1)											# Buffer ends in forward slash and null terminator
	sb $zero 1($a1)
	.end_macro
	
	# Daniel
	# Draws the character at the next appropriate position
	# Precondition: %character_reg holds the lowered character from a-z to draw
	# Postcondition: The character will appear at the top of the display
	.macro draw_input(%character_reg)
	subi $a0 %character_reg 97					# Subtract 97 from the character to get an index
	bltz $a0 end								# If %character_reg is not a-z, do not draw
	mul $a0 $a0 4								# Shift index by word indexing multiplier
	la $t0 stencilList							# Load stencilList address
	add $t0 $t0 $a0								# Get address of stencilList at the given index
	lw $t0 ($t0)								# buffer of pixels for character = stencilList[index]
	mul $a0 inputBufferOffset CHARACTER_SPACING	# Set x of top left corner of the character to draw in the display
	addi $a0 $a0 TYPING_CORNER_X				# x = (inputBufferOffset * CHARACTER_SPACING) + TYPING_CORNER_X
	li $a1 TYPING_CORNER_Y						# y = TYPING_CORNER_Y
	addi $t1 $t0 STENCIL_SIZE					# Loading ending address of pixel buffer
	drawing_loop:
	lw $a2 ($t0)								# a2 = next color
	addi $t0 $t0 4								# shift t0 to next pixel value
	bgt $t0 $t1 end								# If t0 > t1: end loop
	beq $a2 0xFFFFFF skip_square				# If a2 == pure white --> don't draw and skip square
	beq $a2 0x7F7F7F wrap_around				# If a2 == particular gray --> jump down one line in display
	push($a0)
	push($a1)
	push($t0)									# Store x, y, buffer start, buffer end
	push($t1)
	draw_pixel($a0, $a1, $a2)					# Draw pixel at (x, y) of color a2
	pop($t1)
	pop($t0)
	pop($a1)									# Restore x, y, buffer start, buffer end
	pop($a0)
	skip_square:
	addi $a0 $a0 1								# x++
	j drawing_loop								# Loop
	wrap_around:
	addi $a1 $a1 1								# y++
	mul $a0 inputBufferOffset CHARACTER_SPACING	# Reset x to left side
	addi $a0 $a0 TYPING_CORNER_X
	j drawing_loop								# Loop
	end:
	.end_macro
	
	# Angel
	# Draws a pixel at (x, y) to the display of the given color | x: left to right | y: top to bottom
	# Precondition: %x, %y, %color are immediates or registers of integer values and appropriate hexcodes respectively
	# Postcondition: Display has the color at (x, y)
	.macro draw_pixel(%x, %y, %color) 
	add $a0 $zero %x					# Move %x to a0 to prevent overwrite
	add $a1 $zero %y					# Move %y to a1 to prevent overwrite
	add $a2 $zero %color				# Move %x to a2 to prevent overwrite
	mul $a1 $a1 LINE_SIZE				# a1 if adjusted to align with display length bytes
	mul $a0 $a0 4						# a0 is adjusted to align with word indexing
	add $a0 $a0 $a1						# Display buffer byte index = a0 + a1
	addi $a0 $a0 DISPLAY				# Display buffer index address = display buffer byte index + display address
	sw $a2 ($a0)						# Store color
	.end_macro
	
	# Angel
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

	# Angel
	# Closes a file from a provided descriptor
	# Precondition: %file is a file descriptor provided by syscall 13
	# Postcondition: File is now closed
	.macro close_file(%file)
	li $v0 16
	move $a0 %file
	syscall
	.end_macro
	
	# Angel
	# Display the compiled image from the provided path
	# Precondition: %image is a string path
	# Postcondition: Image is loaded into display buffer
	.macro read_image(%image)
	la $a0 %image			# Load addres to %image buffer
	jal line_by_line_draw	# Jump and link to line_by_line_draw subroutine
	fix_endian()			# Fix the "endianess" of the bytes in the display buffer
	.end_macro
	
	# Angel
	# Fix the "endianess" of the bytes in the display buffer (Not really but too late to rename)
	# Precondition: Image is loaded into display buffer
	# Postcondition: Image actually displays in Bitmap Display
	.macro fix_endian()
	li $t0 DISPLAY						# Set t0 to start of DISPLAY
	addi $t1 $t0 LINE_SIZE				# Set t1 to end of first line of DISPLAY
	li $t2 0							# Set t2 to number of lines read: 0
	fix_endian_loop:
	lw $t3 ($t0)						# Unload and reload the same value onto the buffer
	sw $t3 ($t0)
	addi $t0 $t0 4						# Move t0 to the next pixel
	blt $t0 $t1 fix_endian_loop			# While (t0 < t1): loop
	addi $t1 $t1 LINE_SIZE				# Once t0 reaches the end of the first line, shift t1 over to the next line
	addi $t2 $t2 1						# Add line read to t2
	push($t0)
	push($t1)							# Push t0-2 values onto the stack
	push($t2)
	is_time()							# Check if time to play note
	pop($t2)
	pop($t1)							# Pop t0-2 from the stack
	pop($t0)
	blt $t2 LINE_COUNT fix_endian_loop	# While (t2 < 256): loop
	.end_macro
	
	# Angel
	# Store the string from the info label into the input buffer and display it
	# Precondition: %info_lab holds string of info to display via inputBuffer
	# Postcondition: inputBuffer holds string in %info_lab and inputBufferOffset is set to 0
	.macro display_info(%info_lab)
	la $a0 %info_lab							# a0 holds address of string buffer %info_lab
	la $a1 inputBuffer							# a1 holds address of inputBuffer
	drawing_loop:
	lb $t0 ($a0)
	lower($t0)									# t0: next character of a0 --> lower(t0) --> store t0 in a1
	sb $t0 ($a1)
	beqz $t0 end_draw							# If t0 it null terminator, end loop
	addi $a0 $a0 1								# Shift a0 and a1 over to the next byte
	addi $a1 $a1 1
	push($a0)									# Store a0 and a1 on stack
	push($a1)
	draw_input($t0)								# Draw the input t0
	addi inputBufferOffset inputBufferOffset 1	# Update inputBufferOffset for draw_input
	is_time()									# Check if time to play next note
	pop($a1)									# Restore a0 and a1 from stack
	pop($a0)
	j drawing_loop								# Loop
	end_draw:
	li inputBufferOffset 0						# Set bufferOffset back to 0 (buffer should be empty to type into)
	.end_macro
	
	# Angel
	# Clear top of display which may hold information
	# Precondition: None
	# Postcondition: Character at the top of the display will be erased away
	.macro clear_input()
	li inputBufferOffset INPUT_BUFFER_SPACE		# Set inputBufferOffset to length of inputBuffer
	subi inputBufferOffset inputBufferOffset 1	# Set inputBufferOffset to last address of inputBuffer
	clear_loop:
	backspace()									# Remove the last character from buffer and display
	is_time()									# Check if time to play next note
	bgtz inputBufferOffset clear_loop			# While inputBufferOffset != 0, loop
	.end_macro
	
	# Daniel
	# Remove the last character from the inputBuffer
	# Precondition: inputBuffer holds at least one character and inputBufferOffset is greater than 0
	# Postcondition: inputBuffer's last value is swapped with the null terminator | inputBufferOffset decrements by 1
	.macro backspace()
	subi inputBufferOffset inputBufferOffset 1			# Derement inputBufferOffset 
	li $t0 123											# Load "backspace character" ({ the value after z)
	draw_input($t0)										# Draw a "backspace" by drawing a blue sqaure
	append_char($zero, inputBuffer, inputBufferOffset)	# "Append" the null terminator overwriting the last character
	.end_macro
	
	# Daniel
	# Print the data provided at the path label
	# Precondition: %path_lab holds a portion of the path for the data 
	# Postcondition: Data from the path is printed to the console
	.macro print_data(%path_lab)
	newline()								# Print a newline
	append(dataDirectory, finalPath, 0)		# Append dataDirectory to the start of finalPath
	push($v0)								# Store the number of characters written
	append(%path_lab, finalPath, $v0)		# Append %path_lab to finalPath at offset v0
	pop($v1)								# Restore number of previous characters written to v1
	add $v0 $v0 $v1							# v0 = current number of characters written + previous number
	subi $v0 $v0 1							# Start the offset back one, overwriting the forward slash from %path_lab
	append(dataExtension, finalPath, $v0)	# Append ".txt" to the end of finalPath, overwriting the forward slash
	la $a0 finalPath						# Load address of final path into a0
	file_open_read($a0)						# Open file in read mode
	move $a0 $v0							# Set a0 to file descriptor
	
	li $v0 14								# Read from file
	la $a1 dataBuffer						# Set a1 to the start of the dataBuffer
	li $a2 DATA_BUFFER_SPACE				# Set a2 to the size of the dataBuffer
	syscall									# Read
	
	add $a1 $a1 $v0							# Offset dataBuffer by number of bytes read
	sb $zero ($a1)							# Store the null terminator at the end of the buffer, right after the data
	
	close_file($a0)							# Close the file
	
	is_time()								# Check if time to play next note
	
	li $v0 4
	la $a0 dataBuffer						# Print(dataBuffer)
	syscall
	
	is_time()								# Check if time to play next note
	.end_macro

.text
# Angel
# Read in the file from the given path and store it in a buffer
# Precondition: a0 holds a portion of the file path for the image
# Postcondition: Display holds the image from the file path
line_by_line_draw:
	push($a0)								# Store a0 temporarily
	append(imageDirectory, finalPath, 0)	# Append imageDirectory to start of finalPath
	pop($a0)								# Restore a0
	push($v0)								# Store number of characters written
	append_reg($a0, finalPath, $v0)			# Append a0 to finalPath at last place character were written
	pop($v1)								# Restore original number of characters written
	add $v0 $v0 $v1							# v0 = current number of characters written + previous number
	li $t0 0								# Set t0 to display offset: 0
	li $t1 1								# Set t1 to current line: 1
	push($t0)
	push($t1)								# Store t0, t1, and v0
	push($v0)
line_by_line:
	char($t1, partBuffer)					# Convert t1 to a string and store in partBuffer
	top($v0)								# Get buffer offset
	append(partBuffer, finalPath, $v0)		# Append partBuffer to final path
	top($v1)								# Get previous buffer offset
	add $v0 $v0 $v1							# v0 = current number of characters written + previous number
	append(partExtension, finalPath, $v0)	# Append ".part" extension to finalPath
	la $a0 finalPath						# Load address of final path into a0
	file_open_read($a0)						# Open file in read mode

	move $a0 $v0							# Set a0 to file descriptor

	pop($t2)								# Pop v0 into t2 to prevent syscall overwrite
	pop($t1)								# Restore original t1 and t0
	pop($t0)

	li $v0 14								# Read from file
	la $a1 DISPLAY							# Set a1 to start of Display
	add $a1 $a1 $t0							# Set a1 to be offset by t0
	add $a2 $zero LINE_SIZE					# Set a2 to read in a lines worth of bytes
	syscall									# Read

	add $t0 $t0 $a2							# Update t0 offset to increment by a lines worth of bytes
	addi $t1 $t1 1							# Update t1 current line to next line

	push($t0)
	push($t1)								# Push back new t0 and t1 values, and push back original v0 in t2
	push($t2)

	close_file($a0)							# Close the file

	is_time()								# Check if time to play note
	below_top($t1)							# Get t1 current line
	ble $t1 256 line_by_line				# While current line < 256, loop

	return									# Return

# Daniel
# Return the inedx for the country likely associated with the given input
# Precondition: All countries substring indecies on the stack starting from the beginning and ending on the top
# Postcondition: v0 holds the idex of the location where
get_likely_country:
	overhead(COUNTRY_COUNT)					# Automatically set fp and ra based on our provided arguments
	li $t0 1								# index t0 starts at 1
	li $t1 INPUT_BUFFER_SPACE				# Set a random value to be the highest index (we're searching for the lowest)
	li $v0 -1								# Set v0 to -1 unless a country is found
lowest_index_search:
	bgt $t0 COUNTRY_COUNT end_index_search	# If the index of t0 surpasses the number of countries, end search
	get_arg($t0, $a0)						# Get the argument 1, 2, 3... from the stack and place it into a0
	addi $t0 $t0 1							# Increment the index
	beq $a0 -1 lowest_index_search			# If the argument is -1, the country did not return a substring, loop again
	bgt $a0 $t1 lowest_index_search			# If the substring index is greater than our current max, loop again
	move $t1 $a0							# Store substring index as currrent lowest
	subi $v0 $t0 2							# Store country index into v0
	beqz $a0 end_index_search				# If substring index was 0, the lowest is automatically found, end loop
	j lowest_index_search					# Otherwise keep looping
end_index_search:	
	cleanup(COUNTRY_COUNT)					# Automatically restore fp and ra based on our provided arguments			
	return									# Return
