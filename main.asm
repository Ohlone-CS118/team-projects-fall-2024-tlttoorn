# Main: Angel & Daniel
# Inputs: Daniel
.include "utils.asm"


.data
	.globl finalPath
	finalPath: .space 70													# Utilized for directory traversal
	
	inputBuffer: .space INPUT_BUFFER_SPACE									# Utilized for user input
	
	imageDirectory: .asciiz "images/"
	mapDirectory: .asciiz "world_map/"										# Main directory locations
	dataDirectory: .asciiz "data/"
	
	partBuffer: .space 4
	partExtension: .asciiz ".part"											# Used for file extensions and numberings
	dataExtension: .asciiz ".txt"
	
	dataLocation: .space DATA_BUFFER_SPACE									# Preallocated space for txt information
	
	inputInfo: .asciiz "Type in a country or press the esc key to exit"
	returnInfo: .asciiz "Press enter to return or the esc key to exit"		# Information to display at the top as text
	notFoundInfo: .asciiz "Country data not found   Please try again"

.text

.globl main
main:
	move $fp $sp				# Set frame pointer to the top of the stack
	start_music()				# Set up definitions for playing music
	jal load_letters			# Load character stencils
	malloc(IMAGE_SIZE)			# Allocate enough bytes for display on heap
	read_image(mapDirectory)	# read in the map image
	print_data(mapDirectory)
	display_info(inputInfo)		# Display input info as text at the top of display
	enable_keyboard()			# Enable the keyboard
	busy_waiting:
	is_time()							# Check if enough milliseconds have passed for the next note to be played
	bnez lastKeyPressed handle_input	# Check if a key press has occured
	j busy_waiting						# Busy wait
	busy_waiting_but_worse:
	is_time()							# ^^^
	bnez lastKeyPressed return_input
	j busy_waiting_but_worse

# Handles the key press provided by a keyboard interrupt
# Preconditon: lastKeyPressed is not 0
# Postcondition: Depending on the value of lastKeyPressed
#			- ENTER: Search for country | If found display new image, info, and data | Else display not found info
#			- ESC: Exit the program
#			- BACKSPACE: Delete the last input character and clear it from the screen
#			- Alphabet: Add character to the inputBuffer and display the character on the screen
#			- Otherwise ignore the input
handle_input:
	disable_keyboard()					# Disable keyboard to prevent errors
	li $t0 INPUT_BUFFER_SPACE			# Get value before buffer end reserved for the null terminator
	subi $t0 $t0 1
	
	beq lastKeyPressed 10 search				# If enter is pressed search for the country
	beq lastKeyPressed 27 exit_program			# If esc is pressed exit the program
	beq lastKeyPressed 8 backspace				# If backspace is pressed replace buffer value and clear screen
	beq inputBufferOffset $t0 restore_keyboard	# If at the end of buffer, ignore input
	
	lower(lastKeyPressed)						# Lower the key press
	validate_input(lastKeyPressed)				# Validate key entered is a space or an alphabetical character
	beqz lastKeyPressed restore_keyboard		# If not valid, ignore input
	bgtz inputBufferOffset skip_clear			# If it's the first character typed clear info stored in current buffer
	clear_input()								# Clear the buffer and display
skip_clear:
	draw_input(lastKeyPressed)									# Draw the character from the associated stencil
	append_char(lastKeyPressed, inputBuffer, inputBufferOffset)	# Append the character to the end of the input buffer
	addi inputBufferOffset inputBufferOffset 1					# Update buffer offset
	
	j restore_keyboard							# remove register stored character and re-enable the keyboard

backspace:
	beqz inputBufferOffset restore_keyboard		# If input buffer is already empty, ignore input
	backspace()									# Remove last input using backspace macro
	beqz inputBufferOffset restore_info			# If input buffer has now become empty, display useful info on display
	
	j restore_keyboard							# remove register stored character and re-enable the keyboard
	
