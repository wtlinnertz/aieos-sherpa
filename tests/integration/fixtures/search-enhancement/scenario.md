# P2 Enhancement Test Scenario: Full-Text Search for Task API

## Initiative
- Name: TASKSEARCH
- Preset: P2 (Enhancement)
- Topic: Add full-text search to existing task management REST API

## User Responses (in conversation order)

### Initial request
We have a task management API that currently only supports filtering by status and assignee. I want to add full-text search so users can search tasks by title and description. I know exactly what I need — it's a bounded enhancement to our existing API.

### Clarifying question: scope clarity
Yes, the scope is clear. We need a new GET /tasks/search endpoint that accepts a query string parameter, searches across task title and description fields, and returns matching tasks ranked by relevance. We're using PostgreSQL with the existing tasks table. Acceptance criteria: returns results in under 200ms for tables up to 100k rows, supports partial word matching, highlights matched terms in the response.

### Clarifying question: discovery needed?
No, we don't need discovery. The problem is well-understood — users have been asking for search for months, and we know exactly what to build. This is a straightforward addition to our existing API.

### Confirm preset
Yes, P2 Enhancement is correct.

### Initiative name
TASKSEARCH

### KER Path B justification
We're choosing Path B (direct EEK entry) because: (1) the feature scope is bounded — single endpoint addition to an existing API, (2) user need is validated through support ticket volume — 23 requests in the last quarter, (3) solution approach is known — PostgreSQL full-text search with tsvector/tsquery, (4) no architectural ambiguity — extends existing REST patterns. No PIK discovery is needed.

### Product Brief responses
**Problem:** Users cannot find tasks without knowing the exact status or assignee. The API only supports structured filters, not free-text search. This forces users to scroll through task lists manually or use workarounds like browser find on the UI. 23 support tickets in Q4 requested search functionality.

**Solution:** Add a full-text search endpoint using PostgreSQL's built-in tsvector/tsquery. Index task titles and descriptions. Return results ranked by relevance with highlighted match snippets.

**Acceptance criteria:** (1) GET /tasks/search?q=<query> returns matching tasks, (2) Response time under 200ms for up to 100k rows, (3) Supports partial word matching, (4) Match highlights included in response, (5) Empty query returns 400 error, (6) Results respect existing authorization — users only see tasks they have access to.

**Non-goals:** Not building a general-purpose search engine. Not indexing comments, attachments, or audit logs. Not supporting boolean operators or advanced query syntax in v1.

### Cross-cutting kit decisions
QAK: decline — this is a small enhancement with straightforward testing, standard unit + integration tests are sufficient.
SCK: decline — no new attack surfaces, search uses parameterized queries, existing auth applies.
DKK: decline — API docs will be updated as part of the implementation, no separate UDR needed.
DCK: decline — no feature flags or configuration changes needed.

### After each validation
(User confirms and sherpa proceeds)

### ACF context
We use Express.js with TypeScript, PostgreSQL 15, Prisma ORM. The project follows a layered architecture: routes → controllers → services → repositories. Tests use Jest with supertest for integration tests. Current API has 12 endpoints across tasks and users resources. CI runs on GitHub Actions.

### SAD confirmation
The component breakdown and PostgreSQL tsvector approach look right. The migration strategy for adding the search index makes sense.

### TDD confirmation
The interface definitions and search service design look good. The ranking algorithm using ts_rank is appropriate for our scale.
