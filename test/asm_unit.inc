; minimal asm_unit (xUnit) for NASM
; --------------------------------

; Original code by Peter Kofler; modified by Marius Cetateanu for Linux systems

; What would a unit testing framework need?
; * assert macros (which abort current test)
;   - DONE, just clear stack & return
; * before/after hooks for each test case
;   - DONE, with startTest and endTest Macros
; * test public APIs
;   - NOP, only test against exported symbols
; * stub system calls
;   - SUT needs to be designed like that
; * test cases and names
;   - DONE, easy with labels
; * run all test cases in test, auto discover (optional)

%ifndef ASM_UNIT
%define ASM_UNIT

bits 32
register_size equ 4

        section .text

; --------------------------------------------------------------------------------
; call convention
; *stdcall* call convention (parameters pushed in right-to-left order, callee clean-up)
; used in Microsoft Win32 API
; see https://en.wikipedia.org/wiki/X86_calling_conventions#stdcall

; begin method, create stack frame and space for local variables
%macro proc_prolog 1         ; number of local variables
        push    ebp
        mov     ebp, esp
        sub     esp, %1 * register_size
%endmacro

; end method, drop paremeters from stack before returning
%macro proc_epilog 1          ; number of parameters to remove
        leave
        ret     %1 * register_size
%endmacro

; --------------------------------------------------------------------------------
; logging/output

%define NULL    dword 0

SYS_WRITE equ 4
STDOUT    equ 1

; void write (string* message, int message_len)
_write:
.p_message      equ 4 + 1 * register_size
.p_message_len   equ 4 + 2 * register_size

	proc_prolog 0

	; write message to stdout using sys_write
    mov     edx, [ebp + .p_message_len]	; message length argument
    mov     ecx, [ebp + .p_message]		; message argument
    mov 	ebx, STDOUT					; file descriptor, 1 == stdout
    mov 	eax, SYS_WRITE				; system call number, 4 == sys_write
    int 	0x80						; call kernel

    proc_epilog 2

; void writeln ()
_writeln:
        push    nwln_len
        push    nwln
        call    _write
        ret

nwln      db 0x0a      ; Linux \n
nwln_len  equ $ - nwln

; void log (string* message, int message_length)
_log:
.p_message      equ 4 + 1 * register_size
.p_message_len   equ 4 + 2 * register_size

	proc_prolog 0

	mov     eax, [ebp + .p_message_len]
    push    eax
    mov     eax, [ebp + .p_message]
    push    eax
    call    _write

    call    _writeln

    proc_epilog 2

; log shortcut
%macro log 2                            ; message and length
        push    %2
        push    %1
        call    _log
%endmacro

; show a dot without newline to indicate progress
; void print('.')
_show_progress:
        ; conserve ALL registers
		pusha

		push    dot_len
        mov     eax, dot
        push    eax
        call    _write

		popa
        ret

dot    db      "."
dot_len equ     1

; --------------------------------------------------------------------------------
; assertions

; fail a test and stop executing it
%macro fail 0
        call _writeln
        log msg_failed, msg_failed_len

        ; skip further test method execution, return immediately
        end_test
%endmacro

        ; TODO could use ANSI color codes for failed
msg_failed     db "FAILED! "
msg_failed_len  equ $ - msg_failed

; assert equality
%macro assert_equals 2                  ; expected, actual
        cmp     %1, %2
        je      %%_end
        fail
%%_end:
        call    _show_progress
%endmacro

; --------------------------------------------------------------------------------
; life cycle and test methods

; start the before method
%macro before 0-1 0                     ; optional number of locals (else 0)
        %ifdef ctx_before
                %error "before used more than once"
        %endif

        %define ctx_before, 1
_before_hook:
        proc_prolog %1
%endmacro

%macro after 0-1 0                      ; optional number of locals (else 0)
        %ifdef ctx_after
                %error "after used more than once"
        %endif

        %define ctx_after, 1
_after_hook:
        proc_prolog %1
%endmacro

%macro end 0
        proc_epilog 0
%endmacro

%macro begin_test 0-1 0                 ; optional number of locals (else 0)
        proc_prolog %1
        %ifdef ctx_before
                call _before_hook
        %endif
%endmacro

%macro end_test 0
        %ifdef ctx_after
                call _after_hook
        %endif
        end
%endmacro

%endif

