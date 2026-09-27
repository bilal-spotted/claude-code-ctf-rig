# Hard-Won Operating Lessons

The tool list in this repo is replaceable. Tools change, new ones appear, versions shift. The part that took real time to get right, and the part worth reading if you are building your own setup, is the accumulated operating discipline. These are the non-obvious choices baked into `CLAUDE.md` and the agents and skills, each one learned from watching the setup fail in a specific way and fixing it.

None of this is theoretical. Every rule here exists because its absence cost something in a live round.

---

## Surface the flag before the write-up

**The rule:** the instant a string matching the flag format is confirmed, from any source, the very next message states it plainly on its own line before anything else. Before notes get written, before scratch files get cleaned up, before the method gets explained.

**Why it exists:** the default behavior of a capable model is to finish a clean, complete narrative before reporting a result. It solves the challenge, then writes up the whole thing, then mentions the flag at the end. In a dynamically-scored competition that is backwards. Every minute between finding the flag and submitting it costs points, because scores decay as more teams solve. The operator was repeatedly finding that the flag existed, but was buried at the bottom of a long write-up or sitting inside a subagent's output that had not surfaced yet, so it had to be hunted down manually before it could be submitted.

**The subtlety that makes it work:** subagents cannot surface anything to you until their task returns. If a subagent is told to keep investigating and write a full report before returning, the flag sits inside a context you cannot see. So the discipline is enforced inside each agent, not just the main session: the moment an agent has the flag, it stops, surfaces it, and does bookkeeping after. This is why the flag-reporting line appears in all six agent files, worded the same way.

---

## A placeholder in source is a decoy, not a solve

**The rule:** a value matching the flag format that is found merely by reading source code, a config default, or binary strings is not treated as the flag. Only a value obtained by actually completing the exploit or decode chain counts. The rig keeps working past hardcoded defaults.

**Why it exists:** challenge source frequently contains a placeholder flag as a fallback, something like `FLAG = os.environ.get('DYN_FLAG', 'EXAMPLE{placeholder}')`, where the real flag is injected at runtime and the hardcoded string is never correct. Without this rule, an agent doing recon reads that string during source review and reports it as the flag, then stops investigating. It looks like a solve and is not. Recognizing that a format-matching string sitting in source is probably a trap, and continuing to the real exploit, is the difference between a wasted submission and a real one.

---

## Report every candidate, including the decoys

**The rule:** if more than one string matches the flag format, every one gets surfaced on its own line, ranked by confidence, with a one-line reason for each, including anything suspected to be a decoy or red herring. The rig does not silently pick one and discard the rest.

**Why it exists:** this one came directly from a loss. On one challenge the model found a real flag and a decoy, judged which was which, reported only its pick, and its pick was wrong, the decoy was actually the real flag. The reasoning behind the judgment was never surfaced, so there was no chance to catch the error. The fix is not to make the model judge better, it is to expose the reasoning and every candidate so the operator, who has competition context the model lacks (whether the platform rate-limits wrong submissions, whether a challenge is known to plant traps), makes the final call. Surfacing more information is never the expensive part; hiding it is.

A caution that rides along with this: not every decoy is safe to submit. Some challenges plant a fake flag specifically to catch shortcuts, and on stricter platforms submitting one can flag a team for review. So the rig surfaces candidates for the operator to weigh, rather than firing them all at the platform automatically.

---

## Notes on disk, continuously, not at the end

**The rule:** each agent records findings to `NOTES.md` as it goes, including the exact command that surfaced each finding, and challenge state lives in `NOTES.md` and `SUMMARY.md` per challenge.

**Why it exists:** two reasons, both practical. First, reproduction: the operator needs to be able to re-run what the model did, so the exact command that produced a finding has to be written down as it happens, not reconstructed later. Second, and more importantly, session survival. Long or heavy sessions sometimes need to be restarted mid-challenge. When that happens, everything in the model's context is gone, but the notes on disk are not. Continuous note-writing is what lets a fresh session pick up exactly where the last one left off instead of starting over. This discipline is what made session restarts survivable rather than catastrophic. A subagent that returns fast but writes nothing to disk first breaks this safety net at the exact moment it is needed.

---

## Match the decompiler approach to the binary, upfront

