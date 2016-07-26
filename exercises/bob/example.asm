
; example tests and test driver
;
%include "asm_unit.inc"

; --------------------------------------------------------------------------------
; tests

; int strcmp (string* first, string* second, int len)
_strcmp:
.p_first      	equ 4 + 1 * register_size
.p_second   	equ 4 + 2 * register_size
.p_len   		equ 4 + 3 * register_size

	proc_prolog 0

	mov esi, [ebp + .p_first] 	; address of first
	mov edi, [ebp + .p_second] 	; address of second
	mov ecx, [ebp + .p_len]		; repe needs the lenth of strings to test in ecx
	repe cmpsb 					; compare strings
	je cmp_equal
	mov eax, -1					; return -1 if not equal
cmp_equal:
	mov eax, 0					; return 1 if equal

	proc_epilog 3				; the epilog cleans the stack so we need to pop the 3 arguments pushed by the caller


_stating_something:
	begin_test
	
	; call our function
	push tomato_str
	call _hey

	; assertion
	push eax				; push the string returned from _hey
	push else_str			; push the expected string
	push else_str_len		; push the expected length
	call _strcmp			; call the string compare procedure
	assert_equals eax, 0	; if strings are equal we should have the return value 0 in eax

	end_test


_shouting:
	begin_test

	end_test


;---------------------------------------------------------------------------------
; define our answer strings
sure_str		db	"Sure."
sure_str_len	equ $ - sure_str

chill_str		db "Whoa, chill out!"
chill_str_len	equ $ - chill_str

fine_str		db "Fine. Be that way!"
fine_str_len	equ $ - fine_str

else_str		db "Whatever."
else_str_len	equ $ - else_str


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
