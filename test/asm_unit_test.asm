
; example tests and test driver
;
%include "asm_unit.inc"

; --------------------------------------------------------------------------------
; demo tests for testing the framework

_before_each_test_initialize_sut:
        before

        nop

        end

_after_each_test_clean_up:
        after

        nop

        end

_happy_path_should_add_one_and_one_to_two:
        begin_test

        mov     eax, 1
        add     eax, 1
        assert_equals eax, 2            ; success, print a dot

        end_test

_fails_and_skips_should_add_one_and_one_to_two:
        begin_test

        mov     eax, 1
        add     eax, 2
        assert_equals eax, 2            ; fails, print FAILED

        ; should not reach
        log     skip_nok, skip_nok_len

        end_test

skip_nok      db  "asm_unit failure: Did not leave test method on test failure! "
skip_nok_len   equ $ - skip_nok

; --------------------------------------------------------------------------------
; test runner

SYS_EXIT        equ     1
EXIT_SUCCESS    equ     0
EXIT_ERROR      equ     1

; void exit()
_exit:
        mov ebx, EXIT_SUCCESS   ;exit code argument
        mov eax, SYS_EXIT       ;system call number (sys_exit)
        int  0x80               ;call kernel

        ; never here
        hlt

; --------------------------------------------------------------------------------
        global  _start

        section .bss

stackp: resd    1

        section .text

_start:
        mov     [stackp], esp

        ; show welcome message
        log     msg_hello, msg_hello_end - msg_hello

        ; run tests, shows .,
        call    _happy_path_should_add_one_and_one_to_two
        call    _fails_and_skips_should_add_one_and_one_to_two

.done:
        ; show complete message
        log     msg_done, msg_done_end - msg_done

        ; development stack corruption check
        cmp     [stackp], esp
        jne     .stack_is_different
        jmp     .exit

.stack_is_different:
        log     stack_diff, stack_diff_len

.exit:
        jmp     _exit

msg_hello      db "HELLO from asm_unit. Starting tests: "
msg_hello_end:

msg_done       db "DONE."
msg_done_end:

stack_diff     db  "asm_unit failure: Stack size inconsistant at end! "
stack_diff_len  equ $ - stack_diff

