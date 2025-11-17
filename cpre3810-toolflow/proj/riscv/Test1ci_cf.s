# ===========================================================
# Test1ci_cfs.s
# Control-flow instruction test (no prints, no syscalls)
# Demonstrates: beq, bne, blt, bge, bltu, bgeu, jal, jalr
# True call depth = 5
# ===========================================================
.text
.globl _start

_start:
# Initialize stack pointer to match RARS (0x7FFFFFF0)
lui sp, 0x7FFFF
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi sp, sp, 0xF0
addi x0, x0, 0
addi x0, x0, 0


jal func1
addi x0, x0, 0
addi x0, x0, 0
wfi

func1:
addi x0, x0, 0
addi x0, x0, 0
addi sp, sp, -16
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
sw ra, 12(sp)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jal branch_test
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4


branch_test:
addi x0, x0, 0
addi x0, x0, 0
addi t0, x0, 0
addi t1, x0, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

beq t0, t0, L1
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L1:
bne t1, x0, L2
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L2:
blt t0, t1, L3
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L3:
bge t1, t0, L4
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L4:
bltu t0, t1, L5
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L5:
bgeu t1, t0, L6
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L6:
jalr ra, ra, 4 # link to next addr +4 go L7
addi x0, x0, 0
addi x0, x0, 0
addi x4, x0, 4
L7:
addi x0, x0, 0 
wfi