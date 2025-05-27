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
# 0xfffffc60 normal display

 addi s0, zero, 1 
 
WaitForSystemReset:
    lw s4, 0xfffffc24(zero)
    bne s4, s0, WaitForSystemReset  
    sw zero, 0xfffffc30(zero)
    sw zero, 0xfffffc60(zero)

ReadTestCaseSelection:
    lw s2, 0xfffffc10(zero) # reading testnumber from switches
    lw s4, 0xfffffc20(zero)# reading testcase number button
    bne s4, s0, ReadTestCaseSelection
    sw s2, 0xfffffc60(zero)# showing number testcase number button on tube
    
    addi s8, zero, 0
    beq s2, s8, DisplayInputsOnLeds
    addi s8, zero, 1
    beq s2, s8, LoadSignedByteToDisplay
    addi s8, zero, 2
    beq s2, s8, LoadUnsignedByteToDisplay
    addi s8, zero, 3
    beq s2, s8, CompareValuesUsingBeq
    addi s8, zero, 4
    beq s2, s8, CompareValuesUsingBlt
    addi s8, zero, 5
    beq s2, s8, CompareValuesUsingBltu
    addi s8, zero, 6
    beq s2, s8, CompareValuesUsingSlt
    addi s8, zero, 7
    beq s2, s8, CompareValuesUsingSltu
    j ReadTestCaseSelection            

# DisplayInputsOnLeds: showing inputs a and b on leds
DisplayInputsOnLeds:
ReadFirstInputValue:
    lw s1, 0xfffffc10(zero)     
    lw s4, 0xfffffc28(zero) # reading input a button bumber
    bne s4, s0, ReadFirstInputValue 
    sw s1, 0xfffffc40(zero) # showing input a button number

ReadSecondInputValue:
    lw s3, 0xfffffc10(zero)     
    lw s4, 0xfffffc2c(zero) # reading input b button bumber 
    bne s4, s0, ReadSecondInputValue  
    sw s3, 0xfffffc50(zero)# showing input b button number  
    j WaitForSystemReset

# loading input a as signed byte 
LoadSignedByteToDisplay:
    lb s1, 0xfffffc10(zero)# load signed byte from switches
    lw s4, 0xfffffc28(zero)     
    bne s4, s0, LoadSignedByteToDisplay  
    sw s1, 0xfffffc60(zero)     
    sw s1, 0(zero)   #store   
    j WaitForSystemReset

# loading input b as unsigned byte 
LoadUnsignedByteToDisplay:
    lbu s3, 0xfffffc10(zero) # loading unsigned byte 
    lw s4, 0xfffffc2c(zero)   
    bne s4, s0, LoadUnsignedByteToDisplay  
    sw s3, 0xfffffc60(zero)     
    sw s3, 4(zero)              
    j WaitForSystemReset

# checking if a equals b
CompareValuesUsingBeq:
    lw s1, 0(zero)            
    lw s3, 4(zero)                 
    beq s1, s3, TurnLedsOn      
    j TurnLedsOff               

CompareValuesUsingBlt:
    lw s1, 0(zero) 
    lw s3, 4(zero) 
    blt s1, s3, TurnLedsOn# if a < b, light leds
    j TurnLedsOff  

CompareValuesUsingBltu:
    lw s1, 0(zero) 
    lw s3, 4(zero)   
    bltu s1, s3, TurnLedsOn # if a < b unsigned, light up
    j TurnLedsOff 

CompareValuesUsingSlt:
    lw s1, 0(zero) # load saved input a
    lw s3, 4(zero)# load saved input b
    # setting s5 to 1 if a < b (signed), else 0
    slt s5, s1, s3 #1 light up
    sw s5, 0xfffffc30(zero)
    j WaitForSystemReset

CompareValuesUsingSltu:
    lw s1, 0(zero)
    lw s3, 4(zero) 
    sltu s5, s1, s3 #1 light up
    sw s5, 0xfffffc30(zero) 
    j WaitForSystemReset

# light up for true condition
TurnLedsOn:
    li s7, 0x0000ffff 
    sw s7, 0xfffffc40(zero)
    j WaitForSystemReset

#light off for false condition
TurnLedsOff:
    sw zero, 0xfffffc40(zero) 
    j WaitForSystemReset