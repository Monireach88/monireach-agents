Skill: capture-learning
Context:
Session: implementing PATCH /api/v1/messages/{message_id}/feedback/user endpoint (Sub-task D of Thumbs Up/Down Feedback feature).

MISTAKES MADE:
1. Used `content={"score": 1}` in httpx/TestClient PATCH call — correct param is `json={"score": 1}`. json= sets Content-Type: application/json automatically; content= is for raw bytes.
2. Typed `data: FeedbackResponse = response.json()` — response.json() returns a plain dict, not a Pydantic object. Correct: `data: dict = response.json()`, then `data["message_id"]` to access fields.
3. Passed `data["message_id"]` (a plain str from JSON) directly to `session.get(Message, ...)` — SQLAlchemy UUID columns call .hex on the PK value, which only exists on uuid.UUID objects, not str. Fix: `session.get(Message, uuid.UUID(data["message_id"]))`.

CONCEPTS LEARNED:
1. httpx/TestClient request body params: json= (JSON + sets Content-Type), data= (form), files= (multipart), content= (raw bytes). Use json= for FastAPI Pydantic body endpoints.

2. SQLAlchemy exception handling on write endpoints: wrap only mutating operations (commit) in try/except. Catch SQLAlchemyError as base class. On failure: db.rollback(), raise HTTPException(500) from e. db.get() reads don't need wrapping — failures bubble up as 500 automatically.

3. `raise HTTPException(...) from e` pattern: use when catching one exception type and raising a different one. Preserves the causal chain in the traceback so the original error is visible in logs. Without `from e`, the original exception is hidden.

4. 403 vs 404 for BOLA violations: returning 404 for both "not found" and "wrong tenant" hides resource existence from attackers (GitHub pattern). Returning 403 is more honest to legitimate clients but leaks that the resource exists. For B2B APIs where tenants know their own IDs, 403 is acceptable.

5. Why use body.score instead of message.user_feedback in FeedbackResponse return: message.user_feedback is typed int | None (nullable column), which conflicts with FeedbackResponse.score: Literal[-1, 1]. body.score is already Pydantic-validated as Literal[-1, 1] and was just written to DB, so it's guaranteed correct.

6. REST API sub-resource suffix pattern: /feedback/user and /feedback/tenant as separate endpoints instead of a single endpoint with a discriminator body field. Each maps to one field on the Message model (user_feedback, tenant_feedback). Cleaner separation of concerns, each actor owns their endpoint.

