.data
.text
.globl main
main:
    # clear registers
    addi x1, x0, 3        # x1=3
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0   
    # for addi data hazard it requires 3 NOPs    
    add x3, x0, x1        # x3=3   
    add x4, x0, x0        # x4=0
    addi x0, x0, 0
    addi x0, x0, 0
    # for add data hazard it requires 3 NOPs   
    beq x3, x4, label1
    addi x0, x0, 0
    addi x0, x0, 0
    addi x6, x0, 1
    
label1:
    addi x5, x0, 2
    wfi



    #ecall
    #addi x0, x0, 0
    # addi x0, x0, 0
    
