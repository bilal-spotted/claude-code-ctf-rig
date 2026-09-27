---
name: ctf-crypto-attacks
description: Cryptographic attack decision tree for CTF crypto. Load for any crypto challenge to identify the primitive (RSA, AES, ECC, DH, hash, PRNG) and select the matching attack. Covers RSA (small e, Wiener, common modulus, Coppersmith, Fermat), AES oracles (ECB, CBC padding, CTR/GCM nonce reuse), ECDSA nonce reuse, LCG/MT state recovery, and hash length extension.
---

# CTF Crypto Attack Decision Tree

IDENTIFY the primitive and parameters FIRST. Never code before naming
the weakness.

## RSA (you have n, e, c, maybe more)
- e = 3 (or small) and m^e < n: cube-root the ciphertext.
- e = 3 across 3 recipients, same m: Hastad broadcast (CRT + root).
- Same n, two e (gcd(e1,e2)=1): common modulus attack.
- e very large / d small: Wiener (continued fractions), or Boneh-Durfee.
- p, q close: Fermat factorization.
- Known high/low bits of p, or stereotyped message: Coppersmith (use sage
  small_roots).
- n factorable / known: try factordb, then d = inverse(e, phi).
- Decryption/parity oracle: LSB oracle -> recover m by halving.
- Partial private key leak: recover with lattice.

## AES / block ciphers
- Same block -> same ciphertext (ECB): detect duplicate blocks; byte-at-a-
  time decryption if you control a prefix; cut-and-paste for structured.
- CBC + padding error distinguishable: padding oracle -> decrypt any block.
- CBC + you want to flip plaintext bits: bit-flipping via prev ciphertext.
- CTR/GCM with repeated nonce: keystream reuse -> XOR out; GCM nonce reuse
  also leaks the auth key (forbidden attack).

## ECC / DH / ECDSA
- Smooth group order: Pohlig-Hellman for discrete log.
- Small subgroup / invalid curve: send crafted points to leak key mod
  small primes.
- ECDSA repeated nonce k (same r in two sigs): recover k then private key.
- Singular/anomalous curve: specialized dlog (Smart's attack for
  trace-1 / p-adic).

## PRNG / stream
- LCG: recover a,c,m from consecutive outputs (differences + gcd).
- Mersenne Twister (Python random): 624 consecutive 32-bit outputs ->
  untemper -> clone state -> predict.
- LFSR: set up linear equations from output bits, solve over GF(2).

## Hashes
- MD5/SHA1 collisions available; length extension on Merkle-Damgard
  (MD5/SHA1/SHA256) when secret is prepended: use hashpumpy.

## Tools
- Standard: Python + pycryptodome + gmpy2 + sympy.
- Heavy math (lattice, Coppersmith, ECC dlog): the `sage` command (run
  from the challenge dir; it mounts cwd). fpylll for LLL natively.
- Always verify the recovered value decrypts/validates before claiming.
