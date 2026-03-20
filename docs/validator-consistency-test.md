# Validator Consistency Testing

Manual test protocol for verifying that AIEOS validators produce consistent results across different AI providers.

## Purpose

Different AIs may interpret the same validator prose differently. This protocol identifies where AI interpretation variance causes different PASS/FAIL outcomes for the same artifact, so specs can be tightened where needed.

## Test Setup

1. Select 3 frozen artifacts of different types from a completed initiative (e.g., PFD, SAD, TDD)
2. For each artifact, note the validator result from the original AI session (the "baseline")
3. Prepare the validator inputs: artifact file + spec file + validator prompt file

## Test Procedure

For each artifact × each AI provider:

1. Start a clean session (no prior context)
2. Provide: the artifact, its spec, and its validator prompt
3. Ask: "Validate this artifact against the spec using the validator prompt. Produce the standard validator JSON output."
4. Record: status (PASS/FAIL), each gate result, completeness score, blocking issues

## Comparison Matrix

| Artifact | Gate | Claude | Copilot | ChatGPT | Baseline | Variance |
|----------|------|--------|---------|---------|----------|----------|
| PFD-XXX | problem_definition | PASS | PASS | PASS | PASS | None |
| PFD-XXX | user_landscape | PASS | PASS | FAIL | PASS | ChatGPT stricter |
| SAD-XXX | layer_assignment | PASS | FAIL | PASS | PASS | Copilot missed it |
| ... | | | | | | |

## Classifying Variance

| Type | Description | Action |
|------|-------------|--------|
| **Cosmetic** | Same PASS/FAIL, different completeness score (±10) | No action needed |
| **Interpretation** | Different gate result, but the gate spec is ambiguous | Tighten spec language to remove ambiguity |
| **Capability** | AI cannot parse the artifact structure or follow the validator format | Note in AI capability matrix; may need simplified validator variant |
| **Outcome-changing** | Overall PASS vs FAIL differs between AIs | Critical — spec must be tightened until all AIs agree |

## Recommended Test Artifacts

Use artifacts with known edge cases:
- An artifact that barely passed (completeness score 60-70)
- An artifact that failed then passed after convergence (tests the gates that initially failed)
- An artifact with N/A sections (tests whether AIs handle optional content consistently)

## When to Run

- After adding a new AI adapter
- After significant spec or validator changes
- Periodically (quarterly) to catch model behavior drift

## Reporting

Save results to `tests/integration/output/validator-consistency-{DATE}.md` with the comparison matrix and identified variances. File findings that require spec changes as framework findings in the next initiative's ER §6.
