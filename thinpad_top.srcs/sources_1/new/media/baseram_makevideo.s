.section .text
.globl _start
_start:
        li      a5,-2046820352
        li      a4,1
        sb      a4,4(a5)
        li      a5,-2046820352
        li      a4,2
        sb      a4,0(a5)
        li      a0,1
        li      a6,0
        li      a2,-2097152000
        j       .L2
.L9:
        li      a1,-2080374784
        j       .L3
.L5:
        add     a3,a2,a5
        add     a4,a1,a5
        lbu     a3,0(a3)
        sb      a3,0(a4)
        addi    a5,a5,1
.L4:
        li      a4,28672
        addi    a4,a4,1328
        bne     a5,a4,.L5
        add     a2,a2,a4
        xori    a0,a0,1
        li      a5,-2046820352
        sb      a0,4(a5)
        addi    a6,a6,1
.L2:
        li      a5,128
        beq     a6,a5,.L7
        bne     a0,zero,.L9
        li      a1,-2063597568
.L3:
        li      a5,0
        j       .L4