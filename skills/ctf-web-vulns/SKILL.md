---
name: ctf-web-vulns
description: Web vulnerability attack catalog for CTF. Load when analyzing any web/HTTP challenge to systematically check SQLi, SSTI, SSRF, XXE, IDOR, JWT flaws, prototype pollution, deserialization, path traversal, command injection, open redirect, auth bypass, and race conditions. Provides the fastest confirming test and exploitation path per class.
---

# CTF Web Vulnerability Catalog

Work top-down. For each class: the tell (what hints at it), the fastest

confirm, then the exploit path.

## SQL Injection

- Tell: input reaching a query, login forms, id/search params, DB errors.

- Confirm: `'` then `' OR '1'='1`; time-based `' OR SLEEP(5)-- -`.

- Exploit: sqlmap for automation; manual UNION for column count via

  ORDER BY; extract via information_schema. Blind = boolean/time oracle.

## Server-Side Template Injection (SSTI)

- Tell: input reflected into a page, Python/Flask/Jinja, Node/handlebars.

- Confirm: `{{7*7}}` -> 49; `${7*7}`; `<%= 7*7 %>`. Identify engine.

- Exploit: Jinja2 -> `{{cycler.__init__.__globals__.os.popen('id').read()}}`

  or config/class traversal to RCE. Note the engine before payloading.

## SSRF

- Tell: URL/host params, webhook, image fetch, PDF render, "url=".

- Confirm: point at your listener; check for internal metadata endpoints.

- Exploit: reach 127.0.0.1 internal services, cloud metadata (169.254.169.254),

  file:// scheme, gopher:// for raw protocol smuggling.

## XXE

- Tell: XML upload/parse, SOAP, SVG, docx.

- Confirm: external entity to read /etc/passwd via DOCTYPE.

- Exploit: file read; blind XXE via external DTD + OOB exfil.

## IDOR / Access Control

- Tell: object ids in URL/body (?id=, /user/5), predictable references.

- Confirm: increment/decrement/swap the id, observe others' data.

- Exploit: enumerate ids; try admin-only routes; method tampering.

## JWT

- Tell: eyJ... tokens in cookies/headers.

- Confirm: decode header; check alg. Look for weak/none.

- Exploit: alg:none, HS256/RS256 confusion (sign with public key as HMAC

  secret), weak HMAC secret (crack with hashcat/john), kid injection.

## Prototype Pollution (Node)

- Tell: JSON merge, lodash/deep-merge, query parsing.

- Confirm: send __proto__ / constructor.prototype keys, check pollution.

- Exploit: gadget to RCE or auth bypass depending on downstream sink.

## Insecure Deserialization

- Tell: base64 blobs, PHP serialized (O:...), Python pickle, Java (rO0),

  Node node-serialize.

- Exploit: craft malicious object; PHP POP chains; pickle __reduce__;

  ysoserial for Java.

## Path Traversal / LFI

- Tell: file/page/include params.

- Confirm: ../../../etc/passwd, encodings, null byte on old PHP.

- Exploit: LFI to RCE via log poisoning, php://filter to leak source,

  data:// or php://input wrappers.

## Command Injection

- Tell: ping/dns/convert features, input passed to shell.

- Confirm: `; id`, `| id`, `$(id)`, backticks, %0a newline.

## Open Redirect / Race Conditions

- Redirect: next/return/url params -> chain into SSRF/OAuth theft.

- Race: parallel requests on limited actions (coupons, balance), use

  ffuf/turbo intruder style concurrency.

## Workflow

1. Fingerprint stack (whatweb, headers) to prioritize likely classes.

2. If source given, trace input->sink; the sink names the vuln.

3. Confirm cheaply before building the full exploit.

4. Default to scripted, repeatable HTTP (python requests, httpie, curl, ffuf, sqlmap) so exploits are reproducible. The Burp MCP is connected too for your use: use it to read proxy history (get_proxy_http_history), inspect requests the browser/human generated, and send requests whenever you need.

