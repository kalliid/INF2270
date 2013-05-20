	.globl sprinter

#Navn:         sprinter
#C-signature:  int sprinter (unsigned char *res, unsigned char *format, ...);
#Registere:    AL  - tegn som skal flyttes
#	       ECX - til (som økes)
#	       EDX - fra (som økes)
#	       EBX - neste args (som økes)
#	       ESI - temp register

	.data
returnValue:	.long 0
hexBase:	.long 16
decBase:	.long 10
octBase:	.long 8
iCount:		.long 0
iCountDown:	.long 0

sprinter:
	pushl	%ebp		 # Standard
	movl	%esp, %ebp	 # funksjonsstart
	pushl	%ebx		 # ebx er ikke et fritt register
	pushl   %esi		 # esi er ikke et fritt register

	xor	%eax, %eax	 
	xor	%ebx, %ebx
	xor	%ecx, %ecx
	xor	%edx, %edx
	movl	$0, returnValue

	leal	8(%ebp), %ecx	 # ecx = *til (minne addresse)
	movl	(%ecx), %ecx	 # ecx = *ecx (verdi fra minne)
	leal	12(%ebp), %edx   # edx = *fra (minne addresse)
	movl	(%edx), %edx	 # edx = *edx (verdi fra minne)
	leal	16(%ebp), %ebx	 # ebx = neste arg (minne addresse)

startLoop:
	movb	(%edx), %al	# al = *fra
	incl	%edx		# edx++
	cmpb	$37, %al	# al == %
	je	analyzeNext     # if (al == %) true
	movb	%al, (%ecx)     # *til = al
	incl	%ecx		# ecx++
	cmpb	$0, %al		# al == null
	je	return		# if (al == null) true
	incl	returnValue     # returnValue += 1
	jne	startLoop	# if (al != null) true


# after we have detect % and now want to analyze the next character
analyzeNext:
	movb	(%edx), %al	# al = *fra
	incl	%edx		# edx++
	cmpb	$37, %al	# al == %
	je	updatePercent	# if (al == p) true
	cmpb	$100 , %al	# al == d
	je	updateDec	# if (al == d) true
	cmpb	$99, %al	# al == c
	je	updateCharacter # if (al == c) true
	cmpb	$115, %al	# al == s
	je	updateString	# if (al == s) true
	cmpb	$120, %al	# al == x
	je	updateHex	# if (al == x) true
	cmpb	$111, %al	# al == o
	je	updateOct	# if (al == o) true 
	jmp 	illegalOperation


# if the character after % is illegal
illegalOperation:
	cmpb	$32, %al	# al = 32 (space)
	je	startLoop	# if (al == space) startLoop
	incl	%edx		# edx++
	movb	(%edx), %al	# al = *fra
	jmp	illegalOperation
		

updatePercent:
	movb	$37, %al	# al = %
	movb	%al, (%ecx)	# *til = al;
	incl	%ecx		# ecx++
	incl	returnValue     # returnValue += 1
	jmp	startLoop

updateCharacter:
	movb	(%ebx), %al		# al = *ebx (N arg)
	addl	$4, %ebx		# ebx += 4  (neste N arg)
	movb	%al, (%ecx)     	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue     	# returnValue += 1
	jmp	startLoop



#	-- STRING --

# Run once, when we have String
# Since we working with String here, array of pointers
# We have to make sure that we convert pointer to pointer -> value
# char value[0] = **ebx;
# We use esi as a temporary register to hold memory at current char.
updateString:
	movl    (%ebx), %esi		# esi = *ebx (minnne addresse / **)
	addl	$4, %ebx		# ebx += 4  (neste N arg)
	movb	(%esi), %al		# al = *esi (N arg)
	incl	%esi			# esi++
	cmpb	$0, %al			# al == null
	je	startLoop		# if (al == null) return
	movb	%al, (%ecx)		# *til = al
	incl	%ecx			# ecx++
	incl	returnValue	   	# returnValue += 1
	jmp	continueString	

# while( al != null)
continueString:
	movb	(%esi), %al		# al = *esi (N arg)
	incl	%esi			# esi++
	cmpb	$0, %al			# al == null
	je	startLoop		# if (al == null) return
	movb	%al, (%ecx)		# *til = al
	incl	%ecx			# ecx++
	incl	returnValue             # returnValue += 1
	jmp	continueString		# continue the loop


# tool function for HexAndOcatal
poplEDX:
	popl	%edx
	jmp	startLoop


#	-- HEX --

# first operation of Hex (division first value)
updateHex:
	pushl	%edx
	movl	$0, iCount		# make iCount emty for operation
	movl	$0, iCountDown		# make iCountDown empty too
	movl	(%ebx), %eax		# eax = *ebx (N arg) (result)
	addl	$4, %ebx		# ebx += 4  (neste N arg)
	movl	$0, %edx		# edx = 0 (rest)
	divl	hexBase			# division (eax = eax / hexBase)
	jmp	continueHex

# loop to go through whole value and fine all hex
continueHex:
	cmpl	$0, %eax		# result == null
	je	hexLastOne		# if (result == null) true
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of hex
	incl	iCountDown		# update iCount, amount of hex
	movl	$0, %edx		# make edx ready for next division
	divl	hexBase			# eax are ready (eax = eax / hexBase)
	jmp	continueHex		# continue the loop

# update the memory stack and counter for the last hex
hexLastOne:
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of hex
	incl	iCountDown		# update iCount, amount of hex
	jmp	hexFinish		# continue the loop

