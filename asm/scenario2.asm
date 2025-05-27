.text
# address mapping:
# 0xfffffc00 16 switches
# 0xfffffc10 upper 8 switches
# 0xfffffc20 test case button 
# 0xfffffc24 exit button 
# 0xfffffc28 input a button 
# 0xfffffc2c input b button 
# 0xfffffc30 all 16 leds
# 0xfffffc40 left 8 leds
# 0xfffffc50 right 8 leds
# 0xfffffc60  tube

addi s11, zero, 1 
WaitForSystemReset:
    lw s0, 0xfffffc24(zero)     
    bne s0, s11, WaitForSystemReset
    sw zero, 0xfffffc30(zero) 
    sw zero, 0xfffffc60(zero) 
    
ReadTestCaseSelection:
    lw s1, 0xfffffc10(zero) 
    lw s0, 0xfffffc20(zero)     
    bne s0, s11, ReadTestCaseSelection
    sw s1, 0xfffffc60(zero)

    addi s10, zero, 0
    beq s1, s10, ExecuteBitReversalTest
    addi s10, zero, 1
    beq s1, s10, ExecutePalindromeTest
    addi s10, zero, 2
    beq s1, s10, ExecuteFloatingPointInputTest
    addi s10, zero, 3
    beq s1, s10, ExecuteFloatingPointAdditionTest
    addi s10, zero, 4
    beq s1, s10, ExecuteCrcGenerationTest
    addi s10, zero, 5
    beq s1, s10, ExecuteCrcVerificationTest
    addi s10, zero, 6
    beq s1, s10, ExecuteLoadUpperImmediateTest
    addi s10, zero, 7
    beq s1, s10, ExecuteJumpInstructionTest
    addi s10, zero, 8
    beq s1, s10, BonusAuipc
    addi s10, zero, 9
    beq s1, s10, SimpleJalJalr
    j ReadTestCaseSelection 

# test case 000: reversing bits in 8-bit number
ExecuteBitReversalTest:
WaitForBitReversalInput:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, WaitForBitReversalInput
    
    # implementing bit reversal algorithm
    addi s3, zero, 0  # initializing result
    addi s4, zero, 8 # bit counter
    
ProcessEachBitForReversal:
    beq s4, zero, FinishBitReversal
    slli s3, s3, 1 # shifting result left
    andi s5, s2, 1   # extracting lsb from input
    or s3, s3, s5   # adding lsb to result
    srli s2, s2, 1   # shifting input right
    addi s4, s4, -1  # decrementing counter
    j ProcessEachBitForReversal
    
FinishBitReversal:
    sw s3, 0xfffffc40(zero)  # displaying reversed result
    j WaitForSystemReset

# test case 001: checking binary palindrome
ExecutePalindromeTest:
WaitForPalindromeInput:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, WaitForPalindromeInput
    
    # comparing with reversed version to check palindrome
    andi s6, s2, 255  # preserving original number
    andi s2, s2, 255  # ensuring 8-bit input
    addi s3, zero, 0 # initializing result
    addi s4, zero, 8 # bit counter
    
CreateReversedVersionForComparison:
    beq s4, zero, CheckIfPalindrome
    slli s3, s3, 1              
    andi s5, s2, 1              
    or s3, s3, s5               
    srli s2, s2, 1              
    addi s4, s4, -1             
    j CreateReversedVersionForComparison
    
CheckIfPalindrome:
    andi s3, s3, 255            
    beq s6, s3, IndicatePalindromeFound
    sw zero, 0xfffffc30(zero) # not a palindrome
    j WaitForSystemReset
    
IndicatePalindromeFound:
    addi s7, zero, 1
    sw s7, 0xfffffc30(zero) # is palindrome
    j WaitForSystemReset

# test case 010: ieee754 12-bit floating point input with negative support
ExecuteFloatingPointInputTest:
    # reading first floating point number
