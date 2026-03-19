# P4 Performance Fix Test Scenario: SEV2 API Latency Spike

## Initiative
- Name: APILATENCY
- Preset: P4 (Performance and Reliability Fix)
- Topic: SEV2 API latency spike after database migration — rollback in place, need permanent fix

## User Responses (in conversation order)

### Initial request
We had a SEV2 incident last night — our API response times spiked from a p95 of 120ms to over 2 seconds after we ran a database migration that added indexes to the orders table. We've rolled back the migration but need to figure out the root cause and implement a proper fix. The rollback is a temporary band-aid.

### Clarifying question: incident details
The incident started at 2024-03-10T22:15:00Z, about 10 minutes after the migration completed. Our alerting caught it via p95 latency threshold (>500ms) at 22:25. We rolled back the migration at 22:45 and latency returned to normal by 22:50. Total impact: 30 minutes of degraded API performance affecting approximately 2,000 users. No data loss. The migration was adding a composite index on (customer_id, created_at) to the orders table which has 12 million rows.

### Clarifying question: is this incident-triggered?
Yes, this is directly triggered by the incident. We need to go through incident investigation first to understand why a simple index addition caused this, then fix the underlying issue so we can safely add the index (which we actually need for a new reporting feature).

### Confirm preset
P4 Performance Fix makes sense — it's an incident that needs investigation and then a targeted fix.

### Initiative name
APILATENCY

### DCR (Disruption Context Record) responses
**Disruption type:** Performance degradation — API latency spike
**Severity:** SEV2 (service degraded, not down)
**Timeline:** Detected 2024-03-10T22:25Z, mitigated (rollback) 2024-03-10T22:45Z, resolved 2024-03-10T22:50Z
**Blast radius:** All API endpoints using the orders table (~60% of traffic). ~2,000 active users affected.
**Immediate mitigation:** Rolled back the database migration. Latency returned to normal within 5 minutes.
**Current status:** Stable on rollback. The index that caused the issue has NOT been re-applied.

### INR (Investigation Narrative Record) responses
**Hypothesis 1:** The index creation locked the orders table, causing all queries to queue. PostgreSQL's CREATE INDEX acquires a SHARE lock by default, which blocks writes. With 12M rows, the index build took ~8 minutes, during which all INSERT/UPDATE operations on the orders table were blocked.
**Evidence:** PostgreSQL logs show lock wait events starting at 22:15Z. The migration log shows CREATE INDEX (not CREATE INDEX CONCURRENTLY). The orders table receives ~200 writes/second during peak hours.
**Hypothesis 2:** The new index changed the query planner's execution strategy for existing queries, causing them to use a less efficient plan.
**Evidence:** After rollback, EXPLAIN ANALYZE on key queries shows the planner reverts to the original (faster) plan. Before rollback, the planner was choosing an index scan on the new index for queries that were previously doing sequential scans — and the new index scan was slower because the index was being built while queries used it.
**Root cause:** The migration used CREATE INDEX (blocking) instead of CREATE INDEX CONCURRENTLY (non-blocking). The 8-minute lock blocked all writes. Additionally, the query planner immediately started using the partially-built index, degrading read performance.
**Contributing factors:** No migration review checklist that flags blocking index creation. No load testing of migrations against production-scale data. Alerting threshold (500ms) caught it quickly but the 10-minute detection gap is too long for write-blocking operations.

### PMR (Post-Mortem Record) responses
**Corrective actions:**
1. Rewrite the migration to use CREATE INDEX CONCURRENTLY — prevents table locking during index builds
2. Add a migration review checklist item: any CREATE INDEX on tables with >1M rows MUST use CONCURRENTLY
3. Add a pre-migration load test step for tables with >5M rows — run the migration against a production-size staging database first
4. Reduce alerting threshold from 500ms to 250ms for p95 latency, and add a write-latency specific alert
5. Document the incident and corrective actions for the team

**Prevention:** The underlying issue is that our migration pipeline doesn't distinguish between safe (small table) and risky (large table) schema changes. We need a migration safety gate.

### After each validation
(User confirms and sherpa proceeds)

### KER Path B justification (for EEK entry from ODK)
The PMR corrective actions are clear and bounded: (1) rewrite one migration to use CONCURRENTLY, (2) add a migration review checklist, (3) add pre-migration load testing. These are well-scoped fixes that don't require discovery — the incident investigation has already identified exactly what needs to change. Path B is appropriate because the corrective actions are the PRD.
