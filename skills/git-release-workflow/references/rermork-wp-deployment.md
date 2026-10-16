# rermork-wp: WordPress + RunCloud Deployment Pattern

This project differs from the generic release workflow in critical ways. Do not apply
the Docker Compose / CI/CD assumptions from the parent skill here.

## Environment split

| Layer | Local | Production |
|---|---|---|
| Runtime | Docker (`docker-compose up -d`) | Bare-metal RunCloud (no Docker) |
| Config source | `.env` (gitignored) → `docker-compose.yml` env vars → `getenv()` in PHP | `wp-config.php` constants → `defined()` in PHP |
| Code deploy | N/A (local) | `git pull` on server (branch `main` only) |
| CI/CD | None | None |

## Config resolution pattern (12-factor, dual-path)

`functions.php` reads config with this priority:
1. `defined('CONSTANT_NAME')` → `constant('CONSTANT_NAME')`  (production: `wp-config.php`)
2. `getenv('CONSTANT_NAME')`  (local: Docker passes from `.env`)

So deploying a feature that uses this pattern requires TWO steps on production:
1. `git pull` to get the new `functions.php` code
2. Add `define()` lines to `wp-config.php` for any new constants

Example for the chatbot widget:
```php
define('SMART_CHATBOT_WIDGET_BASE', 'https://chatbot.monireach.com');
define('SMART_CHATBOT_API_KEY', 'startupDemoApiKey935109632183452');
```

## Production server access

- SSH: `ssh rermork-monireach`
- Web root: `/home/runcloud/webapps/rermork`
- Branch: `main` ONLY — never checkout feature branches on production
- Logged-in user is `monireach` — NOT `runcloud`
- `sudo -u runcloud` does NOT work in non-interactive SSH sessions (sudo prompts for password;
  there is no NOPASSWD rule for monireach). Do not attempt it.
- `git pull` works as `monireach` IF the user has an SSH key authorized on GitHub
  (see "SSH key for git pull" below)
- `wp-config.php` is readable AND writable by `monireach` — no sudo needed for edits
- All other git operations (`status`, `log`, `diff`) work without sudo

### SSH key for git pull

The `monireach` user on the production server needs an SSH key registered as a GitHub
deploy key for the `rermork-ngo/rermork-wp` repo. Without this, `git pull` fails with
"Permission denied (publickey)".

**One-time setup (if key doesn't exist or git pull fails):**

```bash
# 1. Generate key on the production server
ssh rermork-monireach 'ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "monireach@rermork-prod"'

# 2. Get the public key
ssh rermork-monireach 'cat ~/.ssh/id_ed25519.pub'
# Copy the output

# 3. Add as deploy key on GitHub (run locally, NOT on production)
echo "<public-key-from-step-2>" > /tmp/rermork-deploy-key.pub
gh repo deploy-key add /tmp/rermork-deploy-key.pub \
  --repo rermork-ngo/rermork-wp \
  --title "rermork-prod-monireach" \
  -w

# 4. Set upstream tracking if missing (one-time)
ssh rermork-monireach 'cd /home/runcloud/webapps/rermork && git branch --set-upstream-to=origin/main main'
```

### Editing wp-config.php on production

`wp-config.php` is gitignored and lives only on the server. Edits must be done via SSH.
Use `sed` for insertions — anchor on a unique adjacent line:

```bash
ssh rermork-monireach "sed -i '/define.*RERMORK_R2_PUBLIC_HOST/a\\
/* Smart Chatbot widget embed */\\
define('SMART_CHATBOT_WIDGET_BASE', 'https://chatbot.monireach.com');\\
define('SMART_CHATBOT_API_KEY', 'startupDemoApiKey935109632183452');' \\
/home/runcloud/webapps/rermork/wp-config.php"
```

Always verify with `php -l` (lint check) and `grep` after editing.

## Production config values location

The rermork-wp project itself has NO production secrets stored in its repo.
Production values for cross-project integrations live in the sibling project's `.env.production`:
- Smart Chatbot widget: `/Users/monireach/projects/smart_chatbot/.env.production`
  - `WIDGET_BASE_URL` → maps to `SMART_CHATBOT_WIDGET_BASE`

**⚠️ CRITICAL PITFALL: Widget API key ≠ backend DEMO_API_KEY**

The smart_chatbot backend's `DEMO_API_KEY` in `.env.production` is the backend's own internal
demo tenant key — it is NOT the widget embed API key. These are completely separate keys
generated in different places:

- `DEMO_API_KEY` (e.g., `startupDemoApiKey...`) — backend internal key; DO NOT use this
  for the widget embed
- Widget embed API key (e.g., `oa-jAvTvRJE...`) — generated from the smart_chatbot
  **admin console → Go Live page**; this is the correct value for `SMART_CHATBOT_API_KEY`

Using the wrong key causes the widget to fail to authenticate against the backend.
Always get the widget key from the admin console, never from `.env.production`.

## SSH key for git pull on production

The `monireach` user on the production server needs an SSH key registered as a GitHub
deploy key for `rermork-ngo/rermork-wp`. Without this, `git pull` fails with
"Permission denied (publickey)".

**One-time setup (if key doesn't exist or git pull fails):**

```bash
# 1. Generate key on the production server
ssh rermork-monireach 'ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "monireach@rermork-prod"'

# 2. Get the public key
ssh rermork-monireach 'cat ~/.ssh/id_ed25519.pub'

# 3. Add as deploy key on GitHub (run locally, NOT on production)
echo "<public-key-from-step-2>" > /tmp/rermork-deploy-key.pub
gh repo deploy-key add /tmp/rermork-deploy-key.pub \
  --repo rermork-ngo/rermork-wp \
  --title "rermork-prod-monireach" \
  -w

# 4. Set upstream tracking if missing (one-time)
ssh rermork-monireach 'cd /home/runcloud/webapps/rermork && git branch --set-upstream-to=origin/main main'
```

## Deployment sequence (no CI/CD — manual)

1. Commit + push on feature branch (local)
2. Merge to `main` via PR or local merge
3. Push `main` to GitHub
4. SSH to production: `ssh rermork-monireach`
5. Verify state: `git branch --show-current` (must be `main`), `git log -1`
6. Pull: `git pull` (as `monireach` — SSH key must be set up, see above)
7. Edit `wp-config.php` if new constants needed (see "Editing wp-config.php" above)
8. Verify: `php -l wp-config.php`, then visit site to confirm widget/feature renders

## CORS consideration

When embedding cross-origin widgets (e.g., `rermork.org` → `chatbot.monireach.com`),
the production origin must be in the backend's CORS allow-list. This config lives in
the backend project (smart_chatbot), not in rermork-wp. Verify via browser devtools
after deployment — if requests fail with CORS errors, add the origin to the backend.
