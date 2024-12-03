.data
	.eqv lastNoteTime $s0
	.eqv nextNoteTime $s1
	.eqv lastKeyPressed $s2
	.eqv inputBufferOffset $s3
	
	.eqv currentNote $s5
	.eqv sustain $s6
	.eqv nextDoubleMeasure $s7
	
	.eqv DISPLAY 0x10040000	# Display located at the start of HEAP
	.eqv IMAGE_SIZE 524288
	.eqv LINE_SIZE 2048
	.eqv LINE_COUNT 256
	.eqv STENCIL_SIZE 440
	.eqv TYPING_CORNER_X 8
	.eqv TYPING_CORNER_Y 4
	.eqv INPUT_BUFFER_SPACE 32
	.eqv COUNTRY_COUNT 18
