#!/usr/bin/env bash
# run-sherpa-manual-p5b.sh — Manual test: P5 with Persona B (Product Manager)
#
# Same driver pattern as automated tests but with PM-persona responses
# that include deliberate challenges:
#   1. Vague answer on Section 4 (probe for more)
#   2. Jargon test ("What's a VH?")
#   3. Skip request on AR
#
# Usage: bash run-sherpa-manual-p5b.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="AICHAT"
PRESET="p5"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/aichat-pm-persona"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/manual-p5-personaB-$TIMESTAMP"
PROJECT_DIR="$RUN_DIR/aieos-aichat"

# ─── Setup ────────────────────────────────────────────────────────────────────

log_step "Setup: Create output directory"
mkdir -p "$PROJECT_DIR/docs/sdlc"
mkdir -p "$PROJECT_DIR/docs/engagement"
log_pass "Created project structure at $PROJECT_DIR"

# ─── Read fixture ─────────────────────────────────────────────────────────────

log_step "Read test scenario fixture"
if [[ ! -f "$FIXTURE_DIR/scenario.md" ]]; then
  log_fail "Scenario fixture not found: $FIXTURE_DIR/scenario.md"
  print_summary "Manual P5 Persona B"
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
  print_summary "Manual P5 Persona B"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

# ─── Run sherpa session ───────────────────────────────────────────────────────

log_step "Run sherpa session (this may take several minutes)"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Manual P5 Persona B"
  exit 0
fi

PROMPT="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- When the user gives a vague answer (Section 4), probe for more detail
- When the user asks \"What's a VH?\", explain it in plain language before continuing
- When the user asks to skip the AR, explain why it can't be skipped
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
3. How the three challenges were handled (vague Section 4, VH jargon question, AR skip request)
4. Any utility prompts offered (and whether accepted/declined)
5. The final ER state
6. Whether you asked \"Ready?\" at any point (you should NOT have)"

log_info "Invoking claude headless mode..."
CLAUDE_OUTPUT=""
if CLAUDE_OUTPUT=$(claude -p "$PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
  --permission-mode bypassPermissions \
  --output-format text \
  --max-budget-usd 10 \
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

for artifact in wcr intake pfd vh ar el; do
  log_step "Verify ${artifact^^}"
  if ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md &>/dev/null; then
    FILE=$(ls "$PROJECT_DIR/docs/sdlc/"*${artifact}*.md 2>/dev/null | head -1)
    log_pass "${artifact^^} exists: $(basename "$FILE") ($(wc -l < "$FILE") lines)"
  else
    log_fail "${artifact^^} not generated"
  fi
done

log_step "Verify Engagement Record"
ER_FILE=$(find "$PROJECT_DIR/docs/engagement" -iname "er-*chat*.md" -o -iname "er-*aichat*.md" 2>/dev/null | head -1)
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

# ─── Behavioral checks (challenge handling) ──────────────────────────────────

log_step "Behavioral checks — challenge handling"

# Check that Section 4 probe happened
OUTPUT_CONTENT=""
if [[ -f "$RUN_DIR/claude-output.log" ]]; then
  OUTPUT_CONTENT=$(cat "$RUN_DIR/claude-output.log")
fi
TRANSCRIPT_CONTENT=""
if [[ -f "$RUN_DIR/session-transcript.md" ]]; then
  TRANSCRIPT_CONTENT=$(cat "$RUN_DIR/session-transcript.md")
fi
ALL_CONTENT="$OUTPUT_CONTENT $TRANSCRIPT_CONTENT"

if echo "$ALL_CONTENT" | grep -qi "more detail\|tell me more\|could you elaborate\|what tools\|what system\|probe\|vague"; then
  log_pass "Challenge 1: Probed for more detail on vague Section 4"
else
  log_fail "Challenge 1: No evidence of probing for Section 4 detail"
fi

# Check VH explanation
if echo "$ALL_CONTENT" | grep -qi "value hypothesis\|VH.*measurable\|VH.*threshold\|explained.*VH\|what.*VH.*means"; then
  log_pass "Challenge 2: Explained VH jargon to PM persona"
else
  log_fail "Challenge 2: No evidence of VH explanation"
fi

# Check AR skip refusal
if echo "$ALL_CONTENT" | grep -qi "can.t skip\|cannot skip\|important.*skip\|different.*intake\|structured\|formal.*track\|skip.*AR"; then
  log_pass "Challenge 3: Explained why AR can't be skipped"
else
  log_fail "Challenge 3: No evidence of handling AR skip request"
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

print_summary "Manual P5 Persona B"
