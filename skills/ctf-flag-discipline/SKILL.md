---
name: ctf-flag-discipline
description: Flag handling and anti-guessing discipline for CTF. Load whenever a candidate flag is produced or a challenge nears solving. Enforces the flag format, forbids guessing or brute-forcing flag text, and defines what counts as a proven solve versus an assumption.
---

# CTF Flag Discipline

## Format
Expected: the format set in CLAUDE.md for this event (e.g. FLAG{...}) unless the challenge explicitly states another
format. If a recovered string does not match the expected shape, it is
probably not the flag, keep working, do not submit it hopefully.

## Hard rules
- NEVER guess flag contents. Never brute-force or fuzz the flag text
  itself against a checker.
- A flag is only real if it came from the intended solve path: the
  exploit ran, the decryption verified, the binary emitted it, the
  hidden data decoded to it.
- If you have a vulnerability but no flag, you have NOT solved it. Say so.

## Proven vs assumed
- Proven: exploit.py ran against the live target and printed the flag; or
  solve.py decrypted ciphertext to a string in the expected flag format (e.g. FLAG{...}); or the binary
  printed it on the success path with the recovered input.
- Assumed (NOT a solve): "this should give the flag", "the vuln is here
  so the flag is probably X", any flag not produced by a working artifact.

## Surface every candidate instantly (dynamic scoring)
- The instant ANY string matching the flag format appears, whether from the
  full solve, an intermediate step, a decode, a config default, or something
  you suspect is a decoy or red herring, print it at once on its own line as
  `FLAG: <string>`. Scoring weights submission time: surface first, bookkeep
  after.
- For every candidate give one line: confidence (high / medium / low) and
  exactly how it was obtained.
- Report EVERY format-matching candidate, never silently drop one you judge a
  decoy. Author creativity means your 99%-confident pick can be wrong and a
  "decoy" can be the real flag; the human decides what to submit.
- Surfacing candidates does NOT mean stopping. This never licenses guessing:
  keep digging to the end of the challenge until you reach the flag you judge
  actually accurate, surfacing each real match the moment you see it.

## On submission
- The human submits flags on the competition platform. Present the exact flag string,
  clearly, and note how it was obtained so the human can trust it.
- Record the final flag in SUMMARY.md verbatim.

## If stuck near the end
- Do not paper over a gap by guessing the flag. Return to the last
  verified step, state exactly what is missing (a leak, an offset, a
  key bit, a decode step), and solve that, or ask the human.
