.section .text.init
.global _start

_start:

    li sp, 0x80001000

    call main

hang:
    ebreak
    j hang