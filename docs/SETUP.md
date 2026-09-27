# Setup

This is the full first-run walkthrough. It assumes a working Kali Linux VM (VMware, VirtualBox, or bare metal) and Claude Code already installed and authenticated. If you do not have Claude Code yet, install it first from the official Anthropic instructions, then come back.

The setup has five stages: get the files in place, fill in your specifics, create the working folders, install the toolchain, and wire up the MCP bridges. Budget an hour the first time. After that, spinning up a fresh workspace for a new event takes a couple of minutes.

---

## Stage 1: Get the files in place

Clone the repo somewhere permanent. This copy is your reference, not your working directory.

```bash
git clone https://github.com/bilal-spotted/claude-code-ctf-rig.git ~/ctf-rig
```

Create a workspace for your event and copy the config into it. The workspace is where Claude Code actually runs and where your challenge files will live.

```bash
mkdir -p ~/ctf/event
cd ~/ctf/event

# The operator playbook sits at the workspace root
cp ~/ctf-rig/CLAUDE.md .

# Agents and skills go under .claude/
mkdir -p .claude
cp -r ~/ctf-rig/agents .claude/agents
cp -r ~/ctf-rig/skills .claude/skills

# Permissions and MCP definitions, dropping the .template suffix
cp ~/ctf-rig/settings.json.template .claude/settings.json
cp ~/ctf-rig/.mcp.json.template .mcp.json
```

At this point your workspace looks like this:

```
~/ctf/event/
├── CLAUDE.md
├── .mcp.json
└── .claude/
    ├── settings.json
    ├── agents/
    └── skills/
```

Note that `CLAUDE.md` keeps its name. Claude Code reads a file named exactly `CLAUDE.md` from the workspace root, so it is never suffixed. The `settings.json` and `.mcp.json` files are copied from `.template` versions because in the repo they carry placeholder paths; the copy into `.claude/` and the workspace root is where you fill those in.

---

## Stage 2: Fill in your specifics

Three files need editing before the rig will work correctly on your machine.

### CLAUDE.md

Open it and find the mission section near the top. It contains parenthetical placeholders:

```
competing in (write your ctf name here) on the (mention platform).
(format type, jeopardy or attack & defence). Categories: (mention all categories here).
... Flag format is (mention exact flag format) unless a challenge states otherwise.
```

Replace each with your event's real values. For example:

```
competing in Example CTF 2026 on the CTFd platform.
Jeopardy format. Categories: web, pwn, rev, crypto, forensics, misc.
... Flag format is EXAMPLE{...} unless a challenge states otherwise.
```

The flag format matters most. Several agents and the flag-discipline skill reference it, and getting it right is what lets the rig recognize a flag the instant it appears.

### settings.json

This file lists every command Claude Code is allowed to run without stopping to ask. Open `.claude/settings.json` and find the one line that references a home directory:

```json
"Bash(/home/YOUR_USERNAME/ai_tools_venv/bin/*)",
```

Replace `YOUR_USERNAME` with your actual Kali username (run `whoami` if unsure). This grants the rig permission to run the AI-security tools from their isolated environment. If you install that environment somewhere other than your home directory, adjust the path to match.

Everything else in `settings.json` is username-independent and works as-is. The file is covered in detail below under "Understanding settings.json."

### .mcp.json

This defines the two MCP bridges. Open `.mcp.json` and replace `YOUR_USERNAME` in both paths:

```json
"/home/YOUR_USERNAME/.BurpSuite/mcp-proxy/mcp-proxy-all.jar"
"/home/YOUR_USERNAME/tools/GhydraMCP/complete/bridge_mcp_hydra.py"
```

These point at the Burp MCP proxy jar and the Ghidra MCP bridge script. The exact locations depend on where you installed each; [`MCP.md`](MCP.md) walks through installing them and getting the paths right. The Java path (`/usr/lib/jvm/java-21-openjdk-amd64`) is the standard Kali location and usually needs no change, but confirm it with `ls /usr/lib/jvm/` if Burp fails to start.

---

## Stage 3: Create the challenge working folders

The rig expects a folder per category, with one subfolder per challenge inside. The repo does not ship these folders because in real use they hold your solve work and flags, which stay private. Instead, a script creates them fresh.

```bash
cp ~/ctf-rig/scripts/init-workspace.sh .
./init-workspace.sh
```

This creates eight category folders: `web`, `pwn`, `crypto`, `rev`, `forensics`, `ai`, `hardware`, `misc`. The `hardware` and `ai` categories are included deliberately, because the newer competitions include them and being ready for them matters.

The working convention, which the rig follows:

- Each challenge gets its own subfolder, for example `pwn/heap-master/`.
- Inside that subfolder go the challenge files, your `NOTES.md`, and your solve scripts.
- `NOTES.md` and `SUMMARY.md` per challenge are how state survives a session restart. If Claude Code needs to be restarted mid-challenge, those files are what let it pick up where it left off. Writing to them continuously is a core discipline, not an afterthought. See [`LESSONS.md`](LESSONS.md).

---

## Stage 4: Install the toolchain

The rig references a wide set of security tools. On a full Kali install most are already present, but the AI-security toolchain and a few others need explicit installation, and some need version care.

The fastest path is to let the rig install what is missing: launch Claude Code (Stage 6) and run the self-audit prompt from the README, which checks every referenced tool and installs anything absent.

To install by hand, or to understand exactly what the rig expects, see [`TOOLS.md`](TOOLS.md). It covers the standard Kali tools, the AI-security virtual environment (which must be isolated to avoid dependency conflicts), and how to verify each piece actually works.

