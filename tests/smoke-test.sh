#!/usr/bin/env bash
# smoke-test.sh — Zero-cost structural smoke test for aieos-sherpa
#
# Verifies the delegation chain, file existence, and basic integrity
# without invoking any AI or spending API budget.
#
# Usage: bash tests/smoke-test.sh
# Exit code: 0 = PASS, 1 = FAIL

set -euo pipefail

SHERPA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIEOS_ROOT="$(cd "$SHERPA_ROOT/.." && pwd)"

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP  $1"; SKIP=$((SKIP + 1)); }

echo ""
echo "  AIEOS Sherpa Smoke Test"
echo "  $(printf '─%.0s' {1..40})"

# ─── 1. Canonical prompt exists and has content ──────────────────────────────

if [[ -f "$SHERPA_ROOT/sherpa-prompt.md" ]]; then
  LINES=$(wc -l < "$SHERPA_ROOT/sherpa-prompt.md")
  if [[ "$LINES" -gt 400 ]]; then
    pass "Canonical prompt exists ($LINES lines)"
  else
    fail "Canonical prompt too short ($LINES lines, expected >400)"
  fi
else
  fail "Canonical prompt missing: sherpa-prompt.md"
fi

# ─── 2. Claude Code skill delegates to canonical prompt ──────────────────────

SKILL_FILE="$AIEOS_ROOT/.claude/skills/sherpa/SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
  if grep -q "aieos-sherpa/sherpa-prompt.md" "$SKILL_FILE"; then
    pass "Claude Code skill delegates to aieos-sherpa/sherpa-prompt.md"
  else
    fail "Claude Code skill does NOT reference aieos-sherpa/sherpa-prompt.md"
  fi
  # Verify it's a thin wrapper (< 30 lines)
  SKILL_LINES=$(wc -l < "$SKILL_FILE")
  if [[ "$SKILL_LINES" -lt 30 ]]; then
    pass "Claude Code skill is thin wrapper ($SKILL_LINES lines)"
  else
    fail "Claude Code skill is too large ($SKILL_LINES lines) — should delegate, not duplicate"
  fi
else
  skip "Claude Code skill not found at $SKILL_FILE"
fi

# ─── 3. Canonical prompt is tool-agnostic ────────────────────────────────────

if [[ -f "$SHERPA_ROOT/sherpa-prompt.md" ]]; then
  # Should NOT contain Claude Code-specific tool references
  if grep -q "Agent tool" "$SHERPA_ROOT/sherpa-prompt.md"; then
    fail "Canonical prompt contains Claude-specific 'Agent tool' reference"
  else
    pass "Canonical prompt is tool-agnostic (no 'Agent tool' reference)"
  fi
  # Should NOT contain YAML frontmatter
  if head -1 "$SHERPA_ROOT/sherpa-prompt.md" | grep -q "^---$"; then
    fail "Canonical prompt has YAML frontmatter (should be removed)"
  else
    pass "Canonical prompt has no YAML frontmatter"
  fi
fi

# ─── 4. Canonical prompt references framework files that exist ───────────────

if [[ -f "$SHERPA_ROOT/sherpa-prompt.md" ]]; then
  REFS=(
    "aieos-governance-foundation/docs/getting-started.md"
    "aieos-governance-foundation/docs/initiative-presets.md"
    "aieos-governance-foundation/docs/navigation-map.md"
    "aieos-governance-foundation/docs/flow-reference.md"
    "aieos-governance-foundation/docs/sherpa-journal-format.md"
  )
  for ref in "${REFS[@]}"; do
    if [[ -f "$AIEOS_ROOT/$ref" ]]; then
      pass "Referenced file exists: $ref"
    else
      fail "Referenced file missing: $ref"
    fi
  done
fi

# ─── 5. Generic adapter exists ───────────────────────────────────────────────

if [[ -f "$SHERPA_ROOT/adapters/generic/bootstrap-prompt.md" ]]; then
  pass "Generic adapter exists"
else
  fail "Generic adapter missing: adapters/generic/bootstrap-prompt.md"
fi

# ─── 6. Docs are reference pointers, not full copies ────────────────────────

