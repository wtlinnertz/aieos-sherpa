# P3 Compliance Test Scenario: GDPR Right to Erasure

## Initiative
- Name: GDPRERASE
- Preset: P3 (Compliance and Regulatory)
- Topic: Implement GDPR Article 17 right to erasure — regulatory mandate with 6-month deadline

## User Responses (in conversation order)

### Initial request
We've received a formal notice from our EU data protection officer that we need to implement GDPR Article 17 — the right to erasure. Users must be able to request deletion of all their personal data, and we need to comply within 30 days of each request. We have a hard compliance deadline of September 1st. This isn't optional.

### Clarifying question: scope
This is a regulatory mandate. We need to identify everywhere we store personal data, build a deletion pipeline that covers all those locations, provide a self-service UI for erasure requests, and create an audit trail proving we deleted everything. We also need to handle cases where we have a legal basis to retain certain data (like financial records) — those need to be flagged rather than deleted.

### Clarifying question: discovery needed?
We need some discovery but it's constrained — the requirements come from the regulation, not from user research. We need to map our data landscape (what personal data lives where) and validate our deletion approach with legal counsel. But the "what to build" is dictated by GDPR, not by user desirability.

### Confirm preset
Yes, P3 Compliance is correct.

### Initiative name
GDPRERASE

### Intake Section 1: Problem Context
We store personal data across PostgreSQL (primary), Redis (cache), S3 (file uploads), Elasticsearch (search index), and CloudWatch (logs). We currently have no mechanism for users to request data deletion, and no automated way to find and remove a user's data across all these systems. Manual deletion takes our ops team 4-6 hours per request and we've been doing it ad-hoc via support tickets — about 5 requests per month. The DPO flagged this as non-compliant because: (1) no self-service mechanism, (2) no 30-day SLA tracking, (3) no audit trail, (4) incomplete — we're probably missing data in logs and search indices. The September 1st deadline comes from a regulatory review scheduled for Q4.

### Intake Section 2: Users and Stakeholders
Primary users: EU-based end users who want to exercise their right to erasure. Internal users: legal/compliance team who need to review and approve requests, ops team who currently handles manual deletion. Stakeholders: DPO (legal authority), CTO (technical sponsor), head of compliance (audit requirements). We have approximately 45,000 EU-based users out of 200,000 total.

### Intake Section 3: Opportunity
This is about compliance, not competitive advantage. The opportunity is avoiding regulatory penalties (up to 4% of global annual revenue under GDPR) and maintaining our ability to operate in the EU market. Secondary benefit: building a data governance foundation that supports future privacy regulations (CCPA, LGPD). The risk of inaction is existential for our EU business — a finding of non-compliance during the Q4 review could result in enforcement action.

### Intake Section 4: Current State
No privacy infrastructure exists. Data is spread across 5 systems with no unified view of where a user's data lives. The user model has a soft-delete flag but it only marks the primary record — it doesn't cascade to related data, cached data, uploaded files, or search indices. Logs retain PII indefinitely. No data retention policy is implemented in code. We have a privacy policy document but no technical enforcement.

### Intake Section 5: Scope and Boundaries
In scope: data mapping across all 5 systems, automated erasure pipeline, self-service request UI, admin review workflow, audit logging, 30-day SLA tracking, legal hold exceptions. Out of scope: GDPR data portability (Article 20) — separate initiative. Out of scope: consent management — already handled by a third-party tool. Constraints: must not break referential integrity in PostgreSQL, must handle in-flight transactions gracefully, must maintain audit trail even after deletion (anonymized).

### Intake Section 6: Assumptions and Risks
Assumptions: legal counsel will provide the retention exception list within 2 weeks. All 5 data systems have APIs that support targeted deletion. Log anonymization can replace PII with tokens without corrupting log structure. Risks: unknown data locations — we may discover PII in systems we haven't mapped. Deletion cascading could cause data integrity issues. Performance impact of scanning and deleting across 5 systems for each request. The 6-month timeline is tight for the scope.

### Confirm intake accuracy
Yes, that captures the compliance context accurately.

### After each validation
(User confirms and sherpa proceeds)

### VH thresholds (compliance-specific minimal)
For a compliance mandate, the value is binary — we either comply or we don't. The falsification threshold should be: if legal counsel determines that full technical compliance is impossible within the deadline, we escalate to a partial-compliance approach with a remediation timeline. Success target: all automated tests for the erasure pipeline pass, and legal signs off that the implementation satisfies Article 17 requirements.

### AR confirmation
The assumptions and risk levels look accurate. ASM-3 about log anonymization is the riskiest one — we should validate that early.

### DPRD confirmation
The DPRD captures the regulatory requirements correctly. The phased approach (data mapping first, then erasure pipeline, then UI) makes sense given the deadline.
