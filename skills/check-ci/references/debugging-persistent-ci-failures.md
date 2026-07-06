# Debugging Persistent CI Failures (Not Flakes)

When a CI failure survives a rerun but the same code passes in Docker/local,
don't stop at "it's environmental." The gap between CI and local IS the clue.

## Systematic Comparison Checklist

1. **Check PostgreSQL/DB version mismatch**
   - CI service container vs docker-compose image version
   - Example: CI used `postgres:16`, Docker used `postgres:15-alpine`

2. **Check Python point release + compiled extensions**
   - Same major.minor but different `sqlite3` library builds (Ubuntu vs Debian)
   - SQLite type affinity can differ subtly between library versions

3. **Check module-level import side effects**
   - Example: `app/models/database.py` had `engine = create_engine(config.database_url)`
     at module level. In CI, DATABASE_URL=postgresql://...; tests override get_db
     but the PostgreSQL dialect still loads at import time. Rarely causes issues,
     but worth noting.

4. **Check test ordering**
   - If only the LAST test in a module fails, suspect cumulative state corruption
   - In-memory SQLite + StaticPool shares one connection across tests; drop_all/create_all
     should reset but edge cases exist

5. **Check for unnecessary DB round-trips**
   - `session.refresh(obj)` after `session.commit()` is a defensive pattern that
     can trigger driver-specific type processor bugs
   - If no test depends on the refreshed state, remove the refresh

## Specific Failure Pattern: SQLite UUID → float

Error: `AttributeError: 'float' object has no attribute 'replace'`
Trace: `sqlalchemy/sql/sqltypes.py` UUID type processor → `uuid.UUID(value)`

This happens when SQLAlchemy's UUID result processor receives a float from the
SQLite cursor instead of a string. Only manifests on certain SQLite library builds
(GitHub Actions Ubuntu runner, not Debian-based Docker images).

Fix: remove unnecessary `session.refresh()` calls. The data is already in the ORM
object after commit; refresh only needed for server-generated defaults not captured
client-side.

## General Principle

If a test passes in Docker but fails in CI after reruns: prioritize making the
test less dependent on DB driver internals over debugging the exact library version
difference. Remove unnecessary refresh/round-trip patterns rather than chasing
SQLite build numbers.