for doc in docs/sherpa-journal-format.md docs/sherpa-conversation-rubric.md docs/sherpa-test-log.md; do
  if [[ -f "$SHERPA_ROOT/$doc" ]]; then
    DOC_LINES=$(wc -l < "$SHERPA_ROOT/$doc")
    if [[ "$DOC_LINES" -lt 15 ]]; then
      pass "$doc is reference pointer ($DOC_LINES lines)"
    else
      fail "$doc appears to be a full copy ($DOC_LINES lines) — should be reference pointer"
    fi
  else
    skip "$doc not found"
  fi
done

# ─── 7. Version file exists ─────────────────────────────────────────────────

if [[ -f "$SHERPA_ROOT/VERSION" ]]; then
  VERSION=$(cat "$SHERPA_ROOT/VERSION" | tr -d '[:space:]')
  if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    pass "VERSION file exists: $VERSION"
  else
    fail "VERSION file has invalid format: '$VERSION'"
  fi
else
  fail "VERSION file missing"
fi

# ─── 8. Test infrastructure exists ───────────────────────────────────────────

if [[ -f "$SHERPA_ROOT/tests/integration/validate-sherpa-run.py" ]]; then
  pass "Behavioral analysis script exists"
else
  fail "validate-sherpa-run.py missing"
fi

DRIVER_COUNT=$(ls "$SHERPA_ROOT/tests/integration/drivers/run-sherpa-"*.sh 2>/dev/null | wc -l)
if [[ "$DRIVER_COUNT" -ge 5 ]]; then
  pass "Test drivers present ($DRIVER_COUNT drivers)"
else
  fail "Too few test drivers ($DRIVER_COUNT, expected >=5)"
fi

CONFIG_COUNT=$(ls "$SHERPA_ROOT/tests/integration/configs/"*.json 2>/dev/null | wc -l)
if [[ "$CONFIG_COUNT" -ge 5 ]]; then
  pass "Test configs present ($CONFIG_COUNT configs)"
else
  fail "Too few test configs ($CONFIG_COUNT, expected >=5)"
fi

FIXTURE_COUNT=$(ls -d "$SHERPA_ROOT/tests/integration/fixtures/"*/ 2>/dev/null | wc -l)
if [[ "$FIXTURE_COUNT" -ge 5 ]]; then
  pass "Test fixtures present ($FIXTURE_COUNT fixtures)"
else
  fail "Too few test fixtures ($FIXTURE_COUNT, expected >=5)"
fi

# ─── 9. Governance-foundation copies have deprecation notices ────────────────

GF_SKILL="$AIEOS_ROOT/aieos-governance-foundation/docs/tools/sherpa-skill.md"
if [[ -f "$GF_SKILL" ]]; then
  if grep -qi "deprecated" "$GF_SKILL"; then
    pass "Governance-foundation sherpa-skill.md has deprecation notice"
  else
    fail "Governance-foundation sherpa-skill.md missing deprecation notice"
  fi
else
  skip "Governance-foundation sherpa-skill.md not found"
fi

GF_BOOTSTRAP="$AIEOS_ROOT/aieos-governance-foundation/docs/sherpa-bootstrap-prompt.md"
if [[ -f "$GF_BOOTSTRAP" ]]; then
  if grep -qi "deprecated" "$GF_BOOTSTRAP"; then
    pass "Governance-foundation bootstrap-prompt.md has deprecation notice"
  else
    fail "Governance-foundation bootstrap-prompt.md missing deprecation notice"
  fi
else
  skip "Governance-foundation bootstrap-prompt.md not found"
fi

# ─── 10. Key sections present in canonical prompt ────────────────────────────

if [[ -f "$SHERPA_ROOT/sherpa-prompt.md" ]]; then
  SECTIONS=(
    "Phase 1: Discovery"
    "Phase 2: Project Setup"
    "Phase 3: Artifact Generation"
    "Phase 4: Kit Transitions"
    "Phase 5: Cross-Cutting Kits"
    "Phase 6: Completion"
    "Critical Rules"
    "Decision Rationale Replay"
    "Session Resumption"
    "Intent Resolution"
    "Risk scan"
    "Quality scoring"
    "Cross-artifact consistency"
    "Framework finding detection"
    "Parallel artifact orchestration"
    "Health Dashboard Check"
    "Fast-path"
    "Template pre-population"
    "Ideation Mode"
    "Prerequisites"
  )
  for section in "${SECTIONS[@]}"; do
    if grep -qi "$section" "$SHERPA_ROOT/sherpa-prompt.md"; then
      pass "Section present: $section"
    else
      fail "Section missing: $section"
    fi
  done
