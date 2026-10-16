# localStorage Testing Patterns

## Problem: `vi.spyOn(Storage.prototype)` leaks across tests

When a test suite has `vi.clearAllMocks()` in `beforeEach`, `vi.spyOn(Storage.prototype, "getItem")` is NOT cleared — `clearAllMocks` only resets `vi.fn()` mocks, not spies. A spy that returns custom values for one test persists into subsequent tests, causing failures.

This is especially subtle because the failing test runs fine in isolation — the pollution only manifests in the full suite, making it look like a flaky async/timing issue.

## Solution: `vi.stubGlobal("localStorage", ...)`

```ts
it("test that needs localStorage", async () => {
  const store: Record<string, string> = { "my-key": "stored-value" };
  vi.stubGlobal("localStorage", {
    getItem: vi.fn((key: string) => store[key] ?? null),
    setItem: vi.fn((key: string, value: string) => { store[key] = value; }),
    removeItem: vi.fn((key: string) => { delete store[key]; }),
  });

  // ... render, interact, assert ...

  // No manual cleanup needed — vi.unstubAllGlobals() in beforeEach handles it
});
```

`vi.stubGlobal` replaces `window.localStorage` for the duration of the test. The existing `vi.unstubAllGlobals()` call in `beforeEach` restores the original `localStorage` before the next test runs, giving perfect isolation.

## When to use which

| Approach | Cleanup | Safe with `clearAllMocks`? |
|---|---|---|
| `vi.spyOn(Storage.prototype, ...)` | Manual `mockRestore()` | ❌ — spy leaks |
| `vi.stubGlobal("localStorage", ...)` | Automatic via `unstubAllGlobals()` | ✅ |

Prefer `vi.stubGlobal` for any test that manipulates `localStorage` state, especially when other tests in the same file also touch storage (WP sync recovery, reindex recovery, etc.).
