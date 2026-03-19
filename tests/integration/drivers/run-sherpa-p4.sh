#!/usr/bin/env bash
# run-sherpa-p4.sh — Sherpa P4 (Performance and Reliability Fix) integration test
#
# Tests the incident-triggered flow:
# - ODK entry (not PIK or EEK)
# - DCR → INR → PMR sequence
# - PMR corrective actions are specific and actionable
# - ODK→EEK transition with KER referencing PMR
#
# Usage: bash run-sherpa-p4.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="APILATENCY"
PRESET="p4"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/api-latency-incident"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-p4-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-apilatency"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read fixture ─────────────────────────────────────────────────────────────

log_step "Read test scenario fixture"
if [[ ! -f "$FIXTURE_DIR/scenario.md" ]]; then
  log_fail "Scenario fixture not found: $FIXTURE_DIR/scenario.md"
  print_summary "Sherpa P4 (Performance Fix)"
  exit 1
fi
SCENARIO=$(cat "$FIXTURE_DIR/scenario.md")
log_pass "Loaded scenario fixture"

# ─── Read sherpa skill ────────────────────────────────────────────────────────

log_step "Read sherpa skill definition"
SKILL_FILE="$AIEOS_ROOT/.claude/skills/sherpa/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  SKILL_FILE="$AIEOS_ROOT/aieos-governance-foundation/docs/tools/sherpa-skill.md"
fi
if [[ ! -f "$SKILL_FILE" ]]; then
  log_fail "Sherpa skill not found"
  print_summary "Sherpa P4 (Performance Fix)"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

# ─── Run sherpa session ───────────────────────────────────────────────────────

log_step "Run sherpa session (this may take several minutes)"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa P4 (Performance Fix)"
  exit 0
fi

PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- This is a P4 Performance Fix — route to ODK first (not PIK or EEK)
- Generate ODK artifacts in order: DCR (Disruption Context Record), INR (Investigation Narrative Record), PMR (Post-Mortem Record)
- After PMR is frozen, transition to EEK for the fix
- Generate KER (Kit Entry Record) with Path B justification citing PMR corrective actions
- Validate each artifact after generation (separate step — re-read from file)
- Freeze each artifact that passes validation
- Maintain the Engagement Record throughout
- Save the routing record as 00-routing-record.md
- Use this project directory for all output: $PROJECT_DIR
- CRITICAL: Save all SDLC artifacts to $PROJECT_DIR/docs/sdlc/ (e.g., $PROJECT_DIR/docs/sdlc/00-routing-record.md, $PROJECT_DIR/docs/sdlc/01-wcr.md). Save the ER to $PROJECT_DIR/docs/engagement/. Save the Sherpa Journal to $PROJECT_DIR/docs/engagement/. Do NOT write artifacts to the project root.
- The AIEOS framework is at: $AIEOS_ROOT
- Note: EEK may not have an entry-from-odk.md boundary briefing — this is expected

## Pre-Scripted User Responses

$SCENARIO

## Execution

Begin now. Process all responses in sequence. Generate the ODK artifacts (DCR, INR, PMR), then transition to EEK and generate the KER. After completing all artifacts, write a session transcript summary to $RUN_DIR/session-transcript.md that includes:
1. Each artifact generated (filename, artifact ID, status)
2. Each validation result (gate-by-gate)
3. The ODK→EEK transition point and explanation
4. PMR corrective actions summary
5. The final ER state
6. Whether you asked \"Ready?\" at any point (you should NOT have)"

log_info "Invoking claude headless mode..."
CLAUDE_OUTPUT=""
if CLAUDE_OUTPUT=$(claude -p "$PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
  --permission-mode bypassPermissions \
  --output-format text \
  --max-budget-usd 5 \
  2>"$RUN_DIR/claude-stderr.log"); then
  log_pass "Claude session completed"
  echo "$CLAUDE_OUTPUT" > "$RUN_DIR/claude-output.log"
else
  log_fail "Claude session failed"
  echo "$CLAUDE_OUTPUT" > "$RUN_DIR/claude-output.log"
fi

# ─── Verify outputs ──────────────────────────────────────────────────────────

log_step "Verify routing record"
if [[ -f "$PROJECT_DIR/docs/sdlc/00-routing-record.md" ]]; then
  log_pass "Routing record exists: 00-routing-record.md"
