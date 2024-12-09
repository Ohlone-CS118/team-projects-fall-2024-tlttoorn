# Countries: Daniel
.data
	america: .asciiz "United States of America"	# List of commonly known country names associated with a label
	australia: .asciiz "Australia"
	brazil: .asciiz "Brazil"
	canada: .asciiz "Canada"
	china: .asciiz "China"
	germany: .asciiz "Germany"
	india: .asciiz "India"
	ireland: .asciiz "Ireland"
	jamaica: .asciiz "Jamaica"
	japan: .asciiz "Japan"
	kazakhstan: .asciiz "Kazakhstan"
	mexico: .asciiz "Mexico"
	peru: .asciiz "Peru"
	russia: .asciiz "Russia"
	switzerland: .asciiz "Switzerland"
	thailand: .asciiz "Thailand"
	turkiye: .asciiz "Turkiye"
	uk: .asciiz "United Kingdom"
	# The actual list of the countries, null terminated
	.globl countries
	countries: .word america, australia, brazil, canada, china, germany, india, ireland, jamaica, japan, kazakhstan, mexico, peru, russia, switzerland, thailand, turkiye, uk, 0
