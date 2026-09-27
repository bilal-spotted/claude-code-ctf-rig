---
name: ctf-ai-security
description: AI and LLM security CTF recipes. Load for any AI hacking category challenge, prompt injection, jailbreak, MCP tool poisoning, agent tool abuse, provided model files, or AI powered filter bypass.
---

# CTF AI Security Recipes

All tools below live in an isolated virtual environment at /home/YOUR_USERNAME/ai_tools_venv, kept separate so version requirements here never fight with pwntools or the rest of the core toolkit. Always invoke by full path, /home/YOUR_USERNAME/ai_tools_venv/bin/TOOLNAME, never by bare name.

## Frameworks
- OWASP LLM Top 10, OWASP MCP Top 10
- MITRE ATLAS (atlas.mitre.org), the AI equivalent of ATT&CK

## Automated probing tools

Garak, NVIDIA's scanner (v0.9.0.4 here). Console launcher confirmed present at the full path:
/home/YOUR_USERNAME/ai_tools_venv/bin/garak --model_type TARGET_TYPE --model_name NAME --probes leakreplay   (system prompt / training data leak)
/home/YOUR_USERNAME/ai_tools_venv/bin/garak --model_type TARGET_TYPE --model_name NAME --probes dan,encoding   (jailbreak and filter bypass)
The launcher is a thin shim over the module, so /home/YOUR_USERNAME/ai_tools_venv/bin/python3 -m garak <same args> is an exact equivalent if the launcher is ever missing after a venv rebuild.

PyRIT (v1.1.0 here), best for Crescendo escalation, used as a Python library from the venv's own python, not a standalone CLI. In 1.x the old orchestrators are "attacks" under pyrit.executor.attack:
/home/YOUR_USERNAME/ai_tools_venv/bin/python3 -c "from pyrit.executor.attack import PromptSendingAttack, CrescendoAttack"
(PromptSendingAttack replaces the pre-1.0 PromptSendingOrchestrator; CrescendoAttack drives multi-turn escalation.)

Promptfoo lives outside the venv, installed globally via npm already:
promptfoo redteam init

## MCP specific challenges

Practice ground for the real patterns, tool poisoning, shadowing, rug pulls, indirect injection: github.com/harishsg993010/damn-vulnerable-mcp-server

Scanning a target server over stdio:
/home/YOUR_USERNAME/ai_tools_venv/bin/mcp-scanner stdio --stdio-command python3 --stdio-arg TARGET_SERVER_PY --format detailed

Static source scan, no live connection needed:
/home/YOUR_USERNAME/ai_tools_venv/bin/mcp-bandit static --path TARGET_SERVER_SOURCE

Both also work against this rig's own configs, a real check worth running once, not just CTF reference:
/home/YOUR_USERNAME/ai_tools_venv/bin/mcp-scanner --scan-known-configs

Read every tool's full description text before touching anything else, a poisoned tool hides its real behavior in text an LLM reads but a human skimming a tool list doesn't.

## Provided model file

Never load an untrusted pickle checkpoint directly:
/home/YOUR_USERNAME/ai_tools_venv/bin/fickling --check-safety SUSPICIOUS_MODEL_PKL

Safetensors/HuggingFace format, read keys without loading the model:
/home/YOUR_USERNAME/ai_tools_venv/bin/python3 -c "from safetensors import safe_open; f = safe_open('MODEL_SAFETENSORS', framework='pt'); print(list(f.keys()))"

Check config.json and tokenizer files by hand for a planted string, strings on the raw weight file, treat "find the trigger phrase" as a backdoor detection problem, feed varied prefixes and diff the output.

## Challenge shape reference

- Direct extraction: role play, "repeat text above", translation round trip, encoding, indirect leak via error text.
- Crescendo: 5 to 20 turn gradual escalation, defeats single-message filters.
- AI powered WAF/filter bypass: obfuscation, instruction smuggling, context overflow.
- Agent/tool abuse: any external data the agent reads is attacker controlled the instant it's ingested.
- Vibe coded app: LLM generated app with a normal web vuln baked in, treat as a standard web challenge once spotted.
- Agent framework RCE: a tool parameter reaching eval/exec/shell/template render in the framework itself. Reference: CVE-2026-26030, Microsoft Semantic Kernel.
