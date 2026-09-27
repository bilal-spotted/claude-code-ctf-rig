# MCP Bridges: Burp Suite and Ghidra

The rig connects to two heavyweight GUI tools over the Model Context Protocol: Burp Suite for web work and Ghidra for reversing. Each runs an MCP server that Claude Code talks to. This guide covers installing both, getting the paths into `.mcp.json` right, the known quirks, and how to run a second instance for parallel sessions.

The two servers are defined in `.mcp.json.template`:

```json
{
  "mcpServers": {
    "burp": {
      "command": "/usr/lib/jvm/java-21-openjdk-amd64/bin/java",
      "args": [
        "-jar",
        "/home/YOUR_USERNAME/.BurpSuite/mcp-proxy/mcp-proxy-all.jar",
        "--sse-url",
        "http://127.0.0.1:9876"
      ]
    },
    "ghydra": {
      "command": "python3",
      "args": [
        "/home/YOUR_USERNAME/tools/GhydraMCP/complete/bridge_mcp_hydra.py"
      ],
      "env": {
        "GHIDRA_HYDRA_HOST": "localhost"
      }
    }
  }
}
```

Replace `YOUR_USERNAME` in both paths with your Kali username, and adjust the jar and script paths to wherever you actually install them.

---

## Burp Suite MCP

### Installing the extension

Burp's MCP support comes from an official PortSwigger extension.

1. Open Burp Suite (Community edition works).
2. Go to **Extensions**, then the **BApp Store** tab.
3. Find **MCP Server** by PortSwigger and click **Install**.

This extension exposes Burp's functionality (sending requests, reading proxy history, driving Repeater and Intruder) to an MCP client. It runs an MCP endpoint that the proxy jar in `.mcp.json` bridges to Claude Code over SSE on port 9876.

### The proxy jar and port

The `mcp-proxy-all.jar` referenced in `.mcp.json` is the stdio-to-SSE bridge. Claude Code speaks to it over stdio; it speaks to the Burp extension over SSE on `127.0.0.1:9876`. Put the jar wherever you like and point the path at it. The port 9876 is Burp's MCP endpoint default; if you change it in the extension's settings, change it in `.mcp.json` to match.

### The extension-must-be-re-enabled quirk

There is a behavior that will bite you if you do not know it. After a Burp restart, the MCP Server extension can come back **unloaded**, so Claude Code reports the Burp server as failed even though nothing is actually broken. This is not the MCP config's fault and not Claude Code revoking anything, it is Burp not reloading the extension.

Two fixes, do both:

1. **Burp Settings, Extensions tab, enable "Automatically reload extensions on startup."** Without this, every extension unloads on restart and must be re-enabled by hand.
2. **After a restart, check Extensions, Installed tab** (not the BApp Store tab), find MCP Server, and confirm the **Loaded** checkbox is ticked.

A related trap: the extension is installed from the BApp Store tab, but its persistent loaded state lives on the Installed tab. If you ever see an "Extension class is not a recognized type" error, you have tried to add the wrong jar as an extension. The MCP Server extension is installed from the BApp Store, not added manually as a jar. The proxy jar in `.mcp.json` is a separate thing, run by Claude Code, never loaded into Burp.

### Use a Project on Disk for real events

Burp's default Temporary Project stores everything in memory and loses it if Burp crashes or closes wrong. For a live round, create a Project on Disk (File, New Project, saved somewhere in your workspace) so your proxy history and testing state survive a crash. This is separate from the extension setting but worth doing at the same time.

### Verifying

With Burp open, the extension loaded, and the proxy running, launch Claude Code and run `/mcp`. The `burp` server should show connected. If it shows failed, walk back through the extension loaded state and confirm the port matches.

---

## Ghidra MCP

### Installing the bridge

The rig uses GhydraMCP, a bridge that exposes a running Ghidra instance to MCP. The `bridge_mcp_hydra.py` script referenced in `.mcp.json` is the bridge; install GhydraMCP wherever you like and point the path at its bridge script.