search:
	beqz inputBufferOffset restore_keyboard		# If the input buffer is empty, ignore search
	la $t0 inputBuffer							# Get input buffer address
	add $t0 $t0 inputBufferOffset				# Get end of input buffer
	sb $zero ($t0)								# Null terminator goes at the end
	
	la $t0 inputBuffer							# Get start of input buffer
	la $t1 countries							# Get list of strings of country names
	search_loop:
	lw $t2 ($t1)								# Get next country (start i = 0)
	beqz $t2 end_search							# If null terminator found, end of list, terminate search
	push($t1)
	push($t0)									# Store input, list, and string address on stack
	push($t2)
	is_time()									# Check for impending note
	top($t2)
	below_top($t0)								# Restore input buffer and string addresses
	strstr($t2, $t0)							# Find the substring, input buffer, in the string, country name
	pop($t2)
	pop($t0)									# Restore input, list, and string address to registers
	pop($t1)
	push($v0)									# Push the index at which the substring was found (-1 if not)
	addi $t1 $t1 4								# Get next country name address, i++
	j search_loop								# Continue search loop
	
	end_search:
	jal get_likely_country						# Get the name of the country with the earliest returned substring
	beq $v0 -1 country_not_found				# If none found, display not found info and clear the buffer
	mul $v0 $v0 4								# Get the index for the country name in the country list
	destroy(COUNTRY_COUNT)						# Destroy all pushed arguments
	la $t0 countries
	add $t0 $t0 $v0
	lw $t0 ($t0)								# Access country name with index (country list[i])
	push($t0)									# Push name address onto stack
	clear_input()								# Clear input buffer
	pop($t0)									# Pop name address off stack
	directory_conversion($t0, inputBuffer)		# Get the directory of the country and store it in the input buffer
	read_image(inputBuffer)						# Read in the country image file
	is_time()									# Check if time to play next note
	print_data(inputBuffer)						# Print associated country data to console
	display_info(returnInfo)					# Display useful info at the top of the image
	move lastKeyPressed $zero					# Clear last key press
	enable_keyboard()							# Renable the keyboard
	j busy_waiting_but_worse					# Enter new restricted loop

country_not_found:
	clear_input()								# If country not found clear buffer input
	display_info(notFoundInfo)					# Display not found information at the top of the display
	j restore_keyboard							# remove register stored character and re-enable the keyboard

# A modified version of handle input specifically for returning to the world map and restricting input
# Preconditon: lastKeyPressed is ESC or ENTER
# Postcondition: ESC closes the program and ENTER return back to the world map / main screen
return_input:
	disable_keyboard()							# While in the restricted loop disable the keyboard to prevent errors
	
	beq lastKeyPressed 27 exit_program			# If esc is pressed exit the program
	beq lastKeyPressed 10 restore_map			# If enter is pressed restore world map image
	move lastKeyPressed $zero					# Ignore input and restore keyboard otherwise
	enable_keyboard()
	j busy_waiting_but_worse					# Return to restricted loop

# Restores different parts of the mainscreen depending on which label level was accessed
# Precondition: None
# Postcondition: By biggest change: Reload map and map data, Display Map info, Reset key press and enable keyboard
restore_map:	
	read_image(mapDirectory)					# Redraw world map image
	print_data(mapDirectory)
restore_info:
	display_info(inputInfo)						# Display input information at the top of display
restore_keyboard:
	move lastKeyPressed $zero
	enable_keyboard()							# Remove register stored character and re-enable the keyboard
	j busy_waiting

exit_program:
	exit										# Exit the program

