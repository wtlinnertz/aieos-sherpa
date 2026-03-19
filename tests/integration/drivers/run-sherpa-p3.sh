#!/usr/bin/env bash
# run-sherpa-p3.sh — Sherpa P3 (Compliance and Regulatory) integration test
#
# Tests compliance-specific PIK flow:
# - Compliance-specific intake guidance
# - VH is minimal (mandate-driven, not user-desirability-driven)
# - CER mentioned as required SCK artifact
# - SCK-before-QAK ordering noted
# - DPRD generated from compliance requirements
#
# Usage: bash run-sherpa-p3.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="GDPRERASE"
PRESET="p3"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/gdpr-deletion"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-p3-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-gdprerase"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read fixture ─────────────────────────────────────────────────────────────

log_step "Read test scenario fixture"
if [[ ! -f "$FIXTURE_DIR/scenario.md" ]]; then
  log_fail "Scenario fixture not found: $FIXTURE_DIR/scenario.md"
  print_summary "Sherpa P3 (Compliance)"
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
  print_summary "Sherpa P3 (Compliance)"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

# ─── Run sherpa session ───────────────────────────────────────────────────────

log_step "Run sherpa session (this may take several minutes)"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa P3 (Compliance)"
  exit 0
fi

PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- This is a P3 Compliance initiative — route through PIK with compliance-specific guidance
- VH should be minimal — this is a regulatory mandate, not a user-desirability hypothesis
- The EL step may be minimal or adapted for compliance (regulatory mandates don't need user experiments)
- Generate DPRD from compliance requirements
- Mention CER (Compliance Evidence Record) as a required SCK artifact for this initiative
- Note SCK-before-QAK ordering if cross-cutting kits are discussed
- Generate PIK artifacts: WCR, Discovery Intake, PFD, VH, AR, DPRD
- Validate each artifact after generation (separate step — re-read from file)
- Freeze each artifact that passes validation
- Maintain the Engagement Record throughout
- Save the routing record as 00-routing-record.md
- Use this project directory for all output: $PROJECT_DIR
- CRITICAL: Save all SDLC artifacts to $PROJECT_DIR/docs/sdlc/ (e.g., $PROJECT_DIR/docs/sdlc/00-routing-record.md, $PROJECT_DIR/docs/sdlc/01-wcr.md). Save the ER to $PROJECT_DIR/docs/engagement/. Save the Sherpa Journal to $PROJECT_DIR/docs/engagement/. Do NOT write artifacts to the project root.
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses

$SCENARIO

## Execution

Begin now. Process all responses in sequence and generate the P3 artifact set through DPRD freeze. After completing all artifacts, write a session transcript summary to $RUN_DIR/session-transcript.md that includes:
1. Each artifact generated (filename, artifact ID, status)
2. Each validation result (gate-by-gate)
3. Compliance-specific guidance offered (VH minimal, CER mentioned, SCK ordering)
4. The final ER state
5. Whether you asked \"Ready?\" at any point (you should NOT have)"

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

for artifact in wcr intake pfd vh ar dprd; do
  log_step "Verify ${artifact^^}"
  if ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md &>/dev/null; then
    FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
    log_pass "${artifact^^} exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
  else
    log_fail "${artifact^^} not generated"
  fi
done

log_step "Verify Engagement Record"
ER_FILE=$(find "$PROJECT_DIR/docs/engagement" -iname "er-*gdp*.md" -o -iname "er-*erase*.md" 2>/dev/null | head -1)
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

# Check routing record mentions P3 / Compliance
if [[ -f "$PROJECT_DIR/docs/sdlc/00-routing-record.md" ]]; then
  if grep -qi "P3\|[Cc]ompliance\|[Rr]egulatory" "$PROJECT_DIR/docs/sdlc/00-routing-record.md"; then
    log_pass "Routing record references P3/Compliance"
  else
    log_fail "Routing record should reference P3 or Compliance"
  fi
fi

# Check frozen artifacts
for artifact in wcr pfd vh ar dprd; do
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

print_summary "Sherpa P3 (Compliance)"
