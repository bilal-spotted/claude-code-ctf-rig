<div align="center">

# 🚩 Claude Code CTF Rig

A production-grade operator setup that turns Claude Code into a full CTF solving team inside a Kali Linux VM. Built and battle-tested across live jeopardy competitions, it pairs specialist subagents and skill playbooks with real security tooling, MCP bridges to Burp Suite and Ghidra, and a set of hard-won operating rules that keep the model fast, accurate, and disciplined under the pressure of dynamic scoring.

[![License: MIT](https://img.shields.io/badge/License-MIT-2ea44f?style=for-the-badge)](LICENSE)
![Built for Kali Linux](https://img.shields.io/badge/Built_for-Kali_Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![Runs on Claude Code](https://img.shields.io/badge/Runs_on-Claude_Code-D97757?style=for-the-badge)
![MCP: Burp + Ghidra](https://img.shields.io/badge/MCP-Burp_%2B_Ghidra-6E40C9?style=for-the-badge)
![Coverage](https://img.shields.io/badge/coverage-web_pwn_rev_crypto_forensics_AI-444?style=for-the-badge)

</div>

> **Disclaimer** — This rig is provided for authorised security testing and education only: CTF competitions, and systems you own or have explicit permission to assess. Use it lawfully and in accordance with the rules of any event. It is offered as-is, with no warranty and no liability for misuse.

This is not a toy prompt. It is the actual working configuration, generalized so anyone can drop it into their own Kali box and run it. Every path, tool, and instruction here comes from real competition use, and the lessons baked into the agents and skills were learned the hard way, mid-round, when something broke.

---

## Table of Contents

- [What this is for](#what-this-is-for)
- [Architecture at a glance](#architecture-at-a-glance)
- [The subagents](#the-subagents)
- [The skills](#the-skills)
- [Quick start](#quick-start)
- [Have the rig check itself](#have-the-rig-check-itself)
- [Adapting the rig](#adapting-the-rig)
- [A note on the design philosophy](#a-note-on-the-design-philosophy)
- [Repository layout](#repository-layout)
- [License](#license)

---

## What this is for

CTF competitions reward speed and accuracy. A single operator juggling web, pwn, reversing, crypto, forensics, and the newer AI-hacking category cannot go deep on everything at once. This rig hands each category to a dedicated subagent that already knows the right tools, the right order to try them, and the discipline to surface a flag the instant it appears instead of burning time on write-ups first.

The design goals, in priority order:

1. **Surface flags immediately.** Dynamic scoring means every minute between finding a flag and submitting it costs points. The rig is built so the flag hits your screen the moment it exists, before any documentation.
2. **Match the tool to the task.** Each subagent carries a focused toolchain and a decision tree, so Claude does not rediscover which wordlist lives where or which decompiler to reach for.
3. **Stay disciplined under pressure.** Notes and summaries survive session restarts. Decoy flags get surfaced, not silently discarded. Placeholder values in source do not get mistaken for the real thing.
4. **Reproduce cleanly.** Anyone can clone this, adjust a handful of paths, and be running in minutes.

---

## Architecture at a glance

```
                          You (the operator)
                                 |
                          Claude Code (main session)
                                 |
      +--------------+-----------+-----------+--------------+
      |              |           |           |              |
  web_recon    pwn_analyst  rev_analyst  crypto_solver  forensics_carver   ai_redteam
      |              |           |           |              |                  |
   ctf-web-     ctf-pwn-    ctf-rev-    ctf-crypto-    ctf-forensics-     ctf-ai-security
    vulns       playbook    toolkit      attacks         recipes
                                 |
                          Shared discipline: ctf-flag-discipline
                                 |
      +--------------------------+--------------------------+
      |                          |                          |
  Burp Suite MCP           Ghidra MCP                 AI security tools
  (web/proxy)              (reversing)                (isolated venv)
```

Six specialist subagents, each paired with a skill that holds the detailed tool recipes. One shared flag-discipline skill that every agent honors. Two MCP bridges into the heavyweight GUI tools. A separate, isolated virtual environment for the AI-hacking toolchain so its dependencies never fight the rest of the box.

---

## The subagents

Each agent lives in `agents/` and is triggered automatically by Claude Code based on the challenge type, or can be invoked explicitly.

| Agent | Category | What it does |
|-------|----------|--------------|
| `web_recon` | Web | Content discovery, injection, auth bypass, SSRF, deserialization. Drives Burp via MCP and the fuzzing toolchain. |
| `pwn_analyst` | Binary exploitation | Memory corruption, ROP, heap, format strings. Works with gdb, pwntools, ROPgadget, one_gadget. |
| `rev_analyst` | Reverse engineering | Static and dynamic analysis. Drives Ghidra via MCP and headless PyGhidra, plus radare2, gdb, angr. |
| `crypto_solver` | Cryptography | Classical and modern crypto attacks, lattice work, oracle exploitation. SageMath, custom scripts. |
| `forensics_carver` | Forensics | pcap dissection, memory dumps, disk images, steganography, document and archive analysis, Windows and mobile artifacts, timeline correlation. |
| `ai_redteam` | AI / LLM security | Prompt injection, jailbreaks, MCP tool poisoning, agent tool abuse, model file inspection, vibe-coded app flaws. Newer category, self-contained toolkit. |

## The skills

Skills live in `skills/` and hold the detailed, reference-grade recipes each agent pulls from. Separating the recipes into skills keeps the agent instructions lean while giving Claude a deep playbook to consult when it actually needs the specifics.

| Skill | Loaded for |
|-------|-----------|
| `ctf-web-vulns` | Web vulnerability classes and exploitation recipes |
| `ctf-pwn-playbook` | Binary exploitation techniques and gadget workflows |
| `ctf-rev-toolkit` | Reverse-engineering tool recipes, including PyGhidra headless |
| `ctf-crypto-attacks` | Cryptographic attack catalog |
| `ctf-forensics-recipes` | Artifact-by-artifact forensics tool chains |
| `ctf-ai-security` | AI/LLM attack recipes and the isolated tool invocations |
| `ctf-flag-discipline` | The shared rules every agent follows for surfacing and handling flags |

---

## Quick start

Full step-by-step setup is in [`docs/SETUP.md`](docs/SETUP.md). The short version:

1. **Clone into your Kali VM.**
   ```bash
   git clone https://github.com/bilal-spotted/claude-code-ctf-rig.git ~/ctf-rig
   ```

2. **Copy the config into a CTF workspace.**
   ```bash
   mkdir -p ~/ctf/event && cd ~/ctf/event
   cp ~/ctf-rig/CLAUDE.md .
   mkdir -p .claude
   cp -r ~/ctf-rig/agents .claude/agents
   cp -r ~/ctf-rig/skills .claude/skills
   cp ~/ctf-rig/settings.json.template .claude/settings.json
   cp ~/ctf-rig/.mcp.json.template .mcp.json
   ```

3. **Fill in your paths.** Every file with a `.template` suffix and the `CLAUDE.md` itself contain placeholders. Replace `YOUR_USERNAME` throughout, and fill in the competition details (name, platform, flag format, categories) in `CLAUDE.md`. See [`docs/SETUP.md`](docs/SETUP.md) for the exact list.

4. **Create the challenge working folders.**
   ```bash
   cp ~/ctf-rig/scripts/init-workspace.sh .
   ./init-workspace.sh
   ```

5. **Install the toolchain.** See [`docs/TOOLS.md`](docs/TOOLS.md) for the full list, the AI-security virtual environment, and how to verify everything is present.

6. **Wire up the MCP bridges.** Burp Suite and Ghidra each need their MCP server running. See [`docs/MCP.md`](docs/MCP.md).

7. **Launch and audit.** Start Claude Code in the workspace, then run the self-audit prompt (below) to have the rig check itself before you rely on it.

---

## Have the rig check itself

Before trusting the setup in a live event, launch Claude Code in your workspace and paste this. It is the single most useful step for catching a missing tool, a broken path, or a config that did not copy cleanly.

```
Do a full self-audit of this workspace before I rely on it in a competition.
Report two sections, confirmed working and broken or missing, with the exact
file and location for every item.

1. Read CLAUDE.md and check every rule for internal contradictions and for
   consistency with the six files in .claude/agents/, especially the flag
   reporting discipline.
2. Read every file in .claude/agents/ and .claude/skills/. Confirm each agent
   has a complete frontmatter description and a tools list appropriate to its
   domain, and that every concrete command in the skills is real and correctly
   formed.
3. Confirm .claude/settings.json is valid JSON and that permissions.allow
   covers every tool referenced anywhere in the agents and skills. Flag
   anything referenced with no matching allow entry.
4. Check that every command-line tool the rig expects is actually installed.
   For anything missing, install it, then verify. Double-check the reversing,
   forensics, and AI-security toolchains specifically.
5. Run /mcp and confirm the Burp and Ghidra servers are connected.
6. Report anything else that would stop this rig from working in a live round.
```

---

## Adapting the rig

**Changing the flag format or competition details.** Edit `CLAUDE.md`. The mission section holds placeholders for the event name, platform, format type, categories, and flag format.

**Hardcoded paths.** The rig references a handful of absolute paths that depend on your username and where you installed things. Every one is templated to `YOUR_USERNAME` or documented in [`docs/SETUP.md`](docs/SETUP.md). The AI-security tools live in a dedicated virtual environment whose path appears in `settings.json.template`, the `ctf-ai-security` skill, and the `ai_redteam` agent.

**Adding or removing MCP servers.** Edit `.mcp.json.template`. The rig ships with Burp and Ghidra. To add another (a pcap analyzer, a different decompiler bridge), add its entry and grant its tools in `settings.json.template` under `permissions.allow` using the `mcp__<servername>` and `mcp__<servername>__*` form. To remove one, delete both its `.mcp.json` entry and its allow entries. See [`docs/MCP.md`](docs/MCP.md).

**Missing tools.** The self-audit prompt above will find and install them. [`docs/TOOLS.md`](docs/TOOLS.md) has the full manifest if you prefer to install by hand.

---

## Repository layout

```
.
├── README.md                  You are here
├── CLAUDE.md                  The operator playbook (fill in event details)
├── settings.json.template     Claude Code permissions and settings
├── .mcp.json.template         MCP server definitions (Burp, Ghidra)
├── agents/                    The six specialist subagents
│   ├── web_recon.md
│   ├── pwn_analyst.md
│   ├── rev_analyst.md
│   ├── crypto_solver.md
│   ├── forensics_carver.md
│   └── ai_redteam.md
├── skills/                    The seven skill playbooks
│   ├── ctf-web-vulns/
│   ├── ctf-pwn-playbook/
│   ├── ctf-rev-toolkit/
│   ├── ctf-crypto-attacks/
│   ├── ctf-forensics-recipes/
│   ├── ctf-ai-security/
│   └── ctf-flag-discipline/
├── scripts/
│   └── init-workspace.sh      Creates the challenge category folders
└── docs/
    ├── SETUP.md               Full first-run walkthrough
    ├── MCP.md                 Burp and Ghidra MCP bridge setup
    ├── TOOLS.md               Tool manifest and verification
    └── LESSONS.md             Hard-won operating lessons
```

---

## A note on the design philosophy

The most valuable part of this repo is not the tool list. Tools change. The valuable part is the accumulated operating discipline, the rules in `CLAUDE.md` and `ctf-flag-discipline` that came from watching the setup fail and fixing it. Read [`docs/LESSONS.md`](docs/LESSONS.md) for the reasoning behind the non-obvious choices: why flags surface before write-ups, why placeholder values in source are treated as decoys, why the AI tools live in their own virtual environment, why notes are written to disk continuously.

Those lessons are the difference between a setup that looks impressive and one that actually places.

---

## License

See [`LICENSE`](LICENSE).