ReadFirstFloatingPointNumber:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, ReadFirstFloatingPointNumber
    
    slli s2, s2, 4  # making space for lower 4 bits
    sw s2, 8(zero)   # storing first number in memory
    
    jal ra, ConvertFloatingPointToSignedInteger
    addi a0, s6, 0              
    jal ra, ConvertSignedIntegerToDecimalDisplay
    sw a1, 0xfffffc60(zero) # displaying result
    
    srli s7, s6, 31  # extracting sign bit
    sw s7, 0xfffffc30(zero)  # showing sign on leds
    
    # reading second floating point number
ReadSecondFloatingPointNumber:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc2c(zero)     
    bne s0, s11, ReadSecondFloatingPointNumber
    
    slli s2, s2, 4              
    sw s2, 12(zero) # storing second number in memory
    
    jal ra, ConvertFloatingPointToSignedInteger
    addi a0, s6, 0              
    jal ra, ConvertSignedIntegerToDecimalDisplay
    sw a1, 0xfffffc60(zero)     
    
    srli s7, s6, 31             
    sw s7, 0xfffffc30(zero)     
    j WaitForSystemReset

# test case 011: adding two ieee754 12-bit floating point numbers
ExecuteFloatingPointAdditionTest:
    lw s2, 8(zero) # loading first number from memory
    lw s3, 12(zero)  # loading second number from memory
    
    sw s2, 0xfffffc40(zero) # showing first number on left leds
    sw s3, 0xfffffc50(zero)  # showing second number on right leds
    
    # extracting components of first number
    srli t0, s2, 11
    andi t0, t0, 1  # sign of first number
    srli t1, s2, 8  
    andi t1, t1, 7 #exponent of first number
    srli t2, s2, 4
    andi t2, t2, 15  # mantissa of first number
    
    # extracting components of second number
    srli t3, s3, 11
    andi t3, t3, 1 # sign of second number
    srli t4, s3, 8
    andi t4, t4, 7 # exponent of second number
    srli t5, s3, 4  
    andi t5, t5, 15 # mantissa of second number
    
    # converting first number: value = (-1)^sign * 2^(exp-3) * (1.mantissa)
    addi s4, zero, 16# representing 1.0000 in 4-bit fractional
    add s4, s4, t2 # adding mantissa
    
    addi t1, t1, -3 # applying bias to exponent
    blt t1, zero, HandleFirstNumberNegativeExponent
    sll s4, s4, t1   # positive exponent case
    j ApplySignToFirstNumber
    
HandleFirstNumberNegativeExponent:
    neg t1, t1                  
    srl s4, s4, t1  # negative exponent case
    
ApplySignToFirstNumber:
    beq t0, zero, ProcessSecondFloatingPointNumber
    neg s4, s4   # applying negative sign
    
ProcessSecondFloatingPointNumber:
    addi s5, zero, 16           
    add s5, s5, t5              
    
    addi t4, t4, -3             
    blt t4, zero, HandleSecondNumberNegativeExponent
    sll s5, s5, t4              
    j ApplySignToSecondNumber
    
HandleSecondNumberNegativeExponent:
    neg t4, t4                  
    srl s5, s5, t4              
    
ApplySignToSecondNumber:
    beq t3, zero, PerformFloatingPointAddition
    neg s5, s5                  
    
PerformFloatingPointAddition:
    add s6, s4, s5  # adding the two values
    
    # extracting integer part correctly for negative numbers
    bge s6, zero, ExtractPositiveIntegerPart
    
    addi s6, s6, 15 # compensating for rounding in negative case
    srai s7, s6, 4  # arithmetic right shift
    j DisplayAdditionResult
    
ExtractPositiveIntegerPart:
    srai s7, s6, 4              
    
DisplayAdditionResult:
    addi a0, s7, 0              
    jal ra, ConvertSignedIntegerToDecimalDisplay
    sw a1, 0xfffffc60(zero)     
    
    srli s8, s7, 31 # getting sign bit of result
    slli s8, s8, 15  # moving to led[15] for visibility
    andi s9, s7, 0x7f # getting magnitude
    or s8, s8, s9 # combining sign and magnitude
    sw s8, 0xfffffc30(zero)     
    
    j WaitForSystemReset

