# Cloudflare + GitHub Pages TLS Diagnostic Pattern

## Quick Diagnostic Flow

```
User reports: site down, 526 error
     │
     ├─ 1. dig A records → Are they Cloudflare IPs (104.x, 172.x)?
     │      YES → orange cloud ON (Cloudflare proxying)
     │      NO  → gray cloud (DNS-only) — different problem
     │
     ├─ 2. curl -sI http://domain → 200 with X-Github-Request-Id?
     │      YES → HTTP reaches GitHub Pages through Cloudflare
     │
     ├─ 3. curl -sk https://domain → error 526?
     │      YES → TLS broken on CF→origin leg
     │
     └─ 4. Check GitHub Pages settings → "TLS certificate provisioning error"?
            YES → Root cause: orange cloud blocks ACME HTTP-01 challenge
```

## Root Cause

When Cloudflare's orange cloud is ON, it intercepts ALL HTTP requests. GitHub Pages uses Let's Encrypt HTTP-01 challenge to provision TLS certs — it places a file at `.well-known/acme-challenge/...` and Let's Encrypt fetches it. Orange cloud intercepts this fetch, the challenge never reaches GitHub's server, cert provisioning fails.

Without a valid cert on GitHub's side, Cloudflare's `Full (Strict)` mode rejects the CF→origin HTTPS connection → **526 error**.

## The Two-Hop Model

```
Browser ──TLS──▶ Cloudflare ──TLS──▶ GitHub Pages
         ↑ CF cert              ↑ GitHub cert (MISSING → 526)
```

## SSL/TLS Modes (Cloudflare)

| Mode | Browser→CF | CF→Origin | Validates origin? |
|------|-----------|-----------|-------------------|
| Off | HTTP | HTTP | No |
| Flexible | HTTPS | HTTP | No |
| Full | HTTPS | HTTPS | No (accepts any cert) |
| Full (Strict) | HTTPS | HTTPS | Yes (526 if invalid) |

## One-Time Fix Pattern

The cert provisioning is a ONE-TIME problem. After the first cert exists, GitHub auto-renews via Let's Encrypt ~30 days before expiry, and Cloudflare has a built-in exception for `.well-known/acme-challenge/` paths.

**Steps:**

1. Temporarily set SSL mode to **Flexible** (or gray-cloud the DNS)
2. Wait for GitHub Pages to show "TLS certificate is active" (refresh the repo Settings → Pages)
3. Set SSL mode back to **Full**
4. Orange cloud stays ON, renewal is automatic

## Trade-offs

- **Orange cloud ON**: DDoS protection, global CDN caching, but blocks initial cert provisioning
- **Gray cloud (DNS-only)**: No CDN/DDoS, but cert provisioning works immediately
- **Full mode**: Encrypted CF→origin but no origin authentication (MITM possible between CF edge and origin)
- **Full (Strict)**: Encrypted + authenticated, but requires valid cert at origin

## Key Commands for Diagnosis

```bash
# Check DNS records
dig domain.com A +short
dig domain.com CNAME +short
dig domain.com AAAA +short

# Test HTTP (bypasses TLS)
curl -sI http://domain.com

# Test HTTPS
curl -sk https://domain.com

# Check for GitHub Pages headers (confirms traffic reaches GitHub)
curl -sI http://domain.com | grep -i github
```
