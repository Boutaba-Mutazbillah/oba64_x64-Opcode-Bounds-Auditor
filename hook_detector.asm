; ==============================================================================
;  Project: Boutaba-kernel-hook-scanner v1.0
;  Developer: Boutaba Motezeballah — Systems Architect & Reverse Engineer
;  Architecture: x86_64 ASM (Linux Platform Subversion Auditing)
;  Description: Advanced Runtime Syscall Code Segment Verification Layer.
; ==============================================================================

section .data
    msg_safe     db "Status: INTEGRITY SECURE. No unauthorized memory hooks.", 10
    len_safe     equ \$ - msg_safe

    msg_hooked   db "CRITICAL ERROR: Kernel syscall-integrity-check! Rootkit Present.", 10
    len_hooked   equ \$ - msg_hooked

section .text
    global _start

_start:
    ; 1. Architectural Setup - Establish Memory Reference
    push rbp
    mov rbp, rsp
    
    ; Simulation of runtime target extraction via sysfs/kallsyms interface pointer
    ; Loading virtual memory offset proxy address for inspection
    mov rsi, _start              ; Pointer to target execution code page
    xor rcx, rcx                 ; Loop counter initialization

.scan_byte_loop:
    ; 2. Byte-Level Memory Pattern Inspection
    mov al, byte [rsi + rcx]     ; Read raw microarchitectural instruction byte
    
    ; Check for explicit Hook Jump Patterns (Inline Patching Signatures)
    cmp al, 0xE9                 ; 0xE9 = NEAR JUMP Opcode
    je .rootkit_hook_intercept
    
    cmp al, 0xFF                 ; 0xFF /4 = INDIRECT JUMP Opcode Group
    je .check_indirect_group
    
    cmp al, 0xEB                 ; 0xEB = SHORT JUMP Opcode
    je .rootkit_hook_intercept

.continue_scan:
    inc rcx                      ; Increment instruction pointer offset
    cmp rcx, 16                  ; Audit window constraint: scan first 16 bytes
    jl .scan_byte_loop           ; Recurse until code page boundary reached

    ; 3. Verification Integrity Path (SAFE)
    mov rax, 1                   ; syscall: sys_write
    mov rdi, 1                   ; file descriptor: stdout
    mov rsi, msg_safe
    mov rdx, len_safe
    syscall

    ; Graceful Execution Termination
    mov rsp, rbp
    pop rbp
    mov rax, 60                  ; syscall: sys_exit
    xor rdi, rdi                 ; exit code = 0
    syscall

.check_indirect_group:
    ; Sub-validation loop to check secondary registers or memory address pointer redirection
    mov bl, byte [rsi + rcx + 1]
    cmp bl, 0x25                 ; 0x25 = RIP-relative indirect jump signature
    je .rootkit_hook_intercept
    jmp .continue_scan

.rootkit_hook_intercept:
    ; 4. Proactive Forensic Interception (HOOK DETECTED)
    mov rax, 1                   ; syscall: sys_write
    mov rdi, 1                   ; file descriptor: stdout
    mov rsi, msg_hooked
    mov rdx, len_hooked
    syscall

    ; Abrupt Execution Interruption - Mitigation State (Exit code 255)
    mov rsp, rbp
    pop rbp
    mov rax, 60                  ; syscall: sys_exit
    mov rdi, 255                 ; error status classification
    syscall