**The rule:** before using the Ghidra MCP tools on a binary, confirm which binary is actually loaded in the GUI. For any binary that is not the one open, go straight to headless decompilation. Reserve the live GUI connection for the single binary being actively explored interactively.

**Why it exists:** the Ghidra MCP bridge connects to whatever one binary is open in the GUI, and cannot see a second without it being loaded. On multi-binary challenges (a worker, a warden, a relay, say) or when running analysis against one binary while Ghidra sits on another, this single GUI slot becomes a constant source of "the loaded binary is different" stalls. Each one costs a detection cycle and a fallback decision mid-challenge. Turning that reactive discovery into an upfront decision, headless for everything except the one binary you are hand-exploring, removes the stall entirely. Headless PyGhidra gives identical decompiler output, so nothing is lost by defaulting to it.

---

## The AI tools live in their own world

**The rule:** the AI-security toolchain (garak, pyrit, and the rest) is installed in an isolated virtual environment, and every invocation of those tools uses the full path into that environment.

**Why it exists:** these tools have large, aggressive dependency trees. Installed globally on a Kali box, they force version downgrades that break unrelated security tools, pwntools among them. Isolation in a virtual environment is the only clean way to have both. The cost is that the tools must be invoked by full path rather than by bare name, which is why the `ctf-ai-security` skill and `ai_redteam` agent spell out the full paths, and why the skill also documents the module-invocation fallback for the one tool that does not always register a command-line entry point.

---

## The AI-hacking category is real, and it has shapes

**The rule:** the `ai_redteam` agent does not treat AI challenges as a single blur of "try prompt injection." It maps each one to a specific shape first: direct extraction, filter bypass, agent tool abuse, MCP-specific attacks (tool poisoning, shadowing, rug pulls), vibe-coded application flaws, agent framework RCE, or provided model file inspection.

**Why it exists:** the AI-hacking category is newer and growing, and in a prior competition it was a category where zero challenges were solved, a real gap on the leaderboard. Treating it as undifferentiated prompt-injection guesswork does not work, because the category has genuinely distinct attack surfaces that call for different techniques and tools. Naming the shape first, then reaching for the matching technique, is what turns it from a blind spot into a solvable category. The same lesson drove including a `hardware` category folder in the workspace scaffold: a category you are not even set up to attempt is a category you will not score in.

---

## Trust your own MCP config, and know that you are trusting it

**The rule:** the rig sets `enableAllProjectMcpServers: true`, which trusts the MCP servers defined in a workspace without a per-launch approval prompt.

**Why it exists, and the caveat:** for a solo rig you built and control, approving Burp and Ghidra every single launch is pure friction, and the setting removes it. But it is a real tradeoff worth making consciously, not by accident. The setting means any MCP server defined in a workspace Claude Code opens will run with the same access Claude Code has. That is fine for a workspace whose `.mcp.json` you wrote. It would not be fine to point Claude Code at a workspace whose config came from somewhere else. The rule is: only ever run this in workspaces you control, and stay aware the setting is there, so that months later, tired and mid-round, you do not drop an untrusted config into a workspace and forget what auto-execution means. If that tradeoff ever stops feeling worth it, remove the setting and approve servers manually.

---

## Validate JSON before you trust it

**The rule, learned the annoying way:** the permissions file and MCP config are JSON, and a single malformed edit breaks the entire config, causing Claude Code to skip it silently. After any hand-edit to `settings.json` or `.mcp.json`, validate it (`python3 -m json.tool <file>`), and prefer programmatic edits over hand-editing for anything non-trivial.

**Why it exists:** JSON has no tolerance for a stray brace or a missing comma, and the failure mode is quiet, the config just does not load and the rig comes up with none of its permissions. More than once, a manual edit to add one setting produced two adjacent objects instead of one merged object, and the whole file became invalid. The lesson is small but real: treat these files as load-bearing, validate after touching them, and when adding several things at once, edit through a script that cannot produce broken syntax rather than by hand.

---

## The meta-lesson

The thread running through all of these is the same: a capable model left to its own instincts will optimize for a clean, complete, well-narrated result. Competition rewards something different, fast and accurate flag capture under time pressure, with state that survives interruption and information surfaced rather than hidden. Most of the discipline in this rig is about bending that default toward what actually scores. That is the part worth carrying to any setup you build, whatever the tools turn out to be.