# ready to print the value as hex to ecx / result array
# make sure here about if the value is integer or character
hexFinish:
	cmpl	$0, iCountDown		# iCountDown == 0
	je	poplEDX			# if (iCountDown == 0) return
	decl	iCountDown		# iCountDown--
	popl	%edx			# get back edx from stack memory
	cmpl	$10, %edx		# edx == 10
	jl	printHexInteger		# if (edx < 10)  printHexInteger
	jge	printHexCharacter	# if (edx >= 10) printHexCharacter


printHexInteger:
	addb	$48, %dl  		# dl += 48 (start from ascii 0)
	movb	%dl, (%ecx)    	 	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	hexFinish 		# continue the loop

printHexCharacter:
	subb	$10, %dl		# al -= 10 (since a - f)
	addb	$97, %dl  		# dl += 97 (start from ascii a)
	movb	%dl, (%ecx)    	 	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	hexFinish 		# continue the loop


#	-- OCT --

# first operation of Oct (division first value)
updateOct:
	pushl	%edx
	movl	$0, iCount		# make iCount emty for operation
	movl	$0, iCountDown		# make iCountDown empty too
	movl	(%ebx), %eax		# eax = *ebx (N arg) (result)
	addl	$4, %ebx		# ebx += 4  (neste N arg)
	movl	$0, %edx		# edx = 0 (rest)
	divl	octBase			# division (eax = eax / octBase)
	jmp	continueOct

# loop to go through whole value and fine all Oct
continueOct:
	cmpl	$0, %eax		# result == null
	je	octLastOne		# if (result == null) true
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of Oct
	incl	iCountDown		# update iCount, amount of Oct
	movl	$0, %edx		# make edx ready for next division
	divl	octBase			# eax are ready (eax = eax / OctBase)
	jmp	continueOct		# continue the loop

# update the memory stack and counter for the last Oct
octLastOne:
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of Oct
	incl	iCountDown		# update iCount, amount of Oct
	jmp	octFinish		# continue the loop

# ready to print the value as Oct to ecx / result array
# make sure here about if the value is integer or character
octFinish:
	cmpl	$0, iCountDown		# iCountDown == 0
	je	poplEDX			# if (iCountDown == 0) return
	decl	iCountDown		# iCountDown--
	popl	%edx			# get back edx from stack memory
	cmpl	$10, %edx		# edx == 10
	jl	printOctInteger		# if (edx < 10)  printOctInteger
	jge	printOctCharacter	# if (edx >= 10) printOctCharacter


printOctInteger:
	addb	$48, %dl  		# dl += 48 (start from ascii 0)
	movb	%dl, (%ecx)    	 	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	octFinish 		# continue the loop

printOctCharacter:
	subb	$10, %dl		# al -= 10 (since a - f)
	addb	$97, %dl  		# dl += 97 (start from ascii a)
	movb	%dl, (%ecx)    	 	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	octFinish 		# continue the loop


#	-- DEC --

# first operation of Dec (division first value)
updateDec:
	pushl	%edx
	movl	$0, iCount		# make iCount emty for operation
	movl	$0, iCountDown		# make iCountDown empty too
	movl	(%ebx), %eax		# eax = *ebx (N arg) (result)
	addl	$4, %ebx		# ebx += 4  (neste N arg)

	pushl	%eax			# save eax before manipulation
	shrl	$31, %eax		# eax = eax >> 31 (unsigned)
	cmpl	$0, %eax		# value = positive or negative
	popl	%eax			# get back the orginal value
	je	decPositive		# if (value >= 0) decPositive
	jne     decNegative		# if (value <  0) decNegative

decPositive:
	movl	$0, %edx		# edx = 0 (rest)
	divl	decBase			# division (eax = eax / DecBase)
	jmp	continueDec

# We convert the negative value with helo of twos complement
# and when we get positive value we put - in the result string
# and continue operation as the value was a positive value
decNegative:
	decl	%eax			# value -= 1
	notl	%eax			# NOT each bit
	movb	$45, (%ecx)     	# *til = 45 (-)
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	decPositive


# loop to go through whole value and fine all Dec
continueDec:
	cmpl	$0, %eax		# result == null
	je	decLastOne		# if (result == null) true
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of Dec
	incl	iCountDown		# update iCount, amount of Dec
	movl	$0, %edx		# make edx ready for next division
	divl	decBase			# eax are ready (eax = eax / DecBase)
	jmp	continueDec		# continue the loop

# update the memory stack and counter for the last Dec
decLastOne:
	pushl	%edx			# save the rest (edx) on the stack
	incl	iCount			# update iCount, amount of Dec
	incl	iCountDown		# update iCount, amount of Dec
	jmp	decFinish		# continue the loop

# ready to print the value as Dec to ecx / result array
# make sure here about if the value is integer or character
decFinish:
	cmpl	$0, iCountDown		# iCountDown == 0
	je	poplEDX			# if (iCountDown == 0) return
	decl	iCountDown		# iCountDown--
	popl	%edx			# get back edx from stack memory
	addb	$48, %dl  		# dl += 48 (start from ascii 0)
	movb	%dl, (%ecx)     	# *til = al
	incl	%ecx			# ecx++
	incl	returnValue		# returnValue++
	jmp	decFinish


#	-- FINISH --

return:
	movl	returnValue, %eax   # eax = returnValue
	popl	%esi	            # hente tilbake esi verdien
	popl	%ebx		    # hente tilbake ebx verdien
	popl	%ebp		    # hente tilbake ebp verdien
	ret
