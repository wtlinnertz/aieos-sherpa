#!/usr/bin/env bash
# run-sherpa-resumption.sh — Session resumption integration test
#
# Two-phase test:
#   Phase 1: Generate P5 artifacts to EL Draft (same as standard P5)
#   Phase 2: Resume session with experiment results, freeze EL, generate DPRD
#
# Verifies the sherpa discovers existing ER, identifies current position,
# and resumes from the correct point in the flow.
#
# Usage: bash run-sherpa-resumption.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="AICR"
PRESET="resumption"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-resumption-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-aicr"
PHASE1_FIXTURE="$INTEGRATION_DIR/fixtures/aicr-exploratory"
PHASE2_FIXTURE="$INTEGRATION_DIR/fixtures/aicr-resumption"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read sherpa skill ────────────────────────────────────────────────────────

log_step "Read sherpa skill definition"
SKILL_FILE="$AIEOS_ROOT/.claude/skills/sherpa/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  SKILL_FILE="$AIEOS_ROOT/aieos-governance-foundation/docs/tools/sherpa-skill.md"
fi
if [[ ! -f "$SKILL_FILE" ]]; then
  log_fail "Sherpa skill not found"
  print_summary "Sherpa Session Resumption"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa Session Resumption"
  exit 0
fi

# ─── Phase 1: Generate to EL Draft ───────────────────────────────────────────

log_step "Phase 1: Generate P5 artifacts to EL Draft"

if [[ ! -f "$PHASE1_FIXTURE/scenario.md" ]]; then
  log_fail "Phase 1 fixture not found"
  print_summary "Sherpa Session Resumption"
  exit 1
fi
PHASE1_SCENARIO=$(cat "$PHASE1_FIXTURE/scenario.md")

PHASE1_PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Use the pre-scripted user responses below.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" — just proceed
- Generate P5 artifacts: WCR, Discovery Intake, PFD, VH, AR, EL
- EL stays Draft (no experiment results yet)
- Validate and freeze all except EL
- Maintain the Engagement Record
- Save routing record as 00-routing-record.md
- Use this project directory: $PROJECT_DIR
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses

$PHASE1_SCENARIO

## Execution

Generate the P5 artifact set with EL as Draft. Write transcript to $RUN_DIR/phase1-transcript.md."

log_info "Phase 1: Invoking claude headless mode..."
PHASE1_OUTPUT=""
if PHASE1_OUTPUT=$(claude -p "$PHASE1_PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
  --permission-mode bypassPermissions \
  --output-format text \
  --max-budget-usd 5 \
  2>"$RUN_DIR/phase1-stderr.log"); then
  log_pass "Phase 1 completed"
  echo "$PHASE1_OUTPUT" > "$RUN_DIR/phase1-output.log"
else
  log_fail "Phase 1 failed"
  echo "$PHASE1_OUTPUT" > "$RUN_DIR/phase1-output.log"
fi

# Verify Phase 1 produced EL Draft
if ls "$PROJECT_DIR/docs/sdlc/"*el*.md &>/dev/null; then
  EL_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*el*.md 2>/dev/null | head -1)
  if grep -q "Draft" "$EL_FILE"; then
    log_pass "Phase 1: EL is Draft (ready for Phase 2)"
  else
    log_fail "Phase 1: EL should be Draft"
  fi
else
  log_fail "Phase 1: EL not generated — cannot proceed to Phase 2"
  print_summary "Sherpa Session Resumption"
  exit 1
fi

# ─── Phase 2: Resume with results ────────────────────────────────────────────

log_step "Phase 2: Resume session with experiment results"

if [[ ! -f "$PHASE2_FIXTURE/scenario.md" ]]; then
  log_fail "Phase 2 fixture not found"
  print_summary "Sherpa Session Resumption"
  exit 1
fi
PHASE2_SCENARIO=$(cat "$PHASE2_FIXTURE/scenario.md")

# Extract only Phase 2 responses from the fixture
PHASE2_RESPONSES=$(sed -n '/## Phase 2 User Responses/,$p' "$PHASE2_FIXTURE/scenario.md")

PHASE2_PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE — SESSION RESUMPTION

You are running in automated test mode. This is PHASE 2 of a two-phase test.

**Context:** Phase 1 has already run. The project directory at $PROJECT_DIR contains existing artifacts from a P5 Exploratory Research initiative (AICR). You should discover the existing ER, identify the current position (EL is Draft, waiting for experiment results), and resume from there.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" — just proceed
- FIRST: Scan the project directory for existing artifacts and the ER
- Identify current position: EL is Draft, all prior artifacts are Frozen
- The user is returning with experiment results
- Fill in the EL with the experiment results, validate, and freeze it
- The results exceed success thresholds → proceed decision
- Generate DPRD from the proceed decision
- Update the ER with new artifact IDs
- Use this project directory: $PROJECT_DIR
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses (Phase 2 only)

$PHASE2_RESPONSES

## Execution

Discover existing state, resume the session, process experiment results, freeze EL, generate DPRD. Write transcript to $RUN_DIR/phase2-transcript.md including:
1. What existing artifacts you discovered
2. How you determined the current position
3. The EL update with results
4. The proceed decision
5. DPRD generation and freeze"

log_info "Phase 2: Invoking claude headless mode..."
PHASE2_OUTPUT=""
if PHASE2_OUTPUT=$(claude -p "$PHASE2_PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
  --permission-mode bypassPermissions \
  --output-format text \
  --max-budget-usd 3 \
  2>"$RUN_DIR/phase2-stderr.log"); then
  log_pass "Phase 2 completed"
  echo "$PHASE2_OUTPUT" > "$RUN_DIR/phase2-output.log"
else
  log_fail "Phase 2 failed"
  echo "$PHASE2_OUTPUT" > "$RUN_DIR/phase2-output.log"
fi

# Combine outputs for post-analysis
cat "$RUN_DIR/phase1-output.log" "$RUN_DIR/phase2-output.log" > "$RUN_DIR/claude-output.log" 2>/dev/null
# Combine transcripts if both exist
if [[ -f "$RUN_DIR/phase1-transcript.md" ]] && [[ -f "$RUN_DIR/phase2-transcript.md" ]]; then
  cat "$RUN_DIR/phase1-transcript.md" "$RUN_DIR/phase2-transcript.md" > "$RUN_DIR/session-transcript.md"
elif [[ -f "$RUN_DIR/phase2-transcript.md" ]]; then
  cp "$RUN_DIR/phase2-transcript.md" "$RUN_DIR/session-transcript.md"
fi

# ─── Verify outputs ──────────────────────────────────────────────────────────

log_step "Verify Phase 2 outputs"

# EL should now be Frozen
if ls "$PROJECT_DIR/docs/sdlc/"*el*.md &>/dev/null; then
  EL_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*el*.md 2>/dev/null | head -1)
  if grep -q "Frozen" "$EL_FILE"; then
    log_pass "EL is Frozen (results added, proceed decision made)"
  else
    log_fail "EL should be Frozen after Phase 2"
  fi
fi

# DPRD should exist and be Frozen
if ls "$PROJECT_DIR/docs/sdlc/"*dprd*.md &>/dev/null; then
  DPRD_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*dprd*.md 2>/dev/null | head -1)
  log_pass "DPRD exists: $(basename "$DPRD_FILE")"
  if grep -q "Frozen" "$DPRD_FILE"; then
    log_pass "DPRD is Frozen"
  else
    log_fail "DPRD should be Frozen"
  fi
else
  log_fail "DPRD not generated in Phase 2"
fi

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

print_summary "Sherpa Session Resumption"
