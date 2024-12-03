.include "utils.asm"
.data
# 3/4
# 114 BPM
# 1/4: 526 ms
# 1/8: 263 ms
# 1/6: 132 ms
# Invariables:
# 263 between each note
# Sustain is constant with one exception
	music1: .word 44 263, 51 263, 56 263, 60 263, 62 263, 67 263, 84 0, 91 0, 44 263, 51 263, 56 263, 60 263, 62 263, 67 263, 0
	music2: .word 44 263, 51 263, 63 0, 56 263, 58 263, 75 0, 60 263, 63 263, 74 0, 44 263, 51 263, 56 263, 72 0, 58 263, 70 0, 60 263, 68 0, 63 263, 0
	music3: .word 72 0, 44 263, 51 263, 56 263, 58 263, 60 263, 63 263, 63 0, 44 263, 51 263, 56 263, 58 263, 60 263, 63 263, 0
	music4: .word 72 0, 42 263, 51 263, 56 263, 58 263, 60 263, 63 263, 42 263, 51 263, 56 263, 58 263, 60 263, 63 263, 0
	music5: .word 40 263, 47 263, 63 0, 52 263, 54 263, 75 0, 56 263, 59 263, 73 0, 42 263, 49 263, 54 263, 72 0, 56 263, 70 0, 58 263, 73 0, 61 263, 0
	music6: .word 72 0, 44 263, 51 263, 63 0, 56 263, 58 263, 68 0, 60 263, 63 263, 70 0, 68 263, 67 263, 72 0, 63 263, 60 263, 74 0, 56 263, 55 263, 0
	music7: .word 44 263, 51 263, 63 0, 75 0, 56 263, 58 263, 75 0, 87 0, 60 263, 63 263, 74 0, 80 0, 84 0, 86 0, 44 263, 51 263, 56 263, 72 0, 84 0, 58 263, 70 0, 82 0, 60 263, 68 0, 80 0, 63 263, 0
	music8: .word 72 0, 80 0, 84 0, 44 263, 51 263, 56 263, 58 263, 60 263, 63 263, 63 0, 72 0, 75 0, 44 263, 51 263, 56 263, 58 263, 60 263, 63 263, 0
	music9: .word 72 0, 80 0, 84 0, 42 263, 51 263, 87 0, 56 263, 58 263, 99 0, 60 263, 63 263, 97 0, 42 263, 51 263, 56 263, 96 0, 58 263, 94 0, 60 263, 92 0, 63 263, 0
	altered7: .word 96 0, 44 263, 51 263, 63 0, 75 0, 56 263, 58 263, 75 0, 87 0, 60 263, 63 263, 74 0, 80 0, 84 0, 86 0, 44 263, 51 263, 56 263, 72 0, 84 0, 58 263, 70 0, 82 0, 60 263, 68 0, 80 0, 63 263, 0
	music10: .word 40 263, 47 263, 63 0, 71 0, 75 0, 52 263, 54 263, 75 0, 83 0, 87 0, 56 263, 59 263, 73 0, 82 0, 85 0, 42 263, 49 263, 54 263, 72 0, 80 0, 84 0, 56 263, 70 0, 78 0, 82 0, 58 263, 73 0, 82 0, 85 0, 61 263, 0
	music11: .word 72 0, 80 0, 84 0, 44 263, 51 263, 56 263, 58 263, 70 0, 60 263, 63 263, 72 0, 68 263, 67 263, 63 263, 60 263, 75 0, 56 263, 58 0, 55 263, 0
	music12: .word 73 0, 80 0, 57 263, 73 0, 80 0, 64 263, 73 0, 80 0, 66 263, 68 263, 66 263, 64 263, 57 263, 64 263, 80 0, 85 0, 66 263, 68 263, 66 263, 78 0, 83 0, 64 263, 0
	music13: .word 80 0, 85 0, 88 0, 57 263, 80 0, 85 0, 64 263, 80 0, 85 0, 66 263, 68 263, 66 263, 64 263, 57 263, 64 263, 83 0, 88 0, 66 263, 68 263, 66 263, 82 0, 87 0, 64 263, 0
	music14: .word 78 0, 83 0, 90 0, 59 263, 78 0, 83 0, 66 263, 78 0, 83 0, 68 263, 70 263, 68 263, 66 263, 59 263, 66 263, 85 0, 90 0, 68 263, 70 263, 68 263, 83 0, 88 0, 66 263, 0
	music15: .word 82 0, 87 0, 94 0, 59 263, 82 0, 87 0, 66 263, 82 0, 87 0, 68 263, 70 263, 68 263, 66 263, 75 0, 80 0, 59 263, 66 263, 68 263, 70 263, 73 0, 78 0, 68 263, 66 263, 0
	music16: .word 82 0, 87 0, 94 0, 59 263, 82 0, 87 0, 66 263, 82 0, 87 0, 68 263, 70 263, 68 263, 66 263, 56 263, 63 263, 78 0, 82 0, 85 0, 66 263, 63 263, 75 0, 78 0, 82 0, 61 263, 58 263, 0
	music17: .word 49 263, 56 263, 68 0, 80 0, 63 263, 65 263, 80 0, 92 0, 72 263, 73 263, 79 0, 91 0, 49 263, 56 263, 63 263, 77 0, 89 0, 65 263, 75 0, 87 0, 68 263, 85 0, 73 263, 0
	music18: .word 75 0, 87 0, 51 263, 58 132, 67 131, 70 0, 63 263, 65 132, 70 131, 75 0, 67 263, 70 132, 75 131, 70 0, 79 0, 82 0, 51 263, 58 132, 79 131, 82 0, 63 263, 65 263, 67 263, 70 263, 0
	music19: .word 75 0, 87 0, 51 263, 58 263, 70 0, 77 0, 63 263, 65 263, 75 0, 79 0, 67 263, 70 263, 77 0, 82 0, 51 263, 58 263, 79 0, 82 0, 87 0, 63 263, 65 263, 82 0, 87 0, 89 0, 67 263, 70 263, 0
	music20: .word 82 0, 86 0, 91 526, 86 0, 89 0, 91 0, 94 526, 82 0, 86 0, 91 526, 79 0, 82 0, 86 526, 74 0, 79 0, 82 526, 70 0, 74 0, 79 526, 0
	musicSheet: .word music1, music1, music2, music3, music2, music4, music2, music3, music5, music6, music7, music8, music7, music9, altered7, music8, music10, music11, music12, music13, music14, music15, music12, music13, music14, music16, music17, music18, music17, music19, music20, 0

	.eqv MEASURE 1678	# 3 quarter notes + 100ms
	.eqv VOLUME 80		# Set the base value for the volume
	
