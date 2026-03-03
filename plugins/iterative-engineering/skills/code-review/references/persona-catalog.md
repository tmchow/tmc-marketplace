# Persona Catalog

8 reviewer personas organized in two tiers. The orchestrator uses this catalog to select which reviewers to spawn for each review.

## Always-on (3)

Spawned on every review regardless of diff content.

| Persona | Agent file | Focus |
|---------|-----------|-------|
| `correctness` | `agents/correctness-reviewer.md` | Logic errors, edge cases, state bugs, error propagation, intent compliance |
| `testing` | `agents/testing-reviewer.md` | Coverage gaps, weak assertions, brittle tests, missing edge case tests |
| `maintainability` | `agents/maintainability-reviewer.md` | Coupling, complexity, naming, dead code, premature abstraction |

## Conditional (5)

Spawned when the orchestrator identifies relevant patterns in the diff. The orchestrator reads the full diff and reasons about selection — this is agent judgment, not keyword matching.

| Persona | Agent file | Select when diff touches... |
|---------|-----------|---------------------------|
| `security` | `agents/security-reviewer.md` | Auth middleware, public endpoints, user input handling, permission checks, secrets management |
| `performance` | `agents/performance-reviewer.md` | Database queries, ORM calls, loop-heavy data transforms, caching layers, async/concurrent code |
| `api-contract` | `agents/api-contract-reviewer.md` | Route definitions, serializer/interface changes, event schemas, exported type signatures, API versioning |
| `data-migrations` | `agents/data-migrations-reviewer.md` | Migration files, schema changes, backfill scripts, data transformations |
| `reliability` | `agents/reliability-reviewer.md` | Error handling, retry logic, circuit breakers, timeouts, background jobs, async handlers, health checks |

## Selection rules

1. **Always spawn all 3 always-on personas.**
2. **For each conditional persona**, the orchestrator reads the diff and decides whether the persona's domain is relevant. This is a judgment call, not a keyword match.
3. **Announce the team** before spawning with a one-line justification per conditional reviewer selected.
