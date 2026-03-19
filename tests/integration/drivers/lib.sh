#!/usr/bin/env bash
# lib.sh — Shared functions for agent integration test drivers
#
# Source this file from driver scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$(cd "$INTEGRATION_DIR/.." && pwd)"
AIEOS_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
OUTPUT_DIR="$INTEGRATION_DIR/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

STEP_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# ─── Logging ──────────────────────────────────────────────────────────────────

log_step() {
  STEP_COUNT=$((STEP_COUNT + 1))
  echo ""
  echo -e "${YELLOW}━━━ Step $STEP_COUNT: $1 ━━━${NC}"
}

log_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo -e "  ${GREEN}PASS${NC}  $1"
}

log_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo -e "  ${RED}FAIL${NC}  $1"
}

log_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo -e "  ${YELLOW}SKIP${NC}  $1"
}

log_info() {
  echo "  INFO  $1"
}

# ─── Agent Invocation ─────────────────────────────────────────────────────────

# Generate an artifact using Claude Code headless mode
# Usage: generate_artifact "role description" "prompt" "output_file"
generate_artifact() {
  local role="$1"
  local prompt="$2"
  local output_file="$3"

  if ! command -v claude &>/dev/null; then
    log_skip "claude CLI not found — skipping generation"
    return 1
  fi

  log_info "Generating: $(basename "$output_file")"
  log_info "Role: $role"

  local full_prompt="You are $role.

$prompt

Write the complete artifact to the file: $output_file
Use the Write tool to create the file. Output only the artifact content — no commentary."

  local result
  if result=$(claude -p "$full_prompt" \
    --allowedTools "Read,Write,Edit,Glob,Grep" \
    --permission-mode bypassPermissions \
    --output-format text \
    2>&1); then
    if [[ -f "$output_file" ]]; then
      log_pass "Generated: $(basename "$output_file") ($(wc -l < "$output_file") lines)"
      return 0
    else
      log_fail "Claude completed but file not created: $output_file"
      echo "$result" > "${output_file}.error.log"
      return 1
    fi
  else
    log_fail "Claude invocation failed for: $(basename "$output_file")"
    echo "$result" > "${output_file}.error.log"
    return 1
  fi
}

# Validate an artifact using Claude Code headless mode
# Usage: validate_artifact "spec_path" "validator_path" "artifact_path" "result_file"
validate_artifact() {
  local spec_path="$1"
  local validator_path="$2"
  local artifact_path="$3"
  local result_file="$4"

  if ! command -v claude &>/dev/null; then
    log_skip "claude CLI not found — skipping validation"
    return 1
  fi

  log_info "Validating: $(basename "$artifact_path")"

  local prompt="You are a strict validator. Your job is to evaluate the artifact against the spec and produce a JSON verdict.

Read the following files:
1. Spec: $spec_path
2. Validator instructions: $validator_path
3. Artifact to validate: $artifact_path

Follow the validator instructions exactly. Evaluate every hard gate in the spec.
Output ONLY the JSON result — no commentary, no markdown fences.

The JSON must have this schema:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"summary\": \"one sentence verdict\",
  \"hard_gates\": { \"gate_name\": \"PASS\" or \"FAIL\" },
  \"blocking_issues\": [],
  \"warnings\": [],
  \"completeness_score\": \"0-100\"
}

Write the JSON result to: $result_file"

  local result
  if result=$(claude -p "$prompt" \
    --allowedTools "Read,Write" \
    --permission-mode bypassPermissions \
    --output-format text \
    2>&1); then
    if [[ -f "$result_file" ]]; then
      local status
      status=$(python3 -c "import json; print(json.load(open('$result_file'))['status'])" 2>/dev/null || echo "UNKNOWN")
      if [[ "$status" == "PASS" ]]; then
        log_pass "Validation: PASS — $(basename "$artifact_path")"
        return 0
      elif [[ "$status" == "FAIL" ]]; then
        log_fail "Validation: FAIL — $(basename "$artifact_path")"
        return 1
      else
        log_fail "Validation: could not parse result — $(basename "$artifact_path")"
        return 1
      fi
    else
      log_fail "Validator completed but result file not created"
      return 1
    fi
  else
    log_fail "Validator invocation failed for: $(basename "$artifact_path")"
    return 1
  fi
}

# ─── Summary ──────────────────────────────────────────────────────────────────

print_summary() {
  local preset_name="$1"
  echo ""
  echo "════════════════════════════════════════"
  echo "  Agent Integration Test: $preset_name"
  echo "  Steps: $STEP_COUNT"
  echo "  PASS: $PASS_COUNT  FAIL: $FAIL_COUNT  SKIP: $SKIP_COUNT"
  echo "════════════════════════════════════════"

  if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "Result: FAIL"
    return 1
  elif [[ $SKIP_COUNT -gt 0 && $PASS_COUNT -eq 0 ]]; then
    echo ""
    echo "Result: SKIP (no tests executed)"
    return 0
  else
    echo ""
    echo "Result: PASS"
    return 0
  fi
}
