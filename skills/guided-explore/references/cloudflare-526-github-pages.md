# Cloudflare 526 + GitHub Pages TLS Diagnosis

## Symptom

`https://example.com` returns Cloudflare error 526 "Invalid SSL certificate." HTTP (port 80) works fine and returns content from the origin. GitHub Pages Settings shows "TLS certificate is being provisioned" stuck indefinitely, sometimes with "Certificate Request Error."

## Root cause

Cloudflare's orange-cloud (proxy) intercepts all HTTP traffic before it reaches GitHub Pages. GitHub Pages provisions TLS certificates via Let's Encrypt HTTP-01 challenge: it serves a file at `http://example.com/.well-known/acme-challenge/<token>` and Let's Encrypt fetches it. With orange cloud on, Cloudflare catches that request — the challenge file never reaches GitHub's server. GitHub retries silently and never issues a cert. Without a valid origin cert, Cloudflare's SSL mode Full (Strict) rejects the CF→origin TLS handshake → 526.

## Diagnosis steps

```
# 1. Check DNS — are A records pointing to Cloudflare proxy IPs or origin IPs?
dig example.com A +short
# Cloudflare proxy IPs (104.21.x.x, 172.67.x.x) → orange cloud is ON
# GitHub Pages IPs (185.199.108.153 etc.) → gray cloud / DNS only

# 2. Check HTTP vs HTTPS
curl -sI http://example.com   # Should return 200 with origin headers
curl -sI https://example.com  # Should return 526

# 3. Confirm Cloudflare is proxying
# HTTP response will have cf-ray, cf-cache-status headers
# Or: server: cloudflare in response headers

# 4. Confirm GitHub Pages is the origin
# HTTP response should have x-github-request-id header
```

## Fix

**Option A — Temporary gray cloud (recommended):**
1. In Cloudflare DNS, click orange cloud → gray cloud for all A records
2. Ensure A records point to GitHub Pages IPs: 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
3. Wait for GitHub Pages to provision TLS cert (refresh Settings → Pages)
4. Verify HTTPS works directly (`curl -sI https://example.com` → 200)
5. Re-enable orange cloud; set SSL/TLS mode to Full (Strict)
6. Verify end-to-end

**Option B — Flexible SSL mode (less secure):**
1. Cloudflare SSL/TLS → set encryption mode to Flexible
2. Wait for cert to provision
3. Switch back to Full (Strict)

Option A is preferred: no security downgrade, one step.

## Pitfalls

- **Full → Strict after provisioning:** Once GitHub has a valid cert, Full (Strict) works. If renewal fails in the future, Strict will 526 again — but that's the correct signal that something needs fixing.
- **Renewal is automatic** once the first cert exists. GitHub auto-renews ~30 days before expiry. The ACME challenge for renewal also uses HTTP-01, but Cloudflare has a built-in exception for `.well-known/acme-challenge/` paths.
- **Google Sites favicon cache:** After migrating from Google Sites, browser/Cloudflare cache may still serve the old `/favicon.ico`. Purge Cloudflare cache for favicon paths or wait for cache expiry.