One thing worth doing before your first real event: confirm the reversing stack. Run the PyGhidra verification in [`TOOLS.md`](TOOLS.md) to make sure headless decompilation actually works end to end, not just that the package is installed.

---

## Stage 5: Wire up the MCP bridges

Two heavyweight GUI tools connect to Claude Code over MCP: Burp Suite for web work and Ghidra for reversing. Each runs its own MCP server that the rig talks to.

[`MCP.md`](MCP.md) is the complete guide. In brief:

- **Burp Suite** needs the MCP Server extension installed from the BApp Store, and the proxy jar whose path you set in `.mcp.json`. There is a known behavior where the extension must be re-enabled after a Burp restart unless a specific setting is on; MCP.md covers it.
- **Ghidra** needs the GhydraMCP bridge script whose path you set in `.mcp.json`, plus a running Ghidra instance. The rig also uses headless PyGhidra as a fallback that needs no GUI.

After both are set up, launching Claude Code and running `/mcp` should show both servers connected.

---

## Stage 6: Launch and audit

Start Claude Code from inside your workspace:

```bash
cd ~/ctf/event
claude
```

Then run the self-audit prompt from the README. Do not skip this. It is the single most effective way to catch a path that did not get filled in, a tool that is missing, or a config that did not copy cleanly, and it does it before you are mid-round depending on the setup.

Once the audit comes back clean, the rig is ready. When a challenge drops, put its files in the right category folder and point Claude Code at it.

---

## Understanding settings.json

The permissions file is worth understanding because it is the security boundary between Claude Code and your machine, and because you will likely want to adjust it.

It has three lists, evaluated in a strict order: **deny wins over ask, ask wins over allow.** A command matching a deny rule is blocked outright and no allow rule can override it.

- **`allow`** lists commands Claude Code runs without asking. The rig allows the full CTF toolchain, common shell utilities, and scoped `sudo` for package installation. Scoping matters: `Bash(sudo apt:*)` allows `sudo apt` but not arbitrary `sudo`.
- **`deny`** blocks the genuinely destructive: recursive deletes at dangerous paths, disk formatting, `dd`, filesystem attribute changes, shutdown and reboot, user deletion, password changes, reading SSH keys, editing the sudoers file. These stay blocked no matter what.
- **`ask`** prompts you before running. By default the rig asks before any `sudo` command not already allowed.

Two top-level settings sit alongside permissions:

- `defaultMode: acceptEdits` lets Claude edit and create files without a prompt for each one, while still confirming other actions. This keeps the rig moving during a round without giving up oversight of shell commands.
- `enableAllProjectMcpServers: true` trusts the MCP servers defined in this workspace's `.mcp.json` without a per-launch approval. This is convenient for a solo rig you control. Be aware of what it means: any MCP server defined in a workspace Claude Code opens will run. Only ever run this in a workspace whose `.mcp.json` you wrote yourself. See [`LESSONS.md`](LESSONS.md) for the fuller reasoning.

If you want tighter control, remove `enableAllProjectMcpServers` and approve the servers manually each launch, or narrow the `allow` list to only the tools you expect a given event to need.

---

## Running two accounts in parallel

The rig supports running two independent Claude Code sessions at once, each on its own account, to work two challenges in parallel. The pattern:

1. Clone the workspace into two directories, for example `~/ctf/event-a` and `~/ctf/event-b`, each a full independent copy.
2. Run one Claude Code session in each, signed into a different account.

The one thing to plan for is the shared GUI tools. Ghidra's MCP bridge connects to whatever binary is open in the GUI, so two sessions hitting one Ghidra instance will collide. The clean approach is to have parallel sessions default to headless PyGhidra decompilation and reserve the single live GUI connection for whichever challenge you are personally driving. The same applies to Burp: both sessions' traffic lands in one proxy history unless you run a second Burp instance on a different port. [`MCP.md`](MCP.md) covers running a second instance.

---

## Important configuration notes

### The flag format lives in more than one place

Setting the flag format in `CLAUDE.md` (Stage 2) is the main step, but the format
is also referenced in the six agent files under `agents/` and in the
`ctf-flag-discipline` skill, where each says "as set in CLAUDE.md for this event."
Those references point back to `CLAUDE.md`, so filling in `CLAUDE.md` is normally
enough. If you prefer to hardcode your event's actual format directly into the
agents and skill instead of relying on the pointer, search for the phrase
`e.g. FLAG{...}` across `agents/` and `skills/ctf-flag-discipline/` and replace it
with your real format. Either approach works; the pointer approach means you only
edit `CLAUDE.md`.

### settings.json is deliberately permissive

The shipped `settings.json.template` includes a broad `Bash` allowance alongside
the detailed scoped tool list. This is an intentional choice for competition
speed: during a timed round you do not want Claude Code stopping to ask before
every unanticipated command. The scoped tool entries document the toolchain the
rig expects, while the broad allowance keeps things moving. The `deny` list still
blocks the genuinely destructive operations regardless, and that is the real
safety boundary.

If you want tighter control, remove the broad `Bash` and broad `sudo` entries from
the `allow` list so only the explicitly scoped tools run without a prompt, and let
everything else fall through to a confirmation. For a shared or less trusted
environment, that tighter posture is the better default.

### cleanupPeriodDays

The template sets `cleanupPeriodDays` to a very large number, which effectively
disables Claude Code's automatic cleanup of old session transcripts. This is
useful during active competition prep, because session history (notes, partial
solves, context) stays available across restarts. Be aware that this means
session transcripts, which can contain challenge data and flags, are retained
indefinitely on your machine. After an event, if you want that history cleaned up
on the normal schedule, lower this value (the Claude Code default is 30 days) or
clear the session data manually.