.text

.globl music_setup
music_setup:
	la nextDoubleMeasure musicSheet

.globl double_measure_setup
double_measure_setup:
	lw currentNote (nextDoubleMeasure)	# Load start of music
	beqz currentNote music_setup
	addi nextDoubleMeasure nextDoubleMeasure 4
	li sustain MEASURE
	
	return
.globl queue_note
queue_note:
	syscall
	sub $a0 $a0 lastNoteTime
	blt $a0 nextNoteTime queue_note

.globl note_setup
note_setup:
	set_time()
	lw $a0 (currentNote)			# Load the note

	lw nextNoteTime 4(currentNote)	# Load the time till next note

	addi currentNote currentNote 8	# Point to next note
get_volume:
	slti $t0 nextNoteTime 263
	move $t1 $t0
	mul $t0 $t0 20
	addi $a3 $t0 VOLUME
	mul $t1 $t1 -27
	addi $a2 $t1 32
get_instrument_and_duration:			# Last tested: 35
	move $a1 sustain					# Harmony | 3 5
	# li $a2 3							# Load instrument | 9 24 [32] 55 85 102 (118) 123
play_note:
	li $v0 31							# Load midi play
	syscall

	beqz nextNoteTime note_setup		# If there is no delay for next note, skip sleep call
	
	sub sustain sustain nextNoteTime	# Remove that from time restarting in the measure

	ble sustain 100 reset_measure

	return

reset_measure:
	lw $t0 (currentNote)
	beqz $t0 double_measure_setup
	
	li sustain MEASURE

	return
