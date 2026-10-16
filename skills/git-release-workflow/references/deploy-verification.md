# Deployment Verification — Smart Chatbot

After CI/CD deploys, verify the change actually took effect on the server.

## Verify container picked up the new image

```bash
# Check when the container was created and its CMD
ssh rermork-staging 'docker inspect chatbot_backend_prod --format "Created: {{.Created}} | CMD: {{.Config.Cmd}}"'
```

If the creation timestamp is old or CMD doesn't match what you expect, the
container wasn't recreated. docker compose may not detect the image change if
the tag stayed the same (`smart-chatbot:prod`). Force recreate:

```bash
ssh rermork-staging 'cd /root/smart_chatbot && docker compose -f docker-compose.prod.yml up -d --force-recreate chatbot_backend_prod'
```

## Verify the running process

The CMD in the image config is what gunicorn runs, but confirm the live process:

```bash
ssh rermork-staging 'docker exec chatbot_backend_prod cat /proc/1/cmdline | tr "\0" " "'
```

## Debugging production errors

### 502 / "upstream prematurely closed connection"

nginx returns 502 when the backend worker dies mid-request. Check nginx AND
backend logs at the same timestamp:

```bash
# nginx access log for 502s
ssh rermork-staging 'docker logs chatbot_nginx_prod --since 30m 2>&1 | grep "502"'

# backend — look for WORKER TIMEOUT or crash at the same second
ssh rermork-staging 'docker logs chatbot_backend_prod --since 30m 2>&1 | grep -E "WORKER TIMEOUT|ERROR|Traceback"'
```

Common causes of worker timeout:
- External API calls (Gemini embedding, LLM) taking > gunicorn timeout
- Resource contention (2 workers on 1 vCPU)
- Check: `docker stats --no-stream` for memory/CPU pressure

### Response content truncated (not a connection error)

If the HTTP response is 200 but the answer is cut short:
- Check nginx response body sizes: look for unusually small byte counts
- Likely cause: `CHAT_MAX_OUTPUT_TOKENS` too low for the language/model
- Khmer text tokenizes less efficiently than English — 1024 tokens may not be enough
- Fix: increase `CHAT_MAX_OUTPUT_TOKENS` in production env

### Local dev vs production mismatch

Local dev uses uvicorn (no worker timeout). Production uses gunicorn (30s
default, configurable via `-t`). A slowness that's invisible locally because
uvicorn never kills workers can manifest as timeouts in production.

Always compare:
- Process manager: uvicorn (local) vs gunicorn (prod)
- Gunicorn timeout: `-t` flag on the CMD line
- nginx proxy timeouts: `proxy_read_timeout` in nginx config

## Anti-patterns

### Never edit config files directly on the production server

Editing files directly on the production server (via `sed`, `vim`, `cat >`, etc.)
creates local modifications that cause git merge conflicts the next time the CI/CD
pipeline runs `git pull`. The pipeline (`deploy-prod.yml`) pulls from `main` and
will abort if uncommitted changes exist.

Wrong:
```bash
ssh rermork-staging 'sed -i "s/OLD/NEW/" /root/smart_chatbot/docker-compose.prod.yml'
```

Right: commit the change to the repo, push a PR, merge to `development`, then
release to `main` via `/git-release-workflow` — or if it's a hotfix, ask the
user to decide how to deploy it. Never take it upon yourself.

If you already made this mistake: discard the local change and pull cleanly:
```bash
ssh rermork-staging 'cd /root/smart_chatbot && git checkout -- <file> && git pull origin main'
```

### .env values are not auto-forwarded into Docker containers

Docker Compose reads `.env` for `${VAR}` substitution in the compose file, but
every env var the app needs at runtime must be explicitly listed under
`environment:` in the compose file. A var present in `.env` but absent from the
compose `environment:` block silently resolves to the Python code default.

This has caused three separate production incidents in this project:
`FERNET_KEY`, `SUPER_ADMIN_EMAILS`, and `CHAT_MAX_OUTPUT_TOKENS`.

After adding a new config key:
1. Add it to `.env` / `.env.production`
2. Add `${VAR}` to the compose `environment:` block
3. Verify with `docker exec <container> printenv VAR`