else
  log_fail "Routing record missing: 00-routing-record.md"
fi

# ODK artifacts
for artifact in dcr inr pmr; do
  log_step "Verify ${artifact^^} (ODK)"
  if ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md &>/dev/null; then
    FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
    log_pass "${artifact^^} exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
  else
    log_fail "${artifact^^} not generated"
  fi
done

# EEK KER
log_step "Verify KER (EEK)"
if ls "$PROJECT_DIR/docs/sdlc/"*ker*.md &>/dev/null; then
  FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*ker*.md 2>/dev/null | head -1)
  log_pass "KER exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
else
  log_fail "KER not generated"
fi

log_step "Verify Engagement Record"
ER_FILE=$(find "$PROJECT_DIR/docs/engagement" -iname "er-*latency*.md" -o -iname "er-*apilatency*.md" 2>/dev/null | head -1)
if [[ -n "$ER_FILE" ]]; then
  log_pass "ER exists: $(basename "$ER_FILE") ($(wc -l < "$ER_FILE") lines)"
else
  log_fail "Engagement Record not generated"
fi

log_step "Verify session transcript"
if [[ -f "$RUN_DIR/session-transcript.md" ]]; then
  log_pass "Session transcript exists"
else
  log_fail "Session transcript not generated"
fi

# ─── Behavioral checks ───────────────────────────────────────────────────────

log_step "Behavioral checks"

# Check no PIK artifacts were generated
if ls "$PROJECT_DIR/docs/sdlc/"*wcr*.md &>/dev/null || \
   ls "$PROJECT_DIR/docs/sdlc/"*pfd*.md &>/dev/null || \
   ls "$PROJECT_DIR/docs/sdlc/"*vh*.md &>/dev/null; then
  log_fail "PIK artifacts found — P4 should not generate PIK artifacts"
else
  log_pass "No PIK artifacts generated (correct for P4)"
fi

# Check routing record mentions P4 / Performance / Incident
if [[ -f "$PROJECT_DIR/docs/sdlc/00-routing-record.md" ]]; then
  if grep -qi "P4\|[Pp]erformance\|[Ii]ncident\|ODK" "$PROJECT_DIR/docs/sdlc/00-routing-record.md"; then
    log_pass "Routing record references P4/Performance/Incident"
  else
    log_fail "Routing record should reference P4, Performance, or Incident"
  fi
fi

# Check PMR has specific corrective actions
PMR_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*pmr*.md 2>/dev/null | head -1)
if [[ -n "${PMR_FILE:-}" ]] && [[ -f "${PMR_FILE:-}" ]]; then
  if grep -qi "corrective\|action\|CONCURRENTLY\|migration" "$PMR_FILE"; then
    log_pass "PMR contains specific corrective actions"
  else
    log_fail "PMR should contain specific, actionable corrective actions"
  fi
fi

# Check KER references PMR
KER_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*ker*.md 2>/dev/null | head -1)
if [[ -n "${KER_FILE:-}" ]] && [[ -f "${KER_FILE:-}" ]]; then
  if grep -qi "PMR\|post.mortem\|corrective\|incident" "$KER_FILE"; then
    log_pass "KER references PMR/corrective actions"
  else
    log_fail "KER should reference PMR corrective actions"
  fi
fi

# Check frozen artifacts
for artifact in dcr inr pmr ker; do
  FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
  if [[ -n "$FILE" ]] && [[ -f "$FILE" ]]; then
    if grep -q "Frozen" "$FILE"; then
      log_pass "$(basename "$FILE") is Frozen"
    else
      log_fail "$(basename "$FILE") should be Frozen"
    fi
  fi
done

# ─── Run post-analysis ───────────────────────────────────────────────────────

log_step "Run post-analysis"
if [[ -f "$INTEGRATION_DIR/validate-sherpa-run.py" ]]; then
  if python3 "$INTEGRATION_DIR/validate-sherpa-run.py" "$PRESET" "$RUN_DIR" "$PROJECT_DIR"; then
    log_pass "Post-analysis passed"
  else
    log_fail "Post-analysis found issues"
  fi
else
  log_skip "validate-sherpa-run.py not found — skipping deep analysis"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

print_summary "Sherpa P4 (Performance Fix)"
