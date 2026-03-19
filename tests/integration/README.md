# Sherpa Integration Test Framework

Automated end-to-end testing of the AIEOS sherpa skill using Claude Code headless mode with pre-scripted user interactions.

## How It Works

Each test runs the sherpa skill against a **fixture** (a scenario with pre-scripted user responses), then validates the output at three levels:

### Three-Layer Verification

1. **Existence checks** — Did the expected artifacts get created? (driver script)
2. **Structural checks** — Are artifacts frozen/draft as expected? Do they have required fields? (driver script)
3. **Behavioral checks** — Did the sherpa follow correct flow, offer utility prompts, avoid anti-patterns? (`validate-sherpa-run.py`)

### Hard vs Soft Checks

- **Hard checks** cause FAIL. These verify deterministic structural requirements: artifact existence, frozen status, provenance fields, ER completeness, routing record accuracy.
- **Soft checks** cause WARN. These verify non-deterministic LLM behaviors: utility prompt offering, explanation quality, transition clarity. Soft check failures are logged but don't fail the test.

## Directory Structure

```
tests/integration/
├── configs/              # JSON configs per preset (checks, artifacts, patterns)
│   ├── p1.json           # New Feature
│   ├── p2.json           # Enhancement
│   ├── p3.json           # Compliance
│   ├── p4.json           # Performance Fix
│   ├── p5.json           # Exploratory Research
│   └── convergence.json  # Convergence loop variant
├── drivers/              # Bash scripts that invoke claude headless mode
│   ├── lib.sh            # Shared functions (logging, agent invocation)
│   ├── run-enhancement.sh        # Direct artifact generation (non-sherpa)
│   ├── run-sherpa-p1.sh          # P1 New Feature
│   ├── run-sherpa-p2.sh          # P2 Enhancement
│   ├── run-sherpa-p3.sh          # P3 Compliance
│   ├── run-sherpa-p4.sh          # P4 Performance Fix
│   ├── run-sherpa-p5.sh          # P5 Exploratory Research
│   ├── run-sherpa-ambiguous.sh   # Ambiguous routing tests
│   ├── run-sherpa-convergence.sh # Convergence loop test
│   ├── run-sherpa-resumption.sh  # Session resumption test
│   └── run-sherpa-negative.sh    # Pivot/pause (negative results)
├── fixtures/             # Pre-scripted user interactions per scenario
│   ├── aicr-exploratory/         # P5: AI Code Review research
│   ├── aicr-negative/            # P5 variant: negative experiment results
│   ├── aicr-resumption/          # P5 variant: session resumption
│   ├── search-enhancement/       # P2: Add search to task API
│   ├── notifications-feature/    # P1: Push notifications (new feature)
│   ├── gdpr-deletion/            # P3: GDPR right to erasure
│   ├── api-latency-incident/     # P4: SEV2 latency spike
│   ├── ambiguous-p1-p2/          # Routing: new vs enhancement
│   ├── ambiguous-p2-p4/          # Routing: enhancement vs incident
│   ├── crud-service/             # Non-sherpa: direct artifact generation
│   └── poisoned-intake/          # Convergence: intake with solution content
├── output/               # Test run output (gitignored)
├── validate-run.py       # Generic post-run analysis
└── validate-sherpa-run.py  # Sherpa-specific behavioral post-analysis
```

## Running Tests

### Single preset

```bash
# Run a specific sherpa test
bash tests/integration/drivers/run-sherpa-p5.sh

# Run the enhancement (non-sherpa) test
bash tests/integration/drivers/run-enhancement.sh
```

### Via master runner

```bash
# Run Tier 1 + 2 + all sherpa tests
./tests/run-all.sh --with-integration

# Run only a specific preset
./tests/run-all.sh --with-integration --preset p5
```

### Budget

Each test has a budget cap (set via `--max-budget-usd`). Full suite costs ~$53.

| Test | Budget |
|------|--------|
| P5 Exploratory | $5 |
| P2 Enhancement | $5 |
| P1 New Feature | $8 |
| P3 Compliance | $8 |
| P4 Performance Fix | $5 |
| Convergence Loop | $5 |
| Ambiguous Routing (x2) | $4 |
| Session Resumption | $8 |
| Pivot/Pause | $5 |

## Adding a New Test

1. **Create a fixture** in `fixtures/<scenario-name>/scenario.md` with pre-scripted user responses
2. **Create a config** in `configs/<preset>.json` defining expected artifacts, checks, and patterns
3. **Create a driver** in `drivers/run-sherpa-<name>.sh` following the pattern in existing drivers
4. **Add behavioral checks** to `validate-sherpa-run.py` if the preset introduces new verifiable behaviors

### Config format

```json
{
  "preset": "P5",
  "preset_name": "Exploratory Research",
  "initiative_pattern": "AICR",
  "entry_kit": "PIK",
  "expected_artifacts": [
    {"glob": "*wcr*", "type": "WCR", "frozen": true}
  ],
  "er_artifact_patterns": ["WCR-{INIT}-\\d+"],
  "kit_transitions": [],
  "hard_checks": ["routing_record", "frozen_artifacts"],
  "soft_checks": ["utility_prompts_mentioned"],
  "budget_usd": 5
}
```

