---
name: ctf-pwn-playbook
description: Binary exploitation playbook for CTF pwn. Load for any pwn challenge to map mitigations to attack techniques: stack overflow, ret2win, ret2libc, ret2csu, ROP, format string, GOT overwrite, one_gadget, and heap techniques (tcache, fastbin, house of force/orange). Includes a pwntools exploit template.
---

# CTF Pwn Playbook

## First, always
`checksec ./bin`. Then map mitigations to what is possible:
- No canary + overflow -> straight stack smash.
- NX on -> no shellcode on stack, use ROP/ret2libc.
- PIE on -> need a leak to defeat ASLR of the binary.
- Full RELRO -> no GOT overwrite; Partial/none -> GOT overwrite viable.
- Canary present -> need leak or brute (forking) or a write primitive
  that avoids it.

## Vulnerability -> technique
- gets()/large read into small buf -> stack overflow.
- printf(user) -> format string: leak (%p/%s) and write (%n).
- scanf %s, off-by-one null -> partial overwrite / frame stitching.
- malloc/free with UAF or double free -> heap (tcache poisoning first,
  it's the modern default on glibc >= 2.26).

## Escalation ladder (typical)
1. Control RIP (find offset with cyclic/pattern).
2. If you need libc: leak a GOT entry via puts(got_entry)/write, then
   compute libc base = leak - known_offset.
3. Return into system("/bin/sh") or a one_gadget (run one_gadget on the
   provided libc; verify constraints).
4. If constrained, ret2csu to control args for a call.

## Format string
- Find your input's stack offset: send AAAA%N$p, find where 0x41414141
  appears.
- Leak: %N$s at a GOT/pointer to read libc/PIE.
- Write: %<val>c%N$n or byte-wise with %hhn for reliability.

## Heap (glibc)
- tcache poisoning: free two same-size chunks, overwrite fd of a freed
  tcache chunk to return an arbitrary pointer from malloc.
- Check glibc version; tcache key/safe-linking (>=2.32) means fd is
  mangled: (ptr >> 12) ^ target. Account for it.
- Older: fastbin dup, unsorted bin leak for libc, house of force/orange
  as fits.

## pwntools template (adapt per challenge)
```python
from pwn import *
context.binary = elf = ELF('./chall')
libc = ELF('./libc.so.6') if os.path.exists('./libc.so.6') else None
context.log_level = 'info'

def conn():
    if args.REMOTE:
        return remote('HOST', 1337)
    return process(elf.path)

io = conn()
# offset = cyclic_find(...)  # compute, do not guess
# ... build payload ...
io.interactive()
```

## Discipline
- Never hardcode an offset you did not compute against THIS binary/libc.
- Prove control locally (RIP overwrite, leak) before going remote.
- If a one_gadget fails, its constraints (register/stack state) were not
  met, pick another or set up the state; don't just retry.
