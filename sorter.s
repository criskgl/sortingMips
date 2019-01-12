.data
	vector: .word 7,2,1,4,3,9,12,15,17,54,16,90,38,34,49,69  #Unsorted
	#vector: .word 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16     #Sorted
	k: .word 3
	
	#----------------Auxiliary messages-------------
	vectorBeforeMessage: .asciiz "vector Before: \n"
	vectorAfterMessage: .asciiz  "vector  After: \n"
	arraySortedMessage: .asciiz "\nArray has been succesfully sorted!!\n"
	newLine: .asciiz "\n"
	sortingMessage: .asciiz "\nSorting...\n"
	comaSeparator: .asciiz ", "
.text
	.globl main
	main:
	
	#Now we need to save somewhere, lets say t7 the address of the start of "vector"
	la $t7, vector
	#print our vector BEFORE swapping
	li $v0, 4
	la $a0, vectorBeforeMessage
	syscall 
	move $a0, $t7 #address of vector
	addi $a1, $zero, 64 #Size  in bytes of vector
	jal printArray
	
	#Sorting starts
	li $v0, 4
	la $a0, sortingMessage
	syscall
	
	#start call to function
	la $a0, vector
	addi $a1, $zero, 64
	jal sortArray
	
	
	la $t7, vector
	#print our vector AFTER sorting
	li $v0, 4
	la $a0, vectorAfterMessage
	syscall 
	move $a0, $t7 #address of vector
	addi $a1, $zero, 0 #cleaning...
	addi $a1, $zero, 64 #Size  in bytes of vector
	jal printArray
	
	
	
	#EXIT
	li $v0, 10
	syscall
	
	#----------//////PROCEDURES DOWN\\\\\\\-----------#
	
	#PROCEDURE >> Swaps values of two locations in the memory
	#Arguments $a0: memory start address
	#          $a1: offset to a0 
	swap:  sll $t1, $a1, 2   # t1 = a1 * 2^(2) ==> t1 = a1 * 4
               add $t1, $a0, $t1 # t1 = a0 + (a1 * 4)
               lw  $t0, 0($t1)   # t0 = contents of memory address [a0 + (a1 * 4)]
               lw  $t2, 4($t1)   # t2 = contents of memory address [a0 + (a1 * 4) + 4]
               sw  $t2, 0($t1)   # contents in memory address [a0 + (a1 * 4)] = contents of memory address [a0 + (a1 * 4)]
               sw  $t0, 4($t1)   # contents in memory address [a0 + (a1 * 4) + 4] = contets of memory address [a0 + (a1 * 4) + 4]
               jr $ra
        
        
        #PROCEDURE >> Prints contents of contigious words in memory given an offset memory adress 
        #
        #Arguments: $a0: Memory address or label
        #	    $a1: Size of array in Bytes
        printArray:
        	addi $t9, $zero, 0
        	add $t3, $zero, $a0# t3 = memory address
        	add $t4, $zero, $a1# t4 = maximum size of array
        	
        	printArrayWhile:
        		beq $t9, $t4, printArrayWhileExit # counter == maxSize? 
        		
        		lw $t2, ($t3) # t2 = current array value
        		#printing
        		li $v0, 1
        		add $a0, $zero, $t2
        		syscall 
        		#printing
        		li $v0, 4
        		la $a0, comaSeparator
        		syscall
        		
        		#step +4 bytes
        		addi $t9, $t9, 4
        		addi $t3, $t3, 4
        				
        		j printArrayWhile
        	printArrayWhileExit:
        		jr $ra

	#PROCEDURE >> sorts contents of contigious 4 byte integers given a 
	#	      starting memory address
	#	      and lenght of sequence of numbers
        #
        #Arguments: $a0: Memory address or label
        #	    $a1: Size of array in Bytes
        sortArray:
        	
        	addi $sp, $sp, -8 #reserving 8 bytes space in stack
		sw $ra, 4($sp) #save the RETURN ADDRESS stores to the first location 
			       #starting in the position where sp is pointing at
        	add $t7, $zero, $a0 # t7 = memory address
        	sw $t7, ($sp) #safely save in stack  memory address to acces later
        	add $t8, $zero, $a1 # t8 = size vector	
        	addi $t6, $t8, -4   # t6 = size vector - 1
        	
        	#Check if array is sorted before sorting
        	add $a0, $zero, $t7
        	add $a1, $zero, $t8
        	jal checkIfArraySorted
        	
        	beq $v0, $zero, sortArrayGoThroughArray
        	beq $v0, 1, arrayIsSorted
        	
        	
        	addi $t9, $zero, 0# k:counter (increments step by 4)
        	addi $t5, $zero, 0# j: counter (increments step by 1)
        	
        	sortArrayGoThroughArray:
        		
        		beq $t9, $t6, sortArrayCheckIfSorted
        			
        			
        			lw $s0, ($t7) # s0 = vector[k]
        			lw $s1, 4($t7)# s1 = vector[k+1]
        			
        			bgt $s0, $s1, sortArraySwapElements #if elements vector[k] & vector[k + 1] are not in order
        			bgt $s1, $s0, sortArrayGoThroughArrayOrderOk
        			
        			sortArrayGoThroughArrayOrderOk:
        			
        				addi $t9, $t9, 4
        				addi $t5, $t5, 1
        				addi $t7, $t7, 4
        				j sortArrayGoThroughArray
        				       	
        					
        			sortArraySwapElements:
        				
        				lw  $a0, ($sp)      #arg1 = address
        				add $a1, $t5, $zero #arg2 = offset
        				jal swap
        				#step counters
        				addi $t9, $t9, 4
        				addi $t5, $t5, 1
        				#step memory address
        				addi $t7, $t7, 4
        				j sortArrayGoThroughArray
        				
        					
        	sortArrayCheckIfSorted:
        	
        		lw $s2, ($sp)
        		add $a0, $s2, $zero 
        		add $a1, $t8, $zero
        		jal checkIfArraySorted
        		beq $v0, $zero, sortArrayReinitialize#if not sorted go through array again
        		j arrayIsSorted
        		
        	sortArrayReinitialize:
        		addi $t9, $zero, 0
        		addi $t5, $zero, 0
        		lw $t7, ($sp)
        		j sortArrayGoThroughArray
        	
        	arrayIsSorted:
        		#print success message
        		li $v0, 4
        		la $a0, arraySortedMessage
        		syscall
        		#RESTORATION PROCESS 
			lw $ra, 4($sp)      #for main return address
			addi $sp, $zero, 8 #RESTORE old position of sp		
			jr $ra
        	
     
        		
        #PROCEDURE >> checks if elements of array are 
        #	      sorted from lowest to highest
        #
        #Arguments: $a0: Memory address or label
        #	    $a1: Size of array in Bytes	
        #
        #Return:    $v0 = 1 if sorted
        #	    $v0 = 0 if not sorted
       	checkIfArraySorted:
       		addi $t1, $zero, 1 # Sorted? >> t1 = true = 1
       		add $t7, $zero, $a0 # t7 = memory address
       		add $t8, $zero, $a1 # t8 = size of array
       		addi $t8, $t8, -4
       				addi $t9, $zero, 0 # K: counter t9 = 0
       				checkIfArraySortedWhile:
       					beq $t9, $t8, checkIfArraySortedWhileEnd
       						lw $t2, ($t7) # t2 = array[i]
       						addi $t3, $t7, 4
       						lw $t4, ($t3) # t4 = array[i+1]
       						
       						
       						bgt $t2, $t4, valuesUnsorted # array[i] > array[i+1]?
       						bgt $t4, $t2, valuesSorted
       						valuesUnsorted:
       							addi $t1, $zero, 0 # Sorted >> t1 = false = 0
       							addi $v0, $zero, 0 # return value = t1      							
       							jr $ra
       						valuesSorted:
       						#STEP + 4 Bytes
       						addi $t7, $t7, 4
       						addi $t9, $t9, 4
       						j checkIfArraySortedWhile
       				checkIfArraySortedWhileEnd:
       						add $v0, $zero, $t1
       						jr $ra
       				
       										
       						 
       		
        	
        	