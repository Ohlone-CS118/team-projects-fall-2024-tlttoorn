.include "utils.asm"
.data
	stencilDirectory: .asciiz "stencils/"
	stencilExtension: .asciiz ".stncl"
	.align 2
	letterA: .space STENCIL_SIZE
	letterB: .space STENCIL_SIZE
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
	.globl stencilList
	stencilList: .word letterA, letterB, letterC, letterD, letterE, letterF, letterG, letterH, letterI, letterJ, letterK, letterL, letterM, letterN, letterO, letterP, letterQ, letterR, letterS, letterT, letterU, letterV, letterW, letterX, letterY, letterZ, backspace
	
	.macro read_stencil(%path_lab, %stencil_buffer_reg)
	move $a1 %stencil_buffer_reg
	la $a0 %path_lab
	push($a1)
	file_open_read($a0)
	move $a0 $v0
	top($a1)
	
	li $v0 14
	li $a2 STENCIL_SIZE
	syscall
	
	close_file($a0)
	pop($a1)
	
	fix_stencil($a1)
	is_time()
	.end_macro
	
	.macro fix_stencil(%stencil_buffer_reg)
	move $a0 %stencil_buffer_reg
	fix_endian_loop:
	lw $t0 ($a0)
	sw $t0 ($a0)
	addi $a0 $a0 4
	blt $a0 STENCIL_SIZE fix_endian_loop
	.end_macro

.text

.globl load_letters
load_letters:
	append(stencilDirectory, finalPath, 0)
	li $t0 97
	push($t0)
	push($v0)
	# stack: [t0 current char | v0 path offset]
	load_loop:
	append_char($t0, finalPath, $v0)
	top($v1)
	add $v0 $v0 $v1
	append(stencilExtension, finalPath, $v0)	# File path obtained
	below_top($t0)
	subi $t0 $t0 97
	mul $t0 $t0 4
	la $t1 stencilList
	add $t1 $t1 $t0
	lw $t0 ($t1)								# Get stensil buffer
	read_stencil(finalPath, $t0)
	pop($v0)
	pop($t0)
	addi $t0 $t0 1
	push($t0)
	push($v0)
	ble $t0 123 load_loop
	
	return
