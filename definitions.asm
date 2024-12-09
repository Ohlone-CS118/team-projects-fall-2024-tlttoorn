# Definitions: Daniel
.data
	# Saved registers used as global variables with specific purpose
	.eqv lastNoteTime $s0		# Last time a note was played
	.eqv nextNoteTime $s1		# Next time a note should be played
	.eqv lastKeyPressed $s2		# Last keypress from the keyboard
	.eqv inputBufferOffset $s3	# Next location to write in the keypress into the input buffer
	
	.eqv currentNote $s5		# Current note of the song
	.eqv sustain $s6			# How long to hold the note
	.eqv nextDoubleMeasure $s7	# Address of the next double measure of the song
	
	.eqv DISPLAY 0x10040000		# Display located at the start of HEAP
	.eqv IMAGE_SIZE 524288		# 512 * 256 * 4 = 524288 bytes needed to display images
	.eqv LINE_SIZE 2048			# 512 * 4 = 2048 bytes to read in for one line of image
	.eqv LINE_COUNT 256			# 256 Lines to read in
	
	.eqv STENCIL_SIZE 440		# 10 * 11 * 4 = 440 bytes needed per stencils
	
	.eqv CHARACTER_SPACING 10	# Pixel distance between the corners of each character
	.eqv TYPING_CORNER_X 1		# Pixel offset from top left corner of display, x
	.eqv TYPING_CORNER_Y 4		# Pixel offset from top left corner of display, y
	
	.eqv INPUT_BUFFER_SPACE 52	# Space given to the input buffer
	.eqv DATA_BUFFER_SPACE 2000	# Space given to the txt files inputs
	
	.eqv COUNTRY_COUNT 18		# Number of countries avaliable to the program