# All but modified __keyboard_interrupt below is courtesey of Karl Marklund
.kdata
	UNHANDLED_EXCEPTION:	.asciiz "===>      Unhandled exception       <===\n\n"
	UNHANDLED_INTERRUPT: 	.asciiz "===>      Unhandled interrupt       <===\n\n"
	OVERFLOW_EXCEPTION: 	.asciiz "===>      Arithmetic overflow       <===\n\n" 
	TRAP_EXCEPTION: 		.asciiz "===>         Trap exception         <===\n\n"
	BAD_ADDRESS_EXCEPTION: 	.asciiz "===>   Bad data address exception   <===\n\n"
.ktext 0x80000180
__kernel_entry_point:

	mfc0 $k0, $13			# Get value in cause register.
	andi $k1, $k0, 0x00007c	# Mask all but the exception code (bits 2 - 6) to zero.
	srl  $k1, $k1, 2		# Shift two bits to the right to get the exception code. 
	
	# Now $k0 = value of cause register
	#     $k1 = exception code 
	
	# The exception code is zero for an interrupt and none zero for all exceptions. 
	
	beqz $k1, __interrupt 	# branch is interrupt

__exception:

	# Branch on value of the the exception code in $k1. 
	
	beq $k1, 12, __overflow_exception	# branch is overflow code 12
	
	beq $k1, 4, __bad_address_exception #branch to label __bad_address_exception for exception code 4. 	
	
	beq $k1, 13, __trap_exception 		#branch to label __trap_exception for exception code 13. 
	
__unhandled_exception: 
    	
	li $v0, 4		# Print the unhandled exception notice
	la $a0, UNHANDLED_EXCEPTION
	syscall
 
 	exit
	
__overflow_exception:
	
	li $v0, 4		# Print the overflow exception notice
	la $a0, OVERFLOW_EXCEPTION
	syscall

	exit

 __bad_address_exception:
	
	li $v0, 4		# Print the bad address exception notice
	la $a0, BAD_ADDRESS_EXCEPTION
	syscall
 
 	exit
 
__trap_exception: 
	
	li $v0, 4		# Print the bad trap notice
	la $a0, TRAP_EXCEPTION
	syscall
 
 	exit

__interrupt: 

	# Value of cause register should already be in $k0. 
    	
    	andi $k1, $k0, 0x00000100	# Mask all but bit 8 (interrupt pending) to zero. 
    	
    	# Shift 8 bits to the right to get the inerrupt pending bit as the 
    	# least significant bit. 
    	srl  $k1, $k1, 8
    	
    	beq  $k1, 1, __keyboard_interrupt	# Branch on the interrupt pedning bit. 

__unhandled_interrupt: 
   
  	#  Use the MARS built-in system call 4 (print string) to print error messsage.
	
	li $v0, 4		# Print the unhandled Interupt notice
	la $a0, UNHANDLED_INTERRUPT
	syscall
 
 	exit

__keyboard_interrupt:     	
	
	# Get ASCII value of pressed key from the memory mapped receiver data register. 

	lw $k1, 0xffff0004  # Store content of the memory mapped receiver data register in $k1.

	# Use the MARS built-in system call 11 (print char) to print the character
	# from receiver data.
	
	move lastKeyPressed $k1
	
	j __resume
	

__resume_from_exception: 
	
	# When an exception or interrupt occurs, the value of the program counter 
	# ($pc) of the user level program is automatically stored in the exception 
	# program counter (ECP), the $14 in Coprocessor 0. 

        # Get value of EPC (Address of instruction causing the exception).
       
        mfc0 $k0, $14
        
        # Skip offending instruction by adding 4 to the value stored in EPC. 
        # Otherwise the same instruction would be executed again causing the same 
        # exception again.
        
        addi $k0, $k0, 4 	# Skip offending instruction by adding 4 to the value stored in EPC.     
        
        mtc0 $k0, $14		# Update EPC in coprocessor 0.
        
__resume:
            
	# Use the eret (Exception RETurn) instruction to set the program counter
	# (PC) to the value saved in the ECP register (register 14 in coporcessor 0).
	
	eret # Look at the value of $14 in Coprocessor 0 before single stepping.
