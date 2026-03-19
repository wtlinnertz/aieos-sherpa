#!/usr/bin/env bash
# run-sherpa-ambiguous.sh — Ambiguous routing integration tests
#
# Runs multiple short routing-only sessions with ambiguous initial requests.
# Verifies the sherpa asks clarifying questions instead of force-routing.
#
# Sub-tests:
#   1. P1 vs P2: "Add notifications" — could be new feature or enhancement
#   2. P2 vs P4: "API is slow" — could be proactive optimization or incident
#
# Usage: bash run-sherpa-ambiguous.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

PRESET="ambiguous"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$OUTPUT_DIR/sherpa-ambiguous-$TIMESTAMP"

# ─── Read sherpa skill ────────────────────────────────────────────────────────

log_step "Read sherpa skill definition"
SKILL_FILE="$AIEOS_ROOT/.claude/skills/sherpa/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  SKILL_FILE="$AIEOS_ROOT/aieos-governance-foundation/docs/tools/sherpa-skill.md"
fi
if [[ ! -f "$SKILL_FILE" ]]; then
  log_fail "Sherpa skill not found"
  print_summary "Sherpa Ambiguous Routing"
  exit 1
fi
SHERPA_PROMPT=$(sed '1{/^---$/d}; /^---$/d' "$SKILL_FILE")
log_pass "Loaded sherpa skill definition"

if ! command -v claude &>/dev/null; then
  log_skip "claude CLI not found — skipping sherpa session"
  print_summary "Sherpa Ambiguous Routing"
  exit 0
fi

# ─── Sub-test runner ──────────────────────────────────────────────────────────

run_ambiguous_test() {
  local test_name="$1"
  local fixture_dir="$2"
  local expected_preset="$3"
  local sub_dir="$RUN_DIR/$test_name"
  local project_dir="$sub_dir/project"

  log_step "Sub-test: $test_name"
  mkdir -p "$project_dir/docs/sdlc"
  mkdir -p "$project_dir/docs/engagement"

  if [[ ! -f "$fixture_dir/scenario.md" ]]; then
    log_fail "Fixture not found: $fixture_dir/scenario.md"
    return 1
  fi
  local scenario
  scenario=$(cat "$fixture_dir/scenario.md")

  local prompt="$SHERPA_PROMPT

---

## AUTOMATED TEST MODE

You are running in automated test mode. Instead of asking questions interactively, use the pre-scripted user responses below. Process them as if the user typed each response in sequence.

**Important test mode rules:**
- Do NOT ask questions — use the scripted responses below
- Do NOT ask \"Ready?\" or \"Ready to proceed?\" — just proceed through the flow
- This is an AMBIGUOUS ROUTING test — the initial request is deliberately ambiguous
- You MUST ask a clarifying question before routing (do NOT force-route based on the initial request alone)
- After asking the clarifying question, use the disambiguating response to determine the preset
- After routing, generate only the routing record — do NOT proceed to artifact generation
- Save the routing record as 00-routing-record.md
- Use this project directory: $project_dir
- The AIEOS framework is at: $AIEOS_ROOT

## Pre-Scripted User Responses

$scenario

## Execution

Begin now. Ask the clarifying question, use the disambiguating response to route, confirm the preset with the user, then write the routing record. Do NOT generate any artifacts beyond the routing record. Write a session transcript to $sub_dir/session-transcript.md that includes:
1. The clarifying question you asked
2. The disambiguating response you received
3. The final routing decision
4. Whether you asked \"Ready?\" at any point (you should NOT have)"

  log_info "Running sub-test: $test_name..."
  local output
  if output=$(claude -p "$prompt" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
    --permission-mode bypassPermissions \
    --output-format text \
    --max-budget-usd 2 \
    2>"$sub_dir/claude-stderr.log"); then
    log_pass "Claude session completed for $test_name"
    echo "$output" > "$sub_dir/claude-output.log"
  else
    log_fail "Claude session failed for $test_name"
    echo "$output" > "$sub_dir/claude-output.log"
  fi

  # Verify routing record
  if [[ -f "$project_dir/docs/sdlc/00-routing-record.md" ]]; then
    log_pass "Routing record exists"
    if grep -qi "$expected_preset" "$project_dir/docs/sdlc/00-routing-record.md"; then
      log_pass "Routing record references $expected_preset"
    else
      log_fail "Routing record should reference $expected_preset after disambiguation"
    fi
  else
    log_fail "Routing record missing"
  fi

  # Check for clarifying question evidence
  local check_content=""
  if [[ -f "$sub_dir/claude-output.log" ]]; then
    check_content=$(cat "$sub_dir/claude-output.log")
  fi
  if echo "$check_content" | grep -qi "clarif\|understand\|tell me more\|could you\|help me understand\|few.*question"; then
    log_pass "Clarifying question detected"
  else
    log_fail "No clarifying question found — sherpa may have force-routed"
  fi
}

# ─── Run sub-tests ────────────────────────────────────────────────────────────

run_ambiguous_test \
  "p1-vs-p2" \
  "$INTEGRATION_DIR/fixtures/ambiguous-p1-p2" \
  "P1"

run_ambiguous_test \
  "p2-vs-p4" \
  "$INTEGRATION_DIR/fixtures/ambiguous-p2-p4" \
  "P2"

# ─── Summary ──────────────────────────────────────────────────────────────────

print_summary "Sherpa Ambiguous Routing"
