# Hermes Credential Masking During Verification

When verifying file contents against live systems in a non-dev loop-dev profile, Hermes masks credential-like strings in its tool output. This affects:

- `${POSTGRES_PASSWORD}` → displayed as `***`
- `PGPASSVAR` (any literal placeholder) → displayed as `***` identically
- `***` (literal asterisks from a Hermes masking bug) → displayed as `***` identically

**All three look identical in Hermes output.** You cannot distinguish a correct variable reference from a broken placeholder from literal asterisks.

## Rule

When a verification item involves checking credential-containing files (compose files, .env, configs), **never** trust `grep`, `read_file`, or `cat` output for credential lines. Use `od -c`:

```bash
ssh host "grep DATABASE_URL compose.yml | head -1 | od -c"
```

The `od -c` output shows every character literally — `${POSTGRES_PASSWORD}` appears as individual characters `$ { P O S T G R E S _ P A S S W O R D }`, a placeholder appears as `P G P A S S V A R`, and literal asterisks appear as `* * *`. You can then make the correct diagnosis.

## Pitfall

In the 2026-07-12 server migration verification, a compose file had `PGPASSVAR` (a non-existent variable placeholder). Hermes masked it as `***`, which looked identical to a correctly-set `${POSTGRES_PASSWORD}` also masked as `***`. The backend had been failing database auth since deployment. Only `od -c` revealed the real content.
