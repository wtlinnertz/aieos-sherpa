# Sherpa Journal Format

The Sherpa Journal is an append-only operational log that captures decision context, user preferences, and reasoning throughout an initiative. It enables seamless session resumption and retroactive decision replay.

The journal is NOT a governed artifact — it has no spec, template, prompt, or validator. It is a transient operational record maintained by the sherpa alongside the Engagement Record.

---

## Location and Naming

| Field | Value |
|-------|-------|
| Location | `{project}/docs/engagement/sherpa-journal-{INITIATIVE}.md` |
| Example | `docs/engagement/sherpa-journal-TASKFLOW.md` |

The journal lives alongside the ER in the `docs/engagement/` directory.

---

## File Structure

```markdown
# Sherpa Journal — {INITIATIVE}

Initiative: {INITIATIVE}
Preset: {P1–P5}
Created: {YYYY-MM-DD}

---

## Entries

### [{NNN}] {YYYY-MM-DD HH:MM} — {entry type}

**Flow position:** {Kit} / {Artifact or Phase} / {Step}

{entry content — varies by type}

---
```

---

## Entry Types

### `routing-decision`

Logged when the sherpa presents and the user confirms a routing recommendation.

**Content fields:**
- **User's original request:** {verbatim or close paraphrase}
- **Intent translation:** {user's words} → {framework concept}
- **Decision table:** {junction ID, e.g., J-ENTRY-1}
- **Criteria evaluated:** {which rows/conditions were checked}
- **Evidence:** {what in the user's context satisfied the criteria}
- **Outcome:** {preset selected, entry point, decision taxonomy label}
- **User confirmation:** {confirmed / modified — if modified, what changed}

### `artifact-freeze`

Logged when an artifact passes validation and is frozen.

**Content fields:**
- **Artifact:** {artifact ID, e.g., PFD-TASKFLOW-001}
- **Validation result:** PASS — {completeness score if available}
- **Convergence iterations:** {0 if first-pass, N if retries were needed}
- **Notable content:** {1-2 sentences capturing the artifact's key substance — enough to remind a future session what this artifact decided/defined}

### `junction-decision`

Logged at any decision junction beyond initial routing (path selection, kit adoption, proceed/pivot/pause, disposition).

**Content fields:**
- **Junction:** {junction ID or description}
- **Decision table:** {ID if applicable}
- **Options considered:** {list}
- **Evidence cited:** {what informed the decision}
- **Decision:** {chosen option}
- **Outcome taxonomy:** {Approve, Approve-with-Conditions, Block, Remediate-and-Retry, Require-Redesign, Rollback}
- **Rationale:** {1-2 sentences in plain language}

### `user-preference`

Logged when the user expresses a preference that affects how the sherpa operates (not domain content — operational preferences).

**Content fields:**
- **Preference:** {what the user wants}
- **Context:** {when/why they expressed it}
- **Impact:** {how this changes sherpa behavior going forward}

### `cross-cutting-adoption`

Logged when a cross-cutting kit adoption decision is made.

**Content fields:**
- **Kit:** {kit name and layer}
- **Decision:** Adopted / Declined / Deferred
- **Rationale:** {why}
- **Risk acknowledged:** {if declining, what risk was noted}

### `finding-detected`

Logged when a potential framework finding is identified during the initiative.

**Content fields:**
- **Finding:** {description}
- **Artifact context:** {which artifact/step surfaced it}
- **Severity:** {observation / suggestion / gap}
- **Logged to ER:** {Yes / Deferred}

### `health-check`

Logged when the sherpa runs a health dashboard check.

**Content fields:**
- **Artifacts frozen:** {count}
- **Signals surfaced:** {list of health signals and severity}
- **User response:** {acknowledged / action taken}

---

## Lifecycle

| Event | Action |
|-------|--------|
| Phase 2 (Project Setup) | Create the journal file with header |
| After each artifact freeze | Append `artifact-freeze` entry |
| At each decision junction | Append `junction-decision` entry |
| When user expresses preference | Append `user-preference` entry |
| At cross-cutting kit decisions | Append `cross-cutting-adoption` entry |
| After health dashboard checks | Append `health-check` entry |
| On session resumption | Read journal to reconstruct context |

---

## Session Resumption Protocol

When resuming an initiative (existing ER found), the sherpa reads the journal to reconstruct:

1. **Decision context** — Why decisions were made, not just what was decided
2. **User preferences** — How the user wants to work (terse/detailed, domain expertise level)
3. **Reasoning chain** — The accumulated logic connecting routing → artifacts → current position
4. **Open threads** — Health signals surfaced but not yet addressed, deferred decisions

The journal supplements the ER (which tracks *what* happened) with *why* and *how* context that the ER's structured tables cannot capture.

---

## Decision Rationale Replay

At any point during the initiative, the user can ask "why did we decide X?" The sherpa:

1. Searches the journal for entries related to the decision
2. Reads the routing record and ER key decisions for corroborating context
3. Reconstructs the reasoning chain: junction → criteria → evidence → outcome
4. Presents in plain language with citations to the journal entry number and any referenced artifacts

This capability requires the journal to exist. If no journal is found (legacy initiative started before journal support), the sherpa falls back to ER key decisions and routing record only, and notes that full rationale replay is unavailable.

---

## Relationship to Other Documents

| Document | Relationship |
|----------|-------------|
| Engagement Record | ER tracks *what* (artifact IDs, statuses, key decisions). Journal tracks *why* and *how* (reasoning, preferences, context). |
| Routing Record | The routing record is the formal audit trail for the initial routing decision. The journal's `routing-decision` entry captures the same information plus user confirmation details. |
| Iteration Ledger | The ledger tracks convergence loop attempts for a single artifact. The journal's `artifact-freeze` entry records the final outcome including iteration count. |
| Position Check | Position check reads ground truth (ER + files). It may optionally read the journal for richer health signal context. |
