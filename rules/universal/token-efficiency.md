# §11. Reading Files Efficiently

## §11.1 Read only what you need
Never read a large file in full when part of it is enough. Search first, then read line ranges.

## §11.2 Knowledge files
Read the table of contents first (about 30 lines), then every section that plausibly matches. When adding a section, append it at the end and update the table of contents; create one if it is missing.

## §11.3 Logs and other append-only files
Read from the end: the last 50 lines, then 100, then 200, until you find today's date or confirm it is absent. Never read from the start.

## §11.4 Output
Sending him text he did not need is the same waste as reading a file you did not need (plain-language §1).