### Fixture format

Fixtures are Markdown files with:
- Initiative metadata (name, preset, topic)
- Ordered user responses keyed by conversation phase
- Confirmation/clarification responses for validation gates

## Findings and Relaxations

When a test surfaces a framework gap or sherpa behavior issue:

1. Log the finding in `sherpa-test-log.md` with observation number and description
2. If the finding requires a framework fix, file it in the ER
3. If the finding is accepted behavior (LLM non-determinism), add it as a soft check relaxation in the config
4. Re-run the test after the fix to confirm resolution

## Behavioral Check Reference

The following checks are available in `validate-sherpa-run.py`:

| Check | Type | What it verifies |
|-------|------|-----------------|
| `routing_record` | Hard | Routing record exists and references correct preset |
| `frozen_artifacts` | Hard | Expected artifacts have Frozen status |
| `provenance` | Hard | AI-generated artifacts have Governance Model Version and Spec Version |
| `er_completeness` | Hard | ER has artifact IDs for all expected artifacts |
| `no_ready_prompts` | Hard | Session transcript contains no "Ready?" prompts |
| `ar_origin` | Hard | Every AR assumption has an Origin field (User-stated/AI-derived) |
| `el_draft` | Hard | EL is Draft (results pending, not Frozen) |
| `ker_justification` | Hard | KER contains Path B justification |
| `convergence_loop` | Hard | Evidence of validation failure followed by correction retry |
| `el_pause_outcome` | Hard | EL indicates pause/stop outcome for negative results |
| `no_dprd` | Hard | No DPRD generated (expected for pause outcomes) |
| `session_resumption` | Hard | Sherpa discovered existing ER and resumed from correct position |
| `no_force_routing` | Hard | Sherpa asked clarifying question instead of force-routing |
| `utility_prompts_mentioned` | Soft | Utility prompts actively offered at appropriate moments |
| `kit_transition_explanations` | Soft | Kit transitions mentioned and explained in transcript |
| `cross_cutting_adoption` | Soft | ER documents cross-cutting kit adoption decisions |
| `intent_resolution` | Soft | Sherpa translated user intent to framework vocabulary before routing |
| `decision_explanation` | Soft | Sherpa cited decision table ID, criteria, and evidence at junctions |
| `health_dashboard` | Soft | Sherpa surfaced health signals after 3+ artifact freezes |
| `journal_exists` | Hard | Sherpa Journal file created in docs/engagement/ |
| `journal_entries` | Hard | Journal has routing-decision entry and artifact-freeze entries matching frozen artifact count |
| `rationale_replay` | Soft | When "why did we decide X?" is asked, sherpa cites journal entries and decision tables |
| `risk_surfaced` | Soft | Sherpa scanned upstream artifacts for risk patterns (TBD, untested assumptions, cross-ref gaps) before generating |
| `path_prediction` | Soft | Sherpa presented concrete artifact count, cross-cutting kit list, decision junctions, and bottleneck alerts at routing |
| `fast_path_used` | Soft | Sherpa pre-filled obvious cross-cutting kit skip/adopt decisions with contextual reasoning |
| `quality_score_surfaced` | Soft | Sherpa presented completeness score with assessment after validation |
| `consistency_check_run` | Soft | Sherpa ran cross-artifact consistency checks (PRD→SAD, SAD→TDD, etc.) |
| `finding_accumulated` | Soft | Sherpa detected or offered to log framework findings during generation |
| `cross_initiative_scan` | Soft | Sherpa scanned for sibling initiatives and mentioned results at routing |
| `parallel_execution` | Soft | Sherpa offered parallel artifact generation for independent pairs (ACF+SAD, DCF+TDD) |
| `template_prepopulated` | Soft | Sherpa pre-filled template sections from frozen upstream artifacts |
| `retrospective_generated` | Soft | Initiative retrospective generated at completion with structured sections |
| `self_score_generated` | Soft | Sherpa self-scoring against 15 rubric criteria generated at completion |

## What Requires Manual Testing

The automated framework cannot verify:
- Conversation tone and naturalness
- Whether explanations build on prior context appropriately
- Quality of plain-language translations of governance concepts
- Appropriateness of pause points and pacing
- Whether the sherpa "feels" like a helpful guide vs a checklist runner
- Quality of Decision Outcome Taxonomy usage at junctions
- Whether health signals are delivered at natural moments vs feeling forced
- Whether decision rationale replay cites specific journal entries and feels like consulting a colleague who was there

Use `docs/sherpa-conversation-rubric.md` for structured manual evaluation of these qualities (15 criteria on a 1-5 scale, including criteria for intent translation, decision junction reasoning, proactive health monitoring, risk awareness, cross-cutting decision efficiency, quality coaching, and decision rationale accessibility).
