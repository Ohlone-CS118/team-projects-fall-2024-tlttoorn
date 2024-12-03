.include "utils.asm"
# TODO
# Load in stensil functions
# Better substring search to return the country with the earliest occurence of a specific index
# Print country strings


.data
	inputBuffer: .space INPUT_BUFFER_SPACE
	imageDirectory: .asciiz "images/"
	partBuffer: .space 4
	partExtension: .asciiz ".part"
	.globl finalPath
	finalPath: .space 50
	mapDirectory: .asciiz "world_map/"
	removed: .asciiz "removed"
	input_info: .asciiz "Enter a country or press escape"
	return_info: .asciiz "Press enter to return"

.text

.globl main
main:
	move $fp $sp
	start_music()
	jal load_letters
	set_time()
	malloc(IMAGE_SIZE)
	read_image(mapDirectory)
	enable_keyboard()
	busy_waiting:
	is_time()
	bnez lastKeyPressed handle_input
	j busy_waiting

handle_input:
	disable_keyboard()
	beq lastKeyPressed 8 backspace
	beq lastKeyPressed 10 search
	beq lastKeyPressed 27 exit_program
	beq inputBufferOffset INPUT_BUFFER_SPACE restore_keyboard
	lower(lastKeyPressed)
	validate_input(lastKeyPressed)
	beqz lastKeyPressed restore_keyboard
	append_char(lastKeyPressed, inputBuffer, inputBufferOffset)
	addi inputBufferOffset inputBufferOffset 1
	draw_input(lastKeyPressed)
	
	li $v0 11
	move $a0 lastKeyPressed
	syscall
	
	j restore_keyboard
	
backspace:
	beqz inputBufferOffset restore_keyboard
	li $t0 123
	draw_input($t0)
	subi inputBufferOffset inputBufferOffset 1
	append_char($zero, inputBuffer, inputBufferOffset)
	
	li $v0 4
	la $a0 removed
	syscall
	
	j restore_keyboard
	
search:
	la $t0 inputBuffer
	add $t0 $t0 inputBufferOffset
	sb $zero ($t0)
	
	la $t0 inputBuffer
	la $t1 countries
	search_loop:
	lw $t2 ($t1)	# Get next country
	beqz $t2 end_search
	push($t1)
	push($t0)
	push($t2)
	is_time()
	top($t2)
	below_top($t0)
	strstr($t2, $t0)
	pop($t2)
	pop($t0)
	pop($t1)
	push($v0)
	addi $t1 $t1 4
	j search_loop
	
	end_search:
	jal get_likely_country
	beq $v0 -1 restore_keyboard
	mul $v0 $v0 4
	destroy(COUNTRY_COUNT)
	la $t0 countries
	add $t0 $t0 $v0
	lw $t0 ($t0)
	directory_conversion($t0, inputBuffer)
	read_image(inputBuffer)
	j restore_keyboard

restore_keyboard:
	move lastKeyPressed $zero
	enable_keyboard()
	j busy_waiting

exit_program:
	exit

.kdata
	UNHANDLED_EXCEPTION:	.asciiz "===>      Unhandled exception       <===\n\n"
	UNHANDLED_INTERRUPT: 	.asciiz "===>      Unhandled interrupt       <===\n\n"
	OVERFLOW_EXCEPTION: 	.asciiz "===>      Arithmetic overflow       <===\n\n" 
	TRAP_EXCEPTION: 		.asciiz "===>         Trap exception         <===\n\n"
	BAD_ADDRESS_EXCEPTION: 	.asciiz "===>   Bad data address exception   <===\n\n"
.ktext 0x80000180
__kernel_entry_point:

	mfc0 $k0, $13		# Get value in cause register.
	andi $k1, $k0, 0x00007c	# Mask all but the exception code (bits 2 - 6) to zero.
	srl  $k1, $k1, 2	# Shift two bits to the right to get the exception code. 
	
	# Now $k0 = value of cause register
	#     $k1 = exception code 
	
	# The exception code is zero for an interrupt and none zero for all exceptions. 
	
	beqz $k1, __interrupt 	# branch is interrupt

__exception:

	# Branch on value of the the exception code in $k1. 
	
	beq $k1, 12, __overflow_exception	# branch is overflow code 12
	
	beq $k1, 4, __bad_address_exception 	#branch to label __bad_address_exception for exception code 4. 	
	
	beq $k1, 13, __trap_exception 	#branch to label __trap_exception for exception code 13. 
	
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
