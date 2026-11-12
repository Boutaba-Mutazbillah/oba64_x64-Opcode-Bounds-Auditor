# oba64

**`oba64`** stands for **x64 Opcode Bounds Auditor**:
- **Opcode:** Inspects raw CPU instruction bytes directly in memory rather than high-level code.
- **Bounds:** Resolves relative jump targets and verifies that execution stays within legitimate code segment limits (catching escapes into code caves).
- **Auditor:** Audits memory integrity to detect unauthorized control-flow redirections.
- **64:** Built specifically for the 64-bit (`x86_64`) architecture.

## What is oba64?

`oba64` is a lightweight, dependency-free security auditing tool written in pure x86_64 Assembly for Windows. It detects inline hooks, mid-function jumps, and software breakpoints by scanning executable code segments byte by byte without relying on `kernel32.dll` or any high-level Windows APIs.

## Where It Operates

- **Operating System:** Windows 64-bit (`x86_64`).
- **Execution Layer:** User Mode (Ring 3) with direct native kernel communication via the `SYSCALL` instruction.
- **Memory Target:** Executable code pages (`.text` section / bounded range from `_START` to `_END` in virtual memory).

## How It Works

Unlike basic checkers that only inspect the first few bytes of a routine (the prologue), `oba64` scans the entire bounded code block to catch deeper mid-body hooks:

- **Near Jumps (`0xE9`):** Calculates the 32-bit signed relative target address using `LEA` and flags an alert if the destination falls outside `_START` and `_END`.
- **Short Jumps (`0xEB`):** Resolves the 8-bit signed offset and verifies that the jump stays inside valid code boundaries.
- **Indirect Jumps (`0xFF`):** Checks the ModR/M byte to detect RIP-relative jumps (`0xFF 0x25`) and register-based jumps (`0xFF 0xE0` – `0xFF 0xE7`).
- **Software Breakpoints (`0xCC`):** Flags `INT3` instructions injected by debuggers or dynamic instrumentation tools.

When the scan completes, it invokes `NtTerminateProcess` (`0x2C`) directly via `SYSCALL` and sets the process exit code:
- `0`: Memory range is clean.
- `255`: Hook, breakpoint, or out-of-bounds jump detected.

## Build & Run

Requires `nasm` and a Windows linker (`ld` or `golink`):

```cmd
nasm -f win64 oba64.asm -o oba64.obj
ld -e _START oba64.obj -o oba64.exe
oba64.exe
echo %ERRORLEVEL%
```

## Embedding in Other Tools

The core scanning block can be integrated directly into other assembly or low-level tools:
- **Input:** Load start address into `RSI` and end address into `RDX`.
- **Output:** Status code is returned in `R8` (`0` for clean, `255` for hooked).
- **Clobbered Registers:** `RAX`, `RBX`, `RCX`, `RDX`, `R8`, `R9`, `R10`.