fi

# ─── 11. Cross-AI compatibility artifacts ────────────────────────────────────

# Adapter directories (at least 2: generic + copilot-cli)
ADAPTER_COUNT=$(ls -d "$SHERPA_ROOT/adapters/"*/ 2>/dev/null | wc -l)
if [[ "$ADAPTER_COUNT" -ge 2 ]]; then
  pass "At least 2 adapter directories ($ADAPTER_COUNT found)"
else
  fail "Fewer than 2 adapter directories ($ADAPTER_COUNT found, expected >=2)"
fi

# Copilot CLI adapter
if [[ -f "$SHERPA_ROOT/adapters/copilot-cli/README.md" ]]; then
  pass "Copilot CLI adapter exists"
else
  fail "Copilot CLI adapter missing: adapters/copilot-cli/README.md"
fi

# AI capability matrix
if [[ -f "$SHERPA_ROOT/docs/ai-capability-matrix.md" ]]; then
  pass "AI capability matrix exists"
else
  fail "AI capability matrix missing: docs/ai-capability-matrix.md"
fi

# Cross-AI handoff protocol
if [[ -f "$SHERPA_ROOT/docs/cross-ai-handoff.md" ]]; then
  pass "Cross-AI handoff protocol exists"
else
  fail "Cross-AI handoff protocol missing: docs/cross-ai-handoff.md"
fi

# Validator consistency test methodology
if [[ -f "$SHERPA_ROOT/docs/validator-consistency-test.md" ]]; then
  pass "Validator consistency test methodology exists"
else
  fail "Validator consistency test missing: docs/validator-consistency-test.md"
fi

# ─── 12. Compact prompt parity ───────────────────────────────────────────────

if [[ -f "$SHERPA_ROOT/sherpa-prompt-compact.md" ]]; then
  COMPACT_LINES=$(wc -l < "$SHERPA_ROOT/sherpa-prompt-compact.md")
  if [[ "$COMPACT_LINES" -lt 350 ]]; then
    pass "Compact prompt exists and is under 350 lines ($COMPACT_LINES lines)"
  else
    fail "Compact prompt too long ($COMPACT_LINES lines, limit 350)"
  fi

  # Verify key sections present in compact version too
  COMPACT_MISSING=0
  COMPACT_SECTIONS=(
    "Phase 1: Discovery"
    "Phase 2: Project Setup"
    "Phase 3: Artifact Generation"
    "Phase 4: Kit Transitions"
    "Phase 5: Cross-Cutting Kits"
    "Phase 6: Completion"
    "Critical Rules"
    "Intent Resolution"
    "Risk scan"
    "Quality scoring"
    "Cross-artifact consistency"
    "Health Dashboard Check"
    "Fast-path"
    "Ideation Mode"
  )
  for section in "${COMPACT_SECTIONS[@]}"; do
    if ! grep -qi "$section" "$SHERPA_ROOT/sherpa-prompt-compact.md"; then
      fail "Compact prompt missing section: $section"
      COMPACT_MISSING=$((COMPACT_MISSING + 1))
    fi
  done
  if [[ "$COMPACT_MISSING" -eq 0 ]]; then
    pass "Compact prompt has all $((${#COMPACT_SECTIONS[@]})) key sections"
  fi
else
  fail "Compact prompt missing: sherpa-prompt-compact.md"
fi

# ─── 13. State block in ER spec ──────────────────────────────────────────────

ER_SPEC="$AIEOS_ROOT/aieos-governance-foundation/docs/engagement-record-spec.md"
if [[ -f "$ER_SPEC" ]]; then
  if grep -q "State Block" "$ER_SPEC"; then
    pass "ER spec defines State Block (§1b)"
  else
    fail "ER spec missing State Block definition"
  fi
else
  skip "ER spec not found at $ER_SPEC"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo "  $(printf '─%.0s' {1..40})"
TOTAL=$((PASS + FAIL + SKIP))
echo "  Total: $TOTAL checks | PASS: $PASS | FAIL: $FAIL | SKIP: $SKIP"

if [[ "$FAIL" -gt 0 ]]; then
  echo "  Result: FAIL"
  exit 1
else
  echo "  Result: PASS"
  exit 0
fi
