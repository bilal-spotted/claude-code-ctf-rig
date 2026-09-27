# Tool Manifest and Verification

This is the complete list of tools the rig references, how to install the pieces that are not standard on Kali, and how to verify each part actually works rather than just that a package is present. The distinction matters: several tools install cleanly but fail on first real use for reasons that are much easier to catch now than mid-round.

The fastest way through this is the self-audit prompt from the README, which has Claude Code check every referenced tool and install what is missing. This document is for installing by hand, for understanding what the rig expects, and for the verifications that the audit alone does not force.

---

## Standard Kali tools

Most of what the rig uses ships with a full Kali install. These are granted in `settings.json` and used across the agents and skills. If any are missing on your box, `sudo apt install <tool>` covers them.

**Web:** ffuf, feroxbuster, gobuster, dirb, nikto, whatweb, wfuzz, sqlmap, hydra

**Binary and reversing:** gdb, radare2, objdump, readelf, nm, strings, file, xxd, hexdump, patchelf, checksec, ROPgadget, one_gadget, ltrace, strace

**Crypto and hashing:** john, hashcat, sage (SageMath), plus the standard sha/md5 utilities and base64/base32

**Forensics:** tshark, tcpdump, binwalk, foremost, scalpel, steghide, zsteg, stegsnow, exiftool, exiv2, pngcheck, volatility3 (`vol`), sleuthkit (`fls`, `icat`, `mmls`), testdisk, fcrackzip, pdfcrack, qpdf, pdftotext

**General:** python3, pip, nc, socat, curl, wget, httpie, docker, git, and the usual shell utilities

The forensics agent also references some tools that may need installation on a minimal Kali: `zeek` for fast pcap logging, `chainsaw` or `hayabusa` for Windows event log triage, `plaso`/`log2timeline` for timeline correlation, `regripper` for registry hives, `apktool` and `jadx` for mobile, `olevba` for Office macros, `bulk_extractor` for pattern carving. Install these as challenges call for them, or let the self-audit prompt pull them.

---

## The reversing stack: PyGhidra

The rig uses PyGhidra for headless decompilation. It does not work out of the box just because Ghidra is installed; the package must be installed and pointed at your Python environment.

### Install

Locate your Ghidra install and install PyGhidra from its bundled package (this matters, a mismatched PyGhidra version causes subtle breakage):

```bash
GHIDRA=$(ls -d /opt/ghidra* /usr/share/ghidra* 2>/dev/null | head -1)
echo "Ghidra install: $GHIDRA"
python3 -m pip install --no-index -f "$GHIDRA/Ghidra/Features/PyGhidra/pypkg/dist" pyghidra --break-system-packages
```

### Verify for real

Confirming the package imports is not enough. The real test is decompiling an actual function end to end. Note two things this test accounts for: PyGhidra writes its project folder next to the binary, so the binary must be somewhere you can write (not `/bin`), and a stripped binary may not have a function literally named `main`, so the test falls back to the first function it finds.

```bash
mkdir -p ~/pyghidra_test
cp /bin/ls ~/pyghidra_test/
python3 -c "
import pyghidra
pyghidra.start()
with pyghidra.open_program('$HOME/pyghidra_test/ls', analyze=True) as flat_api:
    program = flat_api.getCurrentProgram()
    funcs = list(program.getFunctionManager().getFunctions(True))
    print(f'Total functions found: {len(funcs)}')
    from ghidra.app.decompiler import DecompInterface
    ifc = DecompInterface()
    ifc.openProgram(program)
    target = next((f for f in funcs if f.getName() == 'main'), funcs[0])
    print(f'Decompiling: {target.getName()} at {target.getEntryPoint()}')
    result = ifc.decompileFunction(target, 60, None)
    print(result.getDecompiledFunction().getC()[:500])
"
```

A non-zero function count and real pseudo-C output means the whole pipeline works. That is the verification to trust, not the install log.

---

## The AI-security toolchain

