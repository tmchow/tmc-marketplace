---
name: fix-code-review-feedback
description: Address code review feedback by evaluating validity and fixing issues. This skill should be used when the user says "fix the review feedback", "address PR comments", or after a code-review agent produces findings.
user-invocable: true
context: fork
---

# fix-code-review-feedback

Address code review feedback from local review agents or GitHub PRs.

**This skill fixes feedback, not generates it.** Use code review agents to get feedback first, then use this skill to address it.

## Core Principles

> **Agent time is cheap. Tech debt is expensive.**

- **Fix everything valid** - Including nitpicks. Don't carry debt forward.
- **Reviewers can be wrong** - Verify concerns exist before fixing.
- **Quote feedback in replies** - Provide context for what was addressed.

---

## Mode Detection

| Trigger | Mode |
|---------|------|
| Code review agent just provided feedback in conversation | **Local Mode** (auto-invoke) |
| `/fix-code-review-feedback` with no args | **PR Mode - Full** (current branch's PR) |
| User provides link to specific comment/thread | **PR Mode - Targeted** (only that feedback) |
| Ambiguous | Ask user |

**Targeted mode**: When user provides a specific feedback URL, ONLY address that feedback. Do not fetch or evaluate other PR feedback unless user explicitly asks.

---

## Local Mode (Post-Review Agent)

When a code review agent has just provided feedback:

### 1. Parse Feedback
Extract issues from the conversation - typically file:line references with descriptions.

### 2. Evaluate Each Item

| Category | Action |
|----------|--------|
| ✅ Valid concern | Fix (possibly with better approach than suggested) |
| ⚠️ Valid concern, bad suggestion | Fix differently |
| ❌ Invalid (misread code, already handled) | Skip with explanation |
| 🤔 Uncertain | Ask user |

### 3. Fix All Valid Issues
Read files, implement fixes, verify they work. **Do not commit yet.**

### 4. Batch Commit
After ALL fixes are implemented, create a single commit:

```bash
git add -A
git commit -m "Address code review feedback

- [list all changes]"
```

Report what was fixed vs. skipped (with reasons).

---

## PR Mode (GitHub Feedback)

### 1. Determine Scope

**No arguments** → Get current branch's PR:
```bash
gh pr view --json number,headRefName,baseRefName,url,author
```

**Specific feedback URL provided** → Targeted mode:
- Extract thread/comment ID from URL
- Only fetch and address that specific feedback
- Do NOT evaluate other PR feedback unless user asks

### 2. Fetch Feedback

**Targeted mode**: Extract the thread ID from the URL and fetch only that thread via GraphQL `node()` query.

**Full mode**: Use GraphQL to batch-fetch all threads, comments, and reviews:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 50) {
            nodes { id body author { login } createdAt }
          }
        }
      }
      comments(first: 100) {
        nodes { id body author { login } createdAt }
      }
      reviews(first: 50) {
        nodes { id body state author { login } }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUM"
```

### 3. Check for Stale Feedback

For comments referencing specific lines, verify the code still matches:
```bash
git show HEAD:$FILE_PATH | sed -n "${LINE}p"
```

If code changed significantly, verify concern still applies before acting.

### 4. Evaluate Validity

Same framework as Local Mode.

### 5. Fix All Valid Issues

Read files, implement fixes, verify. **Do not commit yet** - batch all fixes.

### 6. Reply to Threads

Quote the original feedback:

```markdown
> [original feedback]

Addressed: [brief description]
```

For invalid feedback:
```markdown
> [original feedback]

Not addressing: [reason with evidence, e.g., "null check exists at line 85"]
```

Reply via GraphQL:
```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewComment(input: {
    pullRequestReviewThreadId: $threadId
    body: $body
  }) { comment { id } }
}' -f threadId="$THREAD_ID" -f body="$REPLY_BODY"
```

### 7. Resolve Threads

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_ID"
```

### 8. Batch Commit and Push

Single commit for all fixes:

```bash
git add -A
git commit -m "Address PR review feedback

- [list all changes]
- [threads resolved]"
git push
```

---

## GitHub CLI Usage

Always use `gh` CLI. Fall back to GitHub MCP only if `gh` fails.

**Prefer high-level commands. Only use `gh api` when required:**

| Operation | Command | Why |
|-----------|---------|-----|
| PR metadata | `gh pr view --json ...` | High-level, efficient |
| Add PR comment | `gh pr comment --body ...` | High-level, efficient |
| Fetch review threads | `gh api graphql` | **Required** - no CLI equivalent |
| Reply to thread | `gh api graphql` | **Required** - no CLI equivalent |
| Resolve thread | `gh api graphql` | **Required** - no CLI equivalent |

Do NOT use `gh api` for operations that have high-level equivalents.

---

## Validity Evaluation

```
1. Can I reproduce the concern?
   NO → Skip (explain why)

2. Is concern still relevant to current code?
   NO → Skip (explain code changed)

3. Would the fix improve the code?
   YES → Implement
   NO but concern valid → Implement better alternative
   NO and concern wrong → Skip (explain)
```

**When to ask user:** Architectural changes, security implications, conflicting conventions, business logic decisions.

---

## Examples

### PR Mode - Full

```
User: /fix-code-review-feedback

Agent:
Fetching feedback for current branch's PR (#123)...

Found 3 unresolved threads:

1. ✅ "Missing null check on user.email"
   → Adding null check at auth.js:45

2. ✅ "Unused import: lodash"
   → Removing unused import

3. ❌ "No error handling for API call"
   → Invalid: try/catch exists at line 78. Replying with explanation.

Committed and pushed. 2 fixed, 1 declined.
```

### PR Mode - Targeted

```
User: /fix-code-review-feedback https://github.com/org/repo/pull/123#discussion_r1234567

Agent:
Fetching specific feedback...

Thread: "Missing null check on user.email"
→ Valid concern. Adding null check at auth.js:45

Replied, resolved thread, committed and pushed.
```

### Local Mode (Auto-Invoked)

```
[After code review agent provides feedback in conversation]

Agent:
Processing review feedback...

1. ✅ Race condition at api.ts:23 → Adding mutex lock
2. ✅ Missing type at api.ts:45 → Adding `: Error` annotation

All issues addressed and committed.
```
