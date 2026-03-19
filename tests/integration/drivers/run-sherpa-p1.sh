#!/usr/bin/env bash
# run-sherpa-p1.sh — Sherpa P1 (New Feature) integration test
#
# Tests the full PIK discovery flow through EEK entry:
# - PIK: WCR, Intake, PFD, VH, AR, EL (with proceed decision), DPRD
# - PIK→EEK transition with handoff explanation
# - EEK Path A: KER (referencing DPRD), PRD (placed from DPRD), ACF, SAD
# - Cross-cutting kit adoption decisions
#
# Usage: bash run-sherpa-p1.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="PUSHNOTIFY"
PRESET="p1"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/notifications-feature"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-p1-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-pushnotify"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read fixture ─────────────────────────────────────────────────────────────

log_step "Read test scenario fixture"
if [[ ! -f "$FIXTURE_DIR/scenario.md" ]]; then
  log_fail "Scenario fixture not found: $FIXTURE_DIR/scenario.md"
  print_summary "Sherpa P1 (New Feature)"
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
  print_summary "Sherpa P1 (New Feature)"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

# ─── Run sherpa session ───────────────────────────────────────────────────────

log_step "Run sherpa session (this may take several minutes)"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa P1 (New Feature)"
  exit 0
fi

PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- This is a P1 New Feature — route through full PIK discovery then transition to EEK
- Generate all PIK artifacts: WCR, Discovery Intake, PFD, VH, AR, EL
- The EL gets experiment results and a \"proceed\" decision — freeze the EL
- Generate DPRD from the EL proceed decision — freeze the DPRD
- Transition to EEK with a clear handoff explanation
- Generate EEK Path A artifacts: KER (referencing frozen DPRD), PRD (placed from DPRD), ACF, SAD
- The PRD should be PLACED from the DPRD, not generated from scratch
- Validate each artifact after generation (separate step — re-read from file)
- Freeze each artifact that passes validation
- Offer cross-cutting kit adoption decisions and record them in the ER
- Maintain the Engagement Record throughout — it should track artifacts across both PIK and EEK
- Save the routing record as 00-routing-record.md
- Use this project directory for all output: $PROJECT_DIR
- CRITICAL: Save all SDLC artifacts to $PROJECT_DIR/docs/sdlc/ (e.g., $PROJECT_DIR/docs/sdlc/00-routing-record.md, $PROJECT_DIR/docs/sdlc/01-wcr.md). Save the ER to $PROJECT_DIR/docs/engagement/. Save the Sherpa Journal to $PROJECT_DIR/docs/engagement/. Do NOT write artifacts to the project root.
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses

$SCENARIO

## Execution

Begin now. Process all responses in sequence and generate the complete P1 artifact set through SAD freeze. After completing all artifacts, write a session transcript summary to $RUN_DIR/session-transcript.md that includes:
1. Each artifact generated (filename, artifact ID, status)
2. Each validation result (gate-by-gate)
3. The PIK→EEK transition point and explanation
4. Cross-cutting kit adoption decisions
5. The final ER state (should span both PIK and EEK artifacts)
6. Whether you asked \"Ready?\" at any point (you should NOT have)"

log_info "Invoking claude headless mode..."
CLAUDE_OUTPUT=""
if CLAUDE_OUTPUT=$(claude -p "$PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
  --permission-mode bypassPermissions \
  --output-format text \
  --max-budget-usd 8 \
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

# PIK artifacts
for artifact in wcr intake pfd vh ar el dprd; do
  log_step "Verify ${artifact^^} (PIK)"
  if ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md &>/dev/null; then
    FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
    log_pass "${artifact^^} exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
  else
    log_fail "${artifact^^} not generated"
  fi
done

# EEK artifacts
for artifact in ker prd acf sad; do
  log_step "Verify ${artifact^^} (EEK)"
  if ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md &>/dev/null; then
    FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
    log_pass "${artifact^^} exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
  else
    log_fail "${artifact^^} not generated"
  fi
done

log_step "Verify Engagement Record"
ER_FILE=$(find "$PROJECT_DIR/docs/engagement" -iname "er-*notify*.md" -o -iname "er-*pushnotify*.md" 2>/dev/null | head -1)
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

# Check EL is Frozen (results received, proceed decision)
EL_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*el*.md 2>/dev/null | head -1)
if [[ -n "${EL_FILE:-}" ]] && [[ -f "${EL_FILE:-}" ]]; then
  if grep -q "Frozen" "$EL_FILE"; then
    log_pass "EL is Frozen (proceed decision made)"
  else
    log_fail "EL should be Frozen after proceed decision"
  fi
fi

# Check DPRD is Frozen
DPRD_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*dprd*.md 2>/dev/null | head -1)
if [[ -n "${DPRD_FILE:-}" ]] && [[ -f "${DPRD_FILE:-}" ]]; then
  if grep -q "Frozen" "$DPRD_FILE"; then
    log_pass "DPRD is Frozen"
  else
    log_fail "DPRD should be Frozen"
  fi
fi

# Check KER references DPRD (Path A)
KER_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*ker*.md 2>/dev/null | head -1)
if [[ -n "${KER_FILE:-}" ]] && [[ -f "${KER_FILE:-}" ]]; then
  if grep -qi "DPRD\|Path A\|discovery" "$KER_FILE"; then
    log_pass "KER references DPRD/Path A"
  else
    log_fail "KER should reference frozen DPRD (Path A entry)"
  fi
fi

# Check frozen status on all expected-frozen artifacts
for artifact in wcr pfd vh ar el dprd ker prd acf sad; do
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

print_summary "Sherpa P1 (New Feature)"