This is the part that needs the most care, because the AI-security tools have heavy, conflicting dependencies that will damage the rest of your Kali Python environment if installed globally. **Install them in an isolated virtual environment.** The rig's `ctf-ai-security` skill and `ai_redteam` agent both invoke these tools by full path into that environment, precisely so their dependencies never fight pwntools or anything else on the box.

### Why isolation is not optional

Installed globally alongside Kali's existing security tools, these packages force version downgrades that break unrelated tools (pwntools' unicorn dependency, among others). A virtual environment keeps them walled off. The rig's paths assume the environment lives at `~/ai_tools_venv`; if you put it elsewhere, update the path in `settings.json`, the `ctf-ai-security` skill, and the `ai_redteam` agent.

### Install

```bash
python3 -m venv ~/ai_tools_venv
~/ai_tools_venv/bin/pip install --upgrade pip
~/ai_tools_venv/bin/pip install garak pyrit fickling transformers safetensors mcp-bandit cisco-ai-mcp-scanner
```

This pulls a large dependency tree and takes several minutes. If your network drops mid-install, just run the same command again; pip skips what is already present and only fetches what did not finish.

Promptfoo is a separate Node tool, installed globally via npm. If npm's global install fails with a permissions error, point npm at a user-owned prefix first:

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g promptfoo
```

### Verify

Confirm each tool resolves. Note that garak may not register a console-script entry point depending on the version, so it is invoked as a module if the direct binary is absent, and the skill documents both forms:

```bash
~/ai_tools_venv/bin/garak --version || ~/ai_tools_venv/bin/python3 -m garak --version
~/ai_tools_venv/bin/fickling --help
~/ai_tools_venv/bin/mcp-scanner --help
~/ai_tools_venv/bin/mcp-bandit --help
promptfoo --version
```

### What each tool is for

| Tool | Role |
|------|------|
| garak | LLM vulnerability scanner, many probe modules (system prompt leak, jailbreak, encoding bypass) |
| pyrit | Multi-turn attack orchestration, used as a Python library (Crescendo-style escalation) |
| promptfoo | Breadth red-team scanning against OWASP LLM presets |
| fickling | Static analysis of pickle files, to check a model checkpoint before loading it |
| mcp-scanner | Cisco's MCP security scanner (stdio, remote, and static modes; tool-poisoning detection) |
| mcp-bandit | MCP server static and dynamic analysis, docstring/behavior mismatch detection |
| transformers, safetensors | Reading model files and weights without executing them |

The `ctf-ai-security` skill has the exact invocations for each, with the full venv paths.

---

## A note on dependency conflict warnings

When installing the AI-security tools, and to a lesser extent other pip installs on a busy Kali box, you will see a wall of "dependency resolver" conflict warnings mentioning tools like faraday, theharvester, netexec. Most of these are pre-existing version mismatches on the Kali image, not something your install created. The isolated virtual environment is specifically what keeps the AI tools from adding to that pile. As long as the verification commands above succeed, the warnings about unrelated tools are noise.

---

## Wordlists

The rig's web and fuzzing work depends on knowing where wordlists actually live, which is baked into `CLAUDE.md` so Claude does not waste time searching for them mid-fuzz. The standard Kali locations:

- **Web content discovery:** `/usr/share/seclists/Discovery/Web-Content/` holds the raft lists (raft-large-directories.txt, raft-medium-files.txt, and so on), plus common.txt and big.txt. Note the DirBuster lists there carry a `DirBuster-2007_` filename prefix, so the file is `DirBuster-2007_directory-list-2.3-medium.txt`, not the short name.
- **Passwords:** `/usr/share/seclists/Passwords/`, including Common-Credentials, Default-Credentials, Leaked-Databases.
- **Usernames:** `/usr/share/seclists/Usernames/`, including xato-net-10-million-usernames.txt.
- **rockyou:** already extracted at `/usr/share/wordlists/rockyou.txt`, no need to gunzip.

If your Kali does not have SecLists, install it with `sudo apt install seclists`. If your wordlists live elsewhere, update the paths in `CLAUDE.md` to match your box, following the same "known paths" section already there.