# converting signed integer to bcd format with sign handling
ConvertSignedIntegerToDecimalDisplay:
    addi a4, zero, 0 # flag for negative number
    bge a0, zero, ConvertPositiveNumberToDecimal
    
    addi a4, zero, 1 # setting negative flag
    neg a0, a0# making positive for conversion
    
ConvertPositiveNumberToDecimal:
    addi a1, zero, 0 # initializing result
    
    bne a0, zero, ExtractDigitsFromNumber
    addi a1, zero, 0
    jr ra
    
ExtractDigitsFromNumber:
    addi a2, zero, 0  # initializing tens counter
CountTensInNumber:
    addi a3, zero, 10
    blt a0, a3, BuildFinalBcdResult      
    sub a0, a0, a3 # subtracting 10
    addi a2, a2, 1 # incrementing tens counter
    j CountTensInNumber
    
BuildFinalBcdResult:
    slli a2, a2, 4 # shifting tens to upper nibble
    or a1, a2, a0 # combining tens and ones
    
    beq a4, zero, ReturnBcdResult
    
    # for negative numbers, adding minus pattern
    lui a3, 0xe000 # loading minus pattern
    or a1, a1, a3               
    
ReturnBcdResult:
    jr ra

# converting 12-bit ieee754-like floating point to integer
ConvertFloatingPointToSignedInteger:
    srli s3, s2, 11
    andi s3, s3, 1 # extracting sign bit
    
    srli s4, s2, 8
    andi s4, s4, 7 # extracting exponent
    
    srli s5, s2, 4
    andi s5, s5, 15 # extracting mantissa
    
    # calculating value: (-1)^sign * 2^(exp-3) * (1.mantissa)
    addi s6, zero, 16           
    add s6, s6, s5              
    
    addi s4, s4, -3 # applying bias
    blt s4, zero, HandleFloatingPointNegativeExponent
    sll s6, s6, s4
    j ExtractIntegerPartFromFloatingPoint
    
HandleFloatingPointNegativeExponent:
    neg s4, s4
    srl s6, s6, s4
    
ExtractIntegerPartFromFloatingPoint:
    srli s6, s6, 4 # removing fractional bits
    
    beq s3, zero, ReturnFloatingPointResult
    neg s6, s6 # applying sign
    
ReturnFloatingPointResult:
    jr ra

# test case 100: crc-4 generation
ExecuteCrcGenerationTest:
WaitForCrcGenerationInput:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, WaitForCrcGenerationInput
    
    andi s2, s2, 15 # masking to 4 bits
    
    # crc-4 calculation using polynomial x^4 + x + 1
    slli s3, s2, 4  # shifting data left by 4 bits
    addi s4, zero, 4 # processing 4 data bits
    addi s5, zero, 0x98 # polynomial positioned at bits 7-3
    
ProcessCrcGenerationLoop:
    beq s4, zero, FinishCrcGeneration
    andi s6, s3, 0x80 # checking msb
    beq s6, zero, SkipCrcGenerationXor
    xor s3, s3, s5 # xor with polynomial
SkipCrcGenerationXor:
    slli s3, s3, 1# shifting left
    addi s4, s4, -1             
    j ProcessCrcGenerationLoop
    
FinishCrcGeneration:
    srli s3, s3, 4 # getting 4-bit crc
    andi s3, s3, 0x0f           
    slli s6, s2, 4 # original data in upper 4 bits
    or s6, s6, s3  # combining data and crc
    sw s6, 0xfffffc40(zero)     
    j WaitForSystemReset

# test case 101: crc-4 verification
ExecuteCrcVerificationTest:
WaitForCrcVerificationInput:
    lw s2, 0xfffffc10(zero)     
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, WaitForCrcVerificationInput
    
