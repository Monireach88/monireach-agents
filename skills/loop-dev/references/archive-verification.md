# Archive Verification — /loop-dev pattern for documentation audits

Use this pattern when /loop-dev targets a markdown archive/execution log that needs verification against live systems.

## Shape

- **Profile:** Non-dev (Slot C = adversarial-verifier-general or self-driven)
- **Work source:** The archive file — extract every falsifiable claim
- **Verification:** SSH to live servers, compare output against claims
- **Ledger:** `current_state/.loop_ledger.md` with PASS/FAIL/BLOCKED markers

## How to extract claims

Read the archive file's execution log section (plan sections may be stale). For each claim, ask: "Can I falsify this with a single SSH command or curl?"

Good claims (independently verifiable):
- "9 containers running" → `docker ps` count
- "RAM: 3.9G used" → `free -h`
- "chatbot.monireach.com resolves via Cloudflare" → `dig +short`
- "no nginx container" → `docker ps | grep nginx`

Bad claims (not independently verifiable):
- "Fixed by writing file directly on server" — need to check if it's STILL fixed
- "User confirmed the fix" — can't verify user intent

## Verification flow

1. Batch independent SSH commands (different servers, DNS, local) in parallel terminal calls
2. Compare each output against the archive claim
3. Mark ledger: `[x]` PASS, `[!]` INVALID/FIXED, note discrepancies
4. For PASS-with-caveat (within tolerance), note the variance

## Common pitfalls

- **Hermes masking:** Compose/env files with credential-like strings display as `***`. Use `od -c` to see raw bytes.
- **Container names vs archive names:** Archive may use human-readable names (`smart-chatbot`) while actual containers have compose-generated names (`chatbot_backend_prod`). Match by function, not exact name.
- **RAM is variable:** A claim of "3.9G used" with actual "4.0G used" is within normal fluctuation — mark PASS with note, not FAIL.
- **Stale plan section:** Many archives have a "plan" section written before execution that contains wrong assumptions. Only verify the execution log.
