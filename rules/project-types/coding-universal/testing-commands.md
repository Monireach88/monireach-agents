# §13. Test Command Output Preferences

Always use short output flags when running pytest — this saves tokens and keeps the session readable.

## pytest flags (universal)

| When | Command suffix |
|---|---|
| Single test file or function | `pytest <path>::<test_name> -rAq --tb=short` |
| Full test suite | `pytest <suite_root> -q --tb=no` |

**If a full-suite run shows a failure:** re-run the specific failing test with `--tb=short` to get the traceback.

## Project-specific prefix

The prefix before `pytest` varies per project — check the project's memory or CLAUDE.md:

- Docker-based projects: `docker compose exec <service> uv run pytest ...`
- Local venv: `uv run pytest ...` or `pytest ...`

Never assume the prefix — read the project context first.
