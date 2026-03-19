#!/usr/bin/env bash
# run-enhancement.sh — Agent integration test: Enhancement preset (Path B)
#
# Exercises the EEK Path B flow with a CRUD service product brief.
# This is the simplest preset (no PIK discovery, no cross-cutting kits required).
#
# Usage: ./tests/integration/drivers/run-enhancement.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INITIATIVE="TASKTRACKER"
FIXTURE_DIR="$INTEGRATION_DIR/fixtures/crud-service"
RUN_DIR="$OUTPUT_DIR/enhancement-$(date +%Y%m%d-%H%M%S)"
EEK="$AIEOS_ROOT/aieos-engineering-execution-kit"

mkdir -p "$RUN_DIR"

echo "=== Agent Integration Test: Enhancement Preset ==="
echo "Initiative: $INITIATIVE"
echo "Output: $RUN_DIR"
echo "Kit: $EEK"

# ─── Step 1: Generate PRD from Product Brief (Path B) ────────────────────────

log_step "Generate PRD from Product Brief (EEK Path B)"

generate_artifact \
  "a senior product manager generating a PRD for the Engineering Execution Kit" \
  "Read the following files for context and rules:
- Product Brief: $FIXTURE_DIR/product-brief.md
- PRD Spec: $EEK/docs/specs/prd-spec.md
- PRD Template: $EEK/docs/artifacts/prd-template.md
- PRD Prompt: $EEK/docs/prompts/prd-prompt.md

Generate a PRD for initiative '$INITIATIVE' following the template exactly.
Use the product brief as your input. Do not expand scope beyond the brief.
Set artifact ID to PRD-$INITIATIVE-001. Set status to Draft." \
  "$RUN_DIR/01-prd.md"

# ─── Step 2: Validate PRD ────────────────────────────────────────────────────

log_step "Validate PRD"

if [[ -f "$RUN_DIR/01-prd.md" ]]; then
  validate_artifact \
    "$EEK/docs/specs/prd-spec.md" \
    "$EEK/docs/validators/prd-validator.md" \
    "$RUN_DIR/01-prd.md" \
    "$RUN_DIR/01-prd-validation.json"
else
  log_skip "PRD not generated — skipping validation"
fi

# ─── Step 3: Generate ACF ────────────────────────────────────────────────────

log_step "Generate Architecture Context File (ACF)"

generate_artifact \
  "a senior architect completing the Architecture Context File" \
  "Read the following files:
- Frozen PRD: $RUN_DIR/01-prd.md
- ACF Spec: $EEK/docs/specs/acf-spec.md
- ACF Template: $EEK/docs/artifacts/architecture-context-template.md

Complete the Architecture Context File for initiative '$INITIATIVE'.
This is a human-authored intake form — fill in all sections based on the PRD.
Technology: Node.js, TypeScript, PostgreSQL, Docker.
Set artifact ID to ACF-$INITIATIVE-001. Set status to Draft." \
  "$RUN_DIR/02-acf.md"

# ─── Step 4: Generate SAD ────────────────────────────────────────────────────

log_step "Generate System Architecture Document (SAD)"

if [[ -f "$RUN_DIR/01-prd.md" ]] && [[ -f "$RUN_DIR/02-acf.md" ]]; then
  generate_artifact \
    "a senior system architect generating the SAD" \
    "Read the following files:
- Frozen PRD: $RUN_DIR/01-prd.md
- Frozen ACF: $RUN_DIR/02-acf.md
- SAD Spec: $EEK/docs/specs/sad-spec.md
- SAD Template: $EEK/docs/artifacts/sad-template.md
- SAD Prompt: $EEK/docs/prompts/sad-prompt.md

Generate the SAD for initiative '$INITIATIVE'.
Set artifact ID to SAD-$INITIATIVE-001. Set status to Draft." \
    "$RUN_DIR/03-sad.md"
else
  log_skip "Upstream artifacts missing — skipping SAD"
fi

# ─── Step 5: Validate SAD ────────────────────────────────────────────────────

log_step "Validate SAD"

if [[ -f "$RUN_DIR/03-sad.md" ]]; then
  validate_artifact \
    "$EEK/docs/specs/sad-spec.md" \
    "$EEK/docs/validators/sad-validator.md" \
    "$RUN_DIR/03-sad.md" \
    "$RUN_DIR/03-sad-validation.json"
else
  log_skip "SAD not generated — skipping validation"
fi

# ─── Step 6: Generate TDD ────────────────────────────────────────────────────

log_step "Generate Technical Design Document (TDD)"

if [[ -f "$RUN_DIR/03-sad.md" ]] && [[ -f "$RUN_DIR/02-acf.md" ]]; then
  generate_artifact \
    "a senior engineer generating the TDD" \
    "Read the following files:
- Frozen PRD: $RUN_DIR/01-prd.md
- Frozen ACF: $RUN_DIR/02-acf.md
- Frozen SAD: $RUN_DIR/03-sad.md
- TDD Spec: $EEK/docs/specs/tdd-spec.md
- TDD Template: $EEK/docs/artifacts/tdd-template.md
- TDD Prompt: $EEK/docs/prompts/tdd-prompt.md

Also read the Design Context File template for the intake form:
- DCF Template: $EEK/docs/artifacts/design-context-template.md

Generate the TDD for initiative '$INITIATIVE'.
Set artifact ID to TDD-$INITIATIVE-001. Set status to Draft." \
    "$RUN_DIR/04-tdd.md"
else
  log_skip "Upstream artifacts missing — skipping TDD"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

print_summary "Enhancement (Path B)"
