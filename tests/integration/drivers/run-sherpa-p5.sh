#!/usr/bin/env bash
# run-sherpa-p5.sh — Sherpa P5 (Exploratory Research) integration test
#
# Tests the /sherpa skill end-to-end with a pre-scripted P5 scenario.
# The sherpa generates all PIK artifacts (WCR, Intake, PFD, VH, AR, EL),
# validates each, maintains the ER, and handles the full flow.
#
# Usage: bash run-sherpa-p5.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="AICR"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/aicr-exploratory"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-p5-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-aicr"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read fixture ─────────────────────────────────────────────────────────────

log_step "Read test scenario fixture"
if [[ ! -f "$FIXTURE_DIR/scenario.md" ]]; then
  log_fail "Scenario fixture not found: $FIXTURE_DIR/scenario.md"
  print_summary "Sherpa P5 (Exploratory)"
  exit 1
fi
SCENARIO=$(cat "$FIXTURE_DIR/scenario.md")
log_pass "Loaded scenario fixture"

# ─── Read sherpa skill ────────────────────────────────────────────────────────

log_step "Read sherpa skill definition"
SKILL_FILE="$AIEOS_ROOT/.claude/skills/sherpa/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  # Fall back to tracked copy
  SKILL_FILE="$AIEOS_ROOT/aieos-governance-foundation/docs/tools/sherpa-skill.md"
fi
if [[ ! -f "$SKILL_FILE" ]]; then
  log_fail "Sherpa skill not found"
  print_summary "Sherpa P5 (Exploratory)"
  exit 1
fi
# Strip YAML frontmatter from skill file
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/,/^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

# ─── Run sherpa session ───────────────────────────────────────────────────────

log_step "Run sherpa session (this may take several minutes)"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa P5 (Exploratory)"
  exit 0
fi

PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- Generate ALL artifacts in the P5 sequence: WCR, Discovery Intake, PFD, VH, AR, EL
- Validate each artifact after generation (separate step — re-read from file)
- Freeze each artifact that passes validation (except EL which stays Draft)
- Maintain the Engagement Record throughout
- Save the routing record as 00-routing-record.md
- Use this project directory for all output: $PROJECT_DIR
- CRITICAL: Save all SDLC artifacts to $PROJECT_DIR/docs/sdlc/ (e.g., $PROJECT_DIR/docs/sdlc/00-routing-record.md, $PROJECT_DIR/docs/sdlc/01-wcr.md). Save the ER to $PROJECT_DIR/docs/engagement/. Save the Sherpa Journal to $PROJECT_DIR/docs/engagement/. Do NOT write artifacts to the project root.
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses

$SCENARIO

## Execution

Begin now. Process all responses in sequence and generate the complete P5 artifact set. After completing all artifacts, write a session transcript summary to $RUN_DIR/session-transcript.md that includes:
1. Each artifact generated (filename, artifact ID, status)
2. Each validation result (gate-by-gate)
3. Any utility prompts offered (and whether accepted/declined)
4. The final ER state
5. Whether you asked \"Ready?\" at any point (you should NOT have)"

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

log_step "Verify WCR"
if [[ -f "$PROJECT_DIR/docs/sdlc/00-wcr.md" ]] || [[ -f "$PROJECT_DIR/docs/sdlc/01-wcr.md" ]]; then
  WCR_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*wcr.md 2>/dev/null | head -1)
  log_pass "WCR exists: $(basename "$WCR_FILE") ($(wc -l < "$WCR_FILE") lines)"
else
  log_fail "WCR not generated"
fi

log_step "Verify Discovery Intake"
if ls "$PROJECT_DIR/docs/sdlc/"*intake*.md &>/dev/null; then
  INTAKE_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*intake*.md 2>/dev/null | head -1)
  log_pass "Intake exists: $(basename "$INTAKE_FILE") ($(wc -l < "$INTAKE_FILE") lines)"
else
  log_fail "Discovery Intake not generated"
fi

log_step "Verify PFD"
if ls "$PROJECT_DIR/docs/sdlc/"*pfd*.md &>/dev/null; then
  PFD_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*pfd*.md 2>/dev/null | head -1)
  log_pass "PFD exists: $(basename "$PFD_FILE") ($(wc -l < "$PFD_FILE") lines)"
else
  log_fail "PFD not generated"
fi

log_step "Verify VH"
if ls "$PROJECT_DIR/docs/sdlc/"*vh*.md &>/dev/null; then
  VH_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*vh*.md 2>/dev/null | head -1)
  log_pass "VH exists: $(basename "$VH_FILE") ($(wc -l < "$VH_FILE") lines)"
else
  log_fail "VH not generated"
fi

log_step "Verify AR"
if ls "$PROJECT_DIR/docs/sdlc/"*ar*.md &>/dev/null; then
  AR_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*ar*.md 2>/dev/null | head -1)
  log_pass "AR exists: $(basename "$AR_FILE") ($(wc -l < "$AR_FILE") lines)"
else
  log_fail "AR not generated"
fi

log_step "Verify EL"
if ls "$PROJECT_DIR/docs/sdlc/"*el*.md &>/dev/null; then
  EL_FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*el*.md 2>/dev/null | head -1)
  log_pass "EL exists: $(basename "$EL_FILE") ($(wc -l < "$EL_FILE") lines)"
else
  log_fail "EL not generated"
fi

log_step "Verify Engagement Record"
ER_FILE=$(find "$PROJECT_DIR/docs/engagement" -iname "er-aicr-001.md" 2>/dev/null | head -1)
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

# Check AR has Origin field
if [[ -n "${AR_FILE:-}" ]] && [[ -f "${AR_FILE:-}" ]]; then
  if grep -qi "origin" "$AR_FILE"; then
    log_pass "AR contains Origin field"
  else
    log_fail "AR missing Origin field (AI transparency fix #3)"
  fi
fi

# Check EL is Draft (not Frozen)
if [[ -n "${EL_FILE:-}" ]] && [[ -f "${EL_FILE:-}" ]]; then
  if grep -q "Draft" "$EL_FILE"; then
    log_pass "EL status is Draft (correct — results pending)"
  else
    log_fail "EL should be Draft, not Frozen"
  fi
fi

# Check frozen artifacts have Frozen status
for artifact_var in WCR_FILE PFD_FILE VH_FILE AR_FILE; do
  artifact_file="${!artifact_var:-}"
  if [[ -n "$artifact_file" ]] && [[ -f "$artifact_file" ]]; then
    if grep -q "Frozen" "$artifact_file"; then
      log_pass "$(basename "$artifact_file") is Frozen"
    else
      log_fail "$(basename "$artifact_file") should be Frozen"
    fi
  fi
done

# ─── Run post-analysis ───────────────────────────────────────────────────────

log_step "Run post-analysis"
if [[ -f "$INTEGRATION_DIR/validate-sherpa-run.py" ]]; then
  if python3 "$INTEGRATION_DIR/validate-sherpa-run.py" p5 "$RUN_DIR" "$PROJECT_DIR"; then
    log_pass "Post-analysis passed"
  else
    log_fail "Post-analysis found issues"
  fi
else
  log_skip "validate-sherpa-run.py not found — skipping deep analysis"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

print_summary "Sherpa P5 (Exploratory)"