# verifying crc by dividing entire 8-bit word by polynomial
    add s3, s2, zero # copying input
    addi s4, zero, 8 # processing all 8 bits
    addi s5, zero, 0x98# polynomial
    
ProcessCrcVerificationLoop:
    beq s4, zero, CheckCrcVerificationResult
    andi s6, s3, 0x80           
    beq s6, zero, SkipCrcVerificationXor
    xor s3, s3, s5              
SkipCrcVerificationXor:
    slli s3, s3, 1              
    addi s4, s4, -1             
    j ProcessCrcVerificationLoop
    
CheckCrcVerificationResult:
    srli s3, s3, 4 # getting remainder
    andi s3, s3, 0x0f           
    beq s3, zero, IndicateCrcSuccess      
    
IndicateCrcFailure:
    sw zero, 0xfffffc30(zero) # crc failed
    j WaitForSystemReset
    
IndicateCrcSuccess:
    addi s7, zero, 1
    sw s7, 0xfffffc30(zero) # crc passed
    j WaitForSystemReset

# test case 110: testing lui instruction
ExecuteLoadUpperImmediateTest:
    lui s2, 0x87654
    addi s2, s2, 0x321# loading upper immediate
    sw s2, 0xfffffc60(zero) # displaying result
    j WaitForSystemReset

# test case 111: testing jal and jalr instructions separately
ExecuteJumpInstructionTest:
WaitForJumpTestSelection:
    lw s2, 0xfffffc10(zero) # 1 for jal, 2 for jalr
    lw s0, 0xfffffc28(zero)     
    bne s0, s11, WaitForJumpTestSelection
    
    addi t0, zero, 1
    beq s2, t0, TestJalInstruction  
    addi t0, zero, 2
    beq s2, t0, TestJalrInstruction 
    
    sw zero, 0xfffffc30(zero) # invalid input
    j WaitForSystemReset

TestJalInstruction:
    jal ra, SimpleJalTestFunction # calling function with jal
    
    li s8, 0x0000ffff # success pattern
    sw s8, 0xfffffc40(zero) # displaying jal success
    j WaitForSystemReset

SimpleJalTestFunction:
    addi t1, zero, 10 # dummy operations
    addi t1, t1, 5              
    jalr zero, ra, 0 # returning using jalr

TestJalrInstruction:
    la t0, JalrTestTargetFunction  # loading target address
    jalr ra, t0, 0  # jumping using jalr
    
    sw zero, 0xfffffc30(zero)# should not reach here
    j WaitForSystemReset

JalrTestTargetFunction:
    li s9, 0x0000ffff # success pattern
    sw s9, 0xfffffc50(zero) # displaying jalr success
    j WaitForSystemReset
    
#Bonus
BonusAuipc:
     lw s0, 0xfffffc28(zero)     # wait for input button
     bne s0, s11, BonusAuipc
     
     # Simple AUIPC test: Load PC + 0x12345000
     auipc s2, 0x12345           # s2 = PC + 0x12345000
     sw s2, 0xfffffc60(zero)     # Display result on digital tube
     
     # Show success pattern on LEDs
     li s3, 0x0000FFFF
     sw s3, 0xfffffc30(zero)     # Turn on all LEDs to indicate test completed
     j WaitForSystemReset

#Optional
# Test case 1001: Simple JAL and JALR test
SimpleJalJalr:
     lw s2, 0xfffffc10(zero)# input any value
     lw s0, 0xfffffc28(zero)# input button
     bne s0, s11, SimpleJalJalr
     
     # Test JAL and JALR together
     jal ra, TestFunction # calling function with JAL
     
     # If returning here, both JAL and JALR worked
     addi s3, zero, 255   # success: light up 8 LEDs
     sw s3, 0xfffffc30(zero) # display success
     j WaitForSystemReset

TestFunction:
     # This function tests JALR by returning
     jalr zero, ra, 0    # return using JALR

