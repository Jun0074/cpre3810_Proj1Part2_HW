# This test is a sequence of small jumps to make sure
# its skipping instructions correctly.

.data

.text
.globl main

main:
# Zeroing registers
addi t0, zero, 0
addi t1, zero, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jal ra, step1
slli x0, x0, 0
slli x0, x0, 0
slli x0, x0, 0
slli x0, x0, 0
slli x0, x0, 0
slli x0, x0, 0
# This shouldn't run
addi t0, t0, 1

step1:
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi t1, t1, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jal ra, step2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
# This shouldn't run
addi t0, t0, 1

step2:
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi t1, t1, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jal ra, step3
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
# This shouldn't run
addi t0, t0, 1

step3:
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi t1, t1, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
# t1 should be at 3, t0 should be at 0 by end
wfi
