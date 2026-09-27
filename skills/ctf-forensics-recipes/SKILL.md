---
name: ctf-forensics-recipes
description: Forensics tool-chain recipes for CTF. Load for any forensics challenge to pick the right recipe by artifact, pcap dissection, memory dumps, disk image carving, Windows artifacts, mobile, timeline analysis, browser, git, containers, steganography, documents.
---

# CTF Forensics Recipes

Identify the artifact, then run its recipe.

## PCAP (.pcap/.pcapng)
- Overview: `tshark -r f.pcap -q -z io,phs`
- Follow streams: filter http/ftp/telnet; export objects `tshark -r f --export-objects http,outdir`
- Large/noisy capture: `zeek -r f.pcap` then grep the generated conn.log/dns.log/http.log
- Look for: plaintext creds, DNS tunneling, ICMP data payloads, unusual ports, base64 in payloads, USB HID data

## Memory dump (.raw/.vmem/.lime)
- Identify: `vol -f dump windows.info` (or linux.banner)
- Standard sweep: pslist, pstree, cmdline, netscan, filescan
- Extract: dumpfiles/memmap the suspicious PID, strings the dump, hashdump/lsadump, consoles/cmdscan

## Disk image (.dd/.img/.E01)
- Layout: `mmls img`. List files: `fls -r -o OFFSET img`
- Recover a file: `icat -o OFFSET img INODE > out`
- Carve unallocated: `foremost` or `scalpel`
- Broad pattern pass regardless of filesystem: `bulk_extractor -o out img`

## Windows artifacts
- Registry: RegRipper against SAM/SYSTEM/SOFTWARE/NTUSER.DAT hives for user activity, installed software, run keys
- Event logs: `chainsaw hunt logs.evtx -s sigma_rules/` or `hayabusa csv-timeline -d evtx_folder` for fast rule based triage
- Prefetch: parse .pf files for execution history and timestamps
- $MFT: `analyzeMFT.py -f \$MFT -o mft.csv` for file activity and deletion timestamps
- Shadow copies can hold an earlier state of a file since altered or deleted

## Timeline correlation
- `log2timeline.py timeline.plaso image.dd` then `psort.py -o l2tcsv timeline.plaso` to get one merged csv across filesystem, registry, browser, and event log artifacts

## Mobile
- APK: `apktool d file.apk` for resources, `jadx -d out file.apk` for readable Java, check AndroidManifest.xml and strings.xml
- ADB backup: `abe unpack backup.ab backup.tar` then treat as tar
- iOS backup: find Manifest.db, extract via the domain hashed file structure it references

## Browser artifacts
- Chrome: `sqlite3 History ".dump"` for history/downloads, check Cache and IndexedDB folders directly
- Firefox: places.sqlite for history, same sqlite3 approach

## Git repository
- `git log --all` for every reachable commit, not just current branch
- `git fsck --unreachable --no-reflogs` to find dangling objects
- `git cat-file -p <hash>` to read a dangling blob/commit directly

## Docker/container image
- `docker save image:tag -o out.tar` then extract, each layer is its own tarball
- Walk layers in creation order, a secret in an early layer survives even if a later layer deletes the file

## Steganography
Images, in order:
1. `strings`, `exiftool` (metadata/comments), `binwalk` (appended/embedded)
2. `steghide extract -sf file` (empty pass, then wordlist)
3. `zsteg file.png` (LSB in PNG/BMP), `pngcheck -v` (chunks/anomalies)
Audio:
- Spectrogram first, flags are commonly drawn directly into it
- Stereo channel diff, LSB in samples, morse in tones

## Documents
- Office: `unzip doc.docx` then read XML; `olevba` for macros
- PDF: `pdftotext`, `qpdf --qdf` to expand objects, look for embedded files and JavaScript

## Archives
- `fcrackzip`/`pdfcrack` for password protected files
