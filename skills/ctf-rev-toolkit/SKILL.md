---
name: ctf-rev-toolkit
description: Reverse engineering toolkit and workflow for CTF rev. Load for any rev challenge to pick the right approach by target type (native ELF/PE, .NET, JVM, Python pyc, WASM, packed/obfuscated), find the flag-gating check, and recover the required input, including angr symbolic execution for constraint-heavy binaries.
---

# CTF Reverse Engineering Toolkit

## Triage (always first)
- `file`, `strings -n 6` (flag or hints sometimes sit in plaintext).
- `checksec`, detect packing (entropy, UPX signature). UPX -> `upx -d`.
- Identify runtime/language; it dictates the tool.

## By target type
- Native ELF/PE: Ghidra (decompile, rename as you learn) via ghidra MCP;
  radare2/gdb+pwndbg for dynamic. Watch for anti-debug (ptrace, timing).
- .NET: ilspycmd or dnSpy; IL is high-level, often trivial once decompiled.
- JVM .class/.jar: cfr or procyon decompiler.
- Python .pyc: decompyle3 / pycdc; match bytecode version.
- WASM: wasm2wat, read the text form.
- Go/Rust: stripped and large; find main.main, use symbol recovery
  scripts, focus on the comparison logic not the runtime.

## Find the gate
Locate where input is validated: strcmp/memcmp, a checksum loop, a
transform-then-compare. Explain what it checks in NOTES.md before solving.

## Recover input
- Direct compare -> read the target bytes, done.
- Simple transform (xor/add/permute) -> invert it.
- Many interlocking constraints on input bytes -> angr:
```python
import angr, claripy
p = angr.Project('./chall', auto_load_libs=False)
# find = address of "Correct" path, avoid = "Wrong" path
sm = p.factory.simulation_manager(p.factory.full_init_state())
sm.explore(find=FIND_ADDR, avoid=AVOID_ADDR)
print(sm.found[0].posix.dumps(0))  # stdin that solves it
```
- Verify: run the binary with the recovered input, confirm success path.

## Discipline
- If you cannot explain why an input works, re-check; luck hides bugs.
- Anti-debug present -> patch the check or use ltrace/strace around it,
  don't fight it blindly.
