# Pivot/Pause Test Scenario: AICR Negative Results

## Initiative
- Name: AICR
- Preset: P5 (Exploratory Research)
- Topic: AI Code Review — returning with negative experiment results
- Special: Two-phase test. Phase 1 generates artifacts to EL Draft. Phase 2 resumes with results that hit falsification thresholds.

## Phase 1 User Responses

Use the aicr-exploratory/scenario.md fixture for Phase 1 (identical to standard P5).

## Phase 2 User Responses (session resumption with negative results)

### Resumption request
I'm back with the experiment results for the AI Code Review initiative (AICR). Unfortunately, the results weren't good.

### Experiment results
Here are our results:

**Experiment 1: Tool evaluation on 20 real PRs**
- CodeRabbit: caught 4 of 15 known issues (26.7% recall), 18 false positives out of 40 total comments (45% false positive rate). Most missed issues were logic errors and race conditions — it only caught style and formatting issues.
- GitHub Copilot code review: caught 3 of 15 known issues (20% recall), 22 false positives out of 35 comments (62.9% false positive rate). Even worse performance on substantive issues.
- Both tools struggled with our custom React patterns and internal TypeScript utilities.

**Experiment 2: Developer sentiment survey (n=8)**
- Only 2 of 8 developers said they would use an AI reviewer (25%).
- 6 of 8 said the false positive noise was "actively annoying" and worse than no tool at all.
- Top complaint: "It flags things that aren't problems and misses things that are."
- Net promoter score: -45

**Experiment 3: Cycle time measurement (2-week trial)**
- PR cycle time actually increased from 3.8 days to 4.2 days (10.5% increase).
- Developers spent time triaging AI comments, dismissing false positives, and explaining to the AI reviewer why its suggestions were wrong. This added overhead instead of reducing it.
- Senior reviewers still had to do full reviews because they couldn't trust the AI's assessment.

### Threshold assessment
All three falsification thresholds from the VH were hit:
- Recall: 26.7% (falsification threshold was 40%) — BELOW THRESHOLD
- Developer willingness: 25% (falsification threshold was 40%) — BELOW THRESHOLD
- Cycle time: increased 10.5% (any increase is below the 0% falsification threshold) — BELOW THRESHOLD

Result: pause. The hypothesis that AI code review tools can meaningfully augment our review process is falsified for our current stack and team.

### Pause decision
Agreed, pause. The tools aren't ready for our use case. We might revisit in 6-12 months as the tools mature, but there's no point continuing now. Let's document what we learned and close this out.