The bridge connects to a Ghidra instance over a local port. The `GHIDRA_HYDRA_HOST: localhost` environment variable in `.mcp.json` tells it where to look.

### How the single-binary limit works, and why it matters

This is the most important thing to understand about the Ghidra bridge. It connects to whatever single binary is currently open in the Ghidra GUI. It cannot see a second binary through the same connection without that binary actually being loaded into the GUI.

The moment you work a multi-binary challenge, or run analysis against one binary while Ghidra sits open on another, that single GUI slot becomes a bottleneck. Every mismatch costs a detection cycle and a fallback decision mid-challenge.

The rig handles this in the `rev_analyst` agent, which is instructed to confirm which binary is loaded before using the live MCP tools, and to go straight to headless decompilation for any binary that is not the one open in the GUI. The live GUI connection is reserved for the one binary being actively explored interactively (function renaming, cross-reference navigation, type application) where the GUI earns its overhead. Everything else is decompiled headless from the start.

### Headless PyGhidra: the fallback that needs no GUI

The rig does not depend on the Ghidra GUI being open. It uses PyGhidra, which drives Ghidra's decompiler as a plain Python library with no GUI at all. This is the preferred path for headless analysis and for any binary that is not the one loaded in the GUI.

PyGhidra must be installed and pointed at your Python environment. It does not work out of the box just because Ghidra is present. [`TOOLS.md`](TOOLS.md) has the install and, importantly, a real end-to-end verification (decompile an actual function, not just confirm the package imports). Run that verification before relying on it in an event.

Headless gives you the full decompiler and analyzers, identical output quality to the GUI. What it does not give you is Ghidra's interactive debugger, which is GUI-only. For the read-understand-extract workflow that makes up the bulk of reversing and pwn work, headless has everything.

### Verifying

With Ghidra running and a binary loaded, launch Claude Code and run `/mcp`. The `ghydra` server should show connected with its tools available.

---

## Running a second instance for parallel sessions

If you run two Claude Code sessions in parallel (see [`SETUP.md`](SETUP.md)), the shared GUI tools need care so the two sessions do not collide.

### Ghidra

GhydraMCP supports multiple instances by design. Each Ghidra GUI window that opens claims the next port in sequence automatically. So a second Ghidra process self-assigns a different port without hand-editing.

The catch is that auto-discovery finds every running instance on the machine, not just the one belonging to the session that is asking. To keep two parallel sessions from touching each other's Ghidra, pin each workspace's config to its own dedicated port rather than trusting auto-discovery. The exact config key depends on which GhydraMCP variant you installed; check the bridge's own configuration options.

The simpler approach, and the one the rig leans toward, is to have both parallel sessions default to headless PyGhidra and reserve the single live GUI for whichever challenge you are personally driving. That sidesteps the collision entirely.

### Burp

Burp handles concurrent traffic fine, that is its job. The wrinkle is that both sessions' requests land in one shared proxy history, so filtering by target host becomes something to do deliberately. If that gets confusing, run a second Burp instance on a different local proxy port with its own extension load and its own MCP endpoint port, then point the second workspace's `.mcp.json` at that second port.

---

## Adding another MCP server

To add a third MCP server (a pcap analyzer, a different decompiler bridge, a database tool):

1. Add its entry to `.mcp.json` under `mcpServers`, following the same shape as the two existing entries.
2. Grant its tools in `settings.json` under `permissions.allow`, using both forms:
   ```json
   "mcp__servername",
   "mcp__servername__*",
   ```
3. Restart Claude Code so it picks up the new server, and run `/mcp` to confirm it connected.

To remove a server, delete both its `.mcp.json` entry and its two allow entries.

One example worth knowing: for pcap-heavy forensics work, a Wireshark MCP server (a wrapper around `tshark`) can pre-summarize large captures before they consume context. The rig already grants `tshark` directly, so Claude can do the analysis without it, but the MCP wrapper saves context on big captures. If you add one, follow the steps above and grant its tools in `settings.json`.
