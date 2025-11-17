# This test file is designed to validate all the supported 35 RISC-V instructions by our Project with Pipeline CPU.
# SW Version with NOPs inserted

.data
result: .word 0
test_data:
    .word 0x11223344

.text
.globl _start
_start:

# ---- BASE TEST SECTION ----
addi x1, x0, 5           # x1 = 5
addi x0, x0, 0           # NOP
addi x2, x0, 10          # x2 = 10
addi x0, x0, 0           # NOP
addi x3, x0, -3          # x3 = -3
addi x0, x0, 0
addi x4, x0, 0           # x4 = 0
addi x0, x0, 0

# ---- Arithmetic operations ----
add x5, x1, x2           # x5 = 15
addi x0, x0, 0
sub x6, x2, x1           # x6 = 5 lbu
addi x0, x0, 0
slt x7, x3, x2           # x7 = 1 (-3 < 10)
addi x0, x0, 0
slti x8, x1, 8           # x8 = 1 (5 < 8)
addi x0, x0, 0
sltiu x9, x3, 4          # x9 = 1 (unsigned compare)
addi x0, x0, 0
lui x10, 0x12345         # x10 = 0x12345000
addi x0, x0, 0
auipc x11, 0x1           # x11 = PC + 0x1000
addi x0, x0, 0

# ---- Logical operations ----
and x12, x1, x2          # 5 AND 10
addi x0, x0, 0
andi x13, x1, 12         # 5 AND 12
addi x0, x0, 0
or x14, x1, x3           # 5 OR -3
addi x0, x0, 0
ori x15, x1, 7           # 5 OR 7
addi x0, x0, 0
xor x16, x1, x2          # 5 XOR 10
addi x0, x0, 0
xori x17, x2, 15         # 10 XOR 15
addi x0, x0, 0

# ---- Shift operations ----
sll x18, x1, x2          # shift left variable
addi x0, x0, 0
slli x19, x1, 2          # shift left imm
addi x0, x0, 0
srl x20, x2, x1          # logical right variable
addi x0, x0, 0
srli x21, x2, 1          # logical right imm
addi x0, x0, 0
sra x22, x3, x1          # arithmetic right variable
addi x0, x0, 0
srai x23, x3, 1          # arithmetic right imm
addi x0, x0, 0
# -- up to here all successful, separated by 3 NOPs
addi x0, x0, 0
addi x0, x0, 0
# ---- LOAD TESTS SECTION ----
# Load base address of the test data
lasw   t0, test_data  
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

lw   t1, 0(t0)           # Should load 0x11223344 into t1
lb   t2, 1(t0)           # Byte = 0x33 → sign-extend → 0x00000033
lbu  t3, 1(t0)           # Byte = 0x33 → zero-extend → 0x00000033
lh   t4, 0(t0)           # Halfword = 0x3344 → sign-ext if needed
lhu  t5, 0(t0)           # Halfword = 0x3344 → zero-extend

# ---- End base test ----
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

# ---- CONTROL FLOW TEST SECTION ----
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
# Program end
wfi

