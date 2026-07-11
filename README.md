# Simple Syscall Checker (PoC)

## Overview
This is a lightweight educational Proof-of-Concept (PoC) written in pure **x86_64 Assembly** for Linux. It simulates how security tools inspect memory pages at the byte level to detect inline hooking signatures (such as `0xE9` and `0xFF` opcodes) often utilized by user-mode rootkits or debuggers.

> **Note:** This project currently runs in User Mode (Ring 3) as a localized structural demonstration of memory pattern matching.

## How it Works
The detection loop scans a specific memory address layout (in this simulation, it references the local entry point) and evaluates the first 16 bytes to intercept control-flow redirections:
- Checks for **Near Jump** (`0xE9`)
- Checks for **Indirect Jump** (`0xFF`)
- Checks for **Short Jump** (`0xEB`)

If any hook signature is matched, the program alerts the console and terminates with an exit status code of `255`. If the byte integrity checks out, it exits gracefully with code `0`.

## Building and Running
To assemble and link the source code locally on Linux, make sure you have `nasm` and `ld` installed, then run:

```bash
# Assemble the source
nasm -f elf64 hook_detector.asm -o hook_detector.o

# Link the object file
ld hook_detector.o -o syscall_checker

# Run the binary
./syscall_checker
```

## Future Roadmap
- Port the assembly memory scanning logic into a proper Linux Kernel Module (LKM) in C.
- Safely resolve virtual-to-physical addressing to verify the real `sys_call_table` boundaries.
