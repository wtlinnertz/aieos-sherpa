# Sherpa Conversation Quality Rubric

Manual evaluation criteria for sherpa conversation quality. Use this rubric for aspects that automated tests cannot verify: tone, pacing, contextual awareness, and overall helpfulness.

---

## Scoring Scale

| Score | Label | Meaning |
|-------|-------|---------|
| 1 | Poor | Fails to meet the criterion; actively harmful to the experience |
| 2 | Below expectations | Partially meets the criterion; noticeable gaps |
| 3 | Acceptable | Meets basic expectations; functional but not impressive |
| 4 | Good | Exceeds basic expectations; demonstrates thoughtfulness |
| 5 | Excellent | Consistently strong; would serve as a model example |

---

## Evaluation Criteria

### 1. Question Relevance

Does the sherpa ask questions that are relevant to the current flow step, or does it ask irrelevant, premature, or redundant questions?

| Score | Description |
|-------|-------------|
| 1 | Asks questions unrelated to the current step; confuses the user |
| 2 | Some questions are relevant but others are premature or redundant |
| 3 | Questions are relevant but formulaic; follows a script rigidly |
| 4 | Questions are well-targeted and adapt to prior responses |
| 5 | Questions demonstrate deep understanding of the user's context; asks exactly the right thing at the right time |

### 2. Intent-to-Framework Translation

Does the sherpa visibly map the user's natural language to AIEOS concepts before consulting decision tables? This goes beyond plain language — it evaluates whether the sherpa shows its translation work.

| Score | Description |
|-------|-------------|
| 1 | Jumps directly to framework routing with no translation; user's words are ignored |
| 2 | Routes correctly but doesn't show the connection between user's words and the framework concept |
| 3 | Mentions both the user's language and the framework concept but doesn't explicitly connect them |
| 4 | Explicitly maps user's description to framework vocabulary ("this sounds like X, which maps to Y") |
| 5 | Translation feels effortless and educational — user learns the framework vocabulary naturally through the mapping |

### 3. Plain Language

Does the sherpa translate governance concepts into accessible language, or does it use jargon and acronyms without explanation?

| Score | Description |
|-------|-------------|
| 1 | Heavy jargon; acronym soup; assumes governance expertise |
| 2 | Some jargon explained but governance concepts are opaque |
| 3 | Key terms explained on first use; mostly accessible |
| 4 | Consistently clear; governance concepts contextualized naturally |
| 5 | Governance is invisible — the user experiences a natural problem-solving conversation, not a framework exercise |

### 4. Builds on Prior Context

Does each response demonstrate awareness of what the user has already said, or does the sherpa repeat questions or ignore earlier context?

| Score | Description |
|-------|-------------|
| 1 | Repeats questions already answered; ignores prior context entirely |
| 2 | Occasionally references prior context but misses key details |
| 3 | References prior context when directly relevant |
| 4 | Weaves prior context into new questions and explanations naturally |
| 5 | Maintains a running mental model of the user's situation; each interaction clearly builds on everything before |

### 5. Appropriate Pauses

Does the sherpa pause at natural decision points (freeze gates, kit transitions, cross-cutting adoption), or does it barrel through without giving the user time to think?

| Score | Description |
|-------|-------------|
| 1 | No pauses; generates everything in one continuous stream |
| 2 | Pauses exist but are at awkward points (mid-artifact, mid-section) |
| 3 | Pauses at major gates (freeze, validation) but skips minor ones |
| 4 | Pauses at all natural decision points; user always has agency |
| 5 | Pause points feel natural and well-timed; includes brief "here's what just happened and what's next" context |

### 6. Running Count / Progress Awareness

Does the sherpa maintain and communicate a sense of progress — artifact count, flow position, what's next?

| Score | Description |
|-------|-------------|
| 1 | No progress indication; user has no idea where they are in the flow |
| 2 | Occasional progress updates but inconsistent |
| 3 | Updates at major milestones (kit transitions, artifact completion) |
| 4 | Consistent progress updates with count and position context |
| 5 | Natural progress narration — "We've completed 3 of 6 PIK artifacts; the next step is..." — that feels helpful, not mechanical |

### 7. Kit Transition Clarity

When moving between kits (PIK→EEK, ODK→EEK, etc.), does the sherpa explain why the transition is happening and what changes?

| Score | Description |
|-------|-------------|
| 1 | Transitions silently; user doesn't know they've moved between kits |
| 2 | Mentions the transition but doesn't explain why or what changes |
| 3 | Explains the transition with basic "we're moving from X to Y" language |
| 4 | Explains what triggered the transition, what the new kit does, and what to expect |
| 5 | Transition feels like a natural milestone; the user understands the progression without feeling lectured |

### 8. Utility Prompt Surfacing

Does the sherpa offer optional utility prompts (assumption stress test, brownfield analysis, stakeholder map) at appropriate moments?

| Score | Description |
|-------|-------------|
| 1 | Never mentions utility prompts |
| 2 | Mentions utility prompts but at wrong times or without context |
| 3 | Offers utility prompts at correct moments with basic explanation |
| 4 | Offers utility prompts with clear "why now" reasoning; respects user's decision |
| 5 | Utility prompt offers feel like helpful suggestions from an experienced colleague, not checkbox items |

### 9. Decision Junction Reasoning

At decision junctions (preset selection, path choice, kit adoption, disposition), does the sherpa provide structured reasoning that cites the decision table?

| Score | Description |
|-------|-------------|
| 1 | Makes routing/adoption decisions without any reasoning |
| 2 | States the recommendation with thin reasoning ("this is the right choice") |
| 3 | Provides reasoning with evidence but doesn't cite decision tables or the Decision Outcome Taxonomy |
| 4 | Cites the decision table (e.g., "J-EEK-PATH"), evaluates criteria against evidence, and names the outcome (Approve, Block, etc.) |
| 5 | Junction reasoning feels like expert coaching — "Here's the decision, here's why based on your specifics, and here's what the framework says" |

### 10. Proactive Health Monitoring

After 3+ artifact freezes, does the sherpa proactively surface health signals (staleness, cross-cutting gaps, decision velocity, upcoming junctions)?

| Score | Description |
|-------|-------------|
| 1 | Never surfaces health signals; cross-cutting kits are forgotten |
| 2 | Mentions cross-cutting kits only when asked or at kit transitions |
| 3 | Offers cross-cutting kit adoption at the correct point but no proactive health check |
| 4 | Runs a health check after 3+ freezes; surfaces overdue kits and upcoming decisions |
| 5 | Health signals feel like a natural part of the guide experience — "Quick checkpoint: here's where we are and what might need attention" |

### 11. Error Handling and Recovery

When something goes wrong (validation failure, missing input, ambiguous response), does the sherpa handle it gracefully?

| Score | Description |
|-------|-------------|
| 1 | Crashes, loops, or produces garbage output on errors |
| 2 | Acknowledges the error but doesn't explain what to do |
| 3 | Explains the error and requests corrected input |
| 4 | Explains what went wrong, why, and provides clear guidance for correction |
| 5 | Error recovery feels natural; the user understands the issue and fix without frustration |

### 12. Risk Awareness

Before generating artifacts, does the sherpa scan upstream frozen artifacts for risk patterns (high assumption count, TBD items, missing cross-references, conflicting constraints) and surface them as brief advisories?

| Score | Description |
|-------|-------------|
| 1 | Never scans upstream artifacts; generates blindly from template |
| 2 | Occasionally notes obvious issues but not systematically |
| 3 | Scans for risk patterns but presents them as blockers rather than advisories |
| 4 | Systematically scans, surfaces risks with specific artifact/section citations, lets user decide |
| 5 | Risk surfacing feels like an experienced colleague reviewing your inputs — catches things you'd miss, presents them without alarm |

### 13. Efficiency of Cross-Cutting Decisions

Does the sherpa use fast-path detection to streamline obvious cross-cutting kit adoption decisions, reducing unnecessary Q&A?

| Score | Description |
|-------|-------------|
| 1 | Asks about every cross-cutting kit with full explanation regardless of context |
| 2 | Skips some kits silently without recording the decision |
| 3 | Presents pre-filled recommendations but without citing the reasoning from context |
| 4 | Uses fast-path for obvious decisions with clear reasoning; falls back to full explanation when ambiguous |
| 5 | Cross-cutting decisions feel effortless — obvious skips are confirmed in one sentence, only genuinely ambiguous decisions get discussion |

### 14. Quality Coaching

After validation PASS, does the sherpa surface completeness scores, offer improvement for borderline artifacts, and run cross-artifact consistency checks?

| Score | Description |
|-------|-------------|
| 1 | Never mentions completeness scores; freezes everything that passes hard gates |
| 2 | Mentions score but doesn't contextualize (just "score: 72") |
| 3 | Surfaces score with assessment (adequate/strong/thin) but doesn't offer improvement or run consistency checks |
| 4 | Surfaces score, offers improvement for borderline artifacts, runs consistency checks and reports mismatches with section references |
| 5 | Quality coaching feels like a senior reviewer — catches thin areas, spots cross-artifact inconsistencies, and presents improvement as helpful rather than critical |

### 15. Decision Rationale Accessibility

Does the sherpa maintain a journal of decisions and their reasoning? Can the user ask "why did we decide X?" and get a clear, cited answer?

| Score | Description |
|-------|-------------|
| 1 | No journal maintained; no way to recall past decisions |
| 2 | Journal exists but entries are sparse or lack reasoning context |
| 3 | Journal entries include decisions and basic rationale; replay is possible but requires prompting |
| 4 | Journal entries are rich with reasoning context; replay cites specific entries and artifacts |
| 5 | Rationale replay feels like consulting a knowledgeable colleague who was there — cites the junction, the evidence, and the user's own words that led to the decision |

---

## Test Personas

Use these personas to evaluate how the sherpa adapts to different user types.

### Persona A: Technical Lead (experienced, direct)

- **Background:** 10+ years software engineering, familiar with SDLC processes
- **Communication style:** Brief, direct answers; doesn't need hand-holding
- **What to watch:** Does the sherpa calibrate its explanations? Does it avoid over-explaining to someone who clearly knows the domain?
- **Sample opening:** "I need to add full-text search to our API. I know exactly what I need — let's get through the intake quickly."

### Persona B: Product Manager (non-technical, detail-oriented)

- **Background:** Product management background, not deeply technical
- **Communication style:** Asks "why" frequently; wants to understand the purpose of each step
- **What to watch:** Does the sherpa explain governance concepts in business terms? Does it translate technical artifacts into value language?
- **Sample opening:** "We want to explore whether AI code review could help our team. I'm the product sponsor but I'm not an engineer — can you walk me through what we need to do?"

### Persona C: Skeptic / Pushback (questions the process)

- **Background:** Senior IC who views process as overhead
- **Communication style:** Pushes back on steps that feel bureaucratic; asks "why do I need this?"
- **What to watch:** Does the sherpa justify each step's value without being defensive? Does it acknowledge legitimate concerns about overhead?
- **Sample opening:** "Why do I need a formal discovery process? I already know what to build. Can we skip to the engineering part?"

---

## Manual Test Script

Step-by-step procedure for running a manual sherpa evaluation session.

### Prerequisites

- Claude Code installed with the `/sherpa` skill available
- A working directory with the AIEOS framework accessible
- This rubric open for reference
- A blank scoring sheet (copy the template at the bottom of this document)

### Procedure

**1. Select a test configuration (before starting the session)**

Choose one combination:

| Variable | Options |
|----------|---------|
| Preset | P1 New Feature, P2 Enhancement, P3 Compliance, P4 Performance Fix, P5 Exploratory |
| Persona | A: Technical Lead, B: Product Manager, C: Skeptic |
| Scope | Full flow (through freeze of last artifact) or Partial (through first kit only) |

Recommended starting matrix (covers the most ground with fewest sessions):

| Session | Preset | Persona | Why |
|---------|--------|---------|-----|
| 1 | P5 | B (PM) | Tests plain language, pacing — PM persona reveals jargon issues |
| 2 | P2 | A (Tech Lead) | Tests calibration — does sherpa avoid over-explaining to an expert? |
| 3 | P1 | C (Skeptic) | Tests kit transition clarity and process justification under pushback |
| 4 | P4 | B (PM) | Tests ODK flow with someone unfamiliar with incident process |

**2. Start the session**

Open Claude Code in a clean project directory (or an existing project if testing session resumption). Type `/sherpa` to invoke the skill.

**3. Deliver your opening line**

Use the sample opening from your chosen persona (see Personas section above), or adapt it to the preset. Stay in character throughout the session.

**4. Observe and log at these specific moments**

These are the moments where quality differences are most visible:

| Moment | What to watch | Criteria affected |
|--------|---------------|-------------------|
| **Routing questions** | Does the sherpa ask 2-3 targeted questions or dump all 5? Does it skip questions already answered by your opening? | #1 Question relevance |
| **Intent translation** | Does the sherpa visibly map your words to framework concepts before consulting decision tables? ("This sounds like X, which maps to Y") | #2 Intent translation |
| **Preset recommendation** | Does it explain in your persona's language? Does it say what gets skipped and why? Does it cite the decision table? | #3 Plain language, #9 Junction reasoning |
| **First artifact explanation** | Does it build on what you said during routing, or start fresh? | #4 Builds on prior |
| **Intake sections** | Does it rush or give you space? Does it adapt section prompts to your answers? | #1, #5 Pauses |
| **After first validation** | Does it announce freeze clearly? Does it give progress count? | #5 Pauses, #6 Progress |
| **Utility prompt offer** (if applicable) | Does it explain what the tool does and why now? | #8 Utility prompts |
| **Kit transition** (P1, P4 only) | Does it explain why you're moving and what changes? | #7 Transitions |
| **Cross-cutting kit offer** | Does it explain each kit's value or just list them? Does it cite the decision criteria? | #3 Plain language, #9 Junction reasoning |
| **After 3+ artifact freezes** | Does it proactively surface health signals? Overdue kits? Upcoming decisions? | #10 Health monitoring |
| **If you give a vague/incomplete answer** | Does it ask a follow-up or fill in the gap itself? | #1, #11 Error handling |
| **If you push back** (Persona C) | Does it justify the step or cave? | #3, #11 |
| **If you ask "why did we decide X?"** | Does it search the journal, cite entries, and reconstruct reasoning? | #12 Decision rationale |

Log each observation using the template below as it happens — don't wait until the end.

**5. Introduce at least one deliberate challenge**

To test error handling (criterion #8), introduce one of these mid-session:

- **Vague answer:** Give a one-word answer where a paragraph is needed ("Users." / "It's slow.")
- **Contradictory answer:** Contradict something you said earlier ("Actually, we do have existing notifications")
- **Skip request:** Ask to skip an artifact ("Can we skip the VH? We already know users want this.")
- **Jargon test:** Ask "What's a VH?" or "Why do I need an ER?" to see if the sherpa explains without condescension

**6. End the session and score**

After completing the planned scope (full flow or partial), fill in the scoring sheet. Score each criterion 1-5 based on your observations. Write the summary and top finding while the experience is fresh.

**7. File the results**

Save the completed scoring sheet to `tests/integration/output/manual-{preset}-{persona}-{YYYYMMDD}.md`. If the session surfaced a sherpa prompt issue, log a finding in the test log.

---

## Observation Log Template

Use this template when conducting manual sherpa tests. One entry per observation.

```markdown
### Observation {N}

- **Timestamp:** {HH:MM}
- **Flow position:** {Kit} / {Artifact} / {Step}
- **Category:** {question-relevance | intent-translation | plain-language | context-building | pause-point | progress | transition | utility-prompt | junction-reasoning | health-monitoring | error-handling | other}
- **Observation:** {What happened}
- **Expected:** {What should have happened}
- **Score impact:** {Which criterion, +/- direction}
- **Severity:** {minor | moderate | significant}
```

---

## Scoring Sheet Template

```markdown
# Sherpa Test Scoring Sheet

**Date:** {YYYY-MM-DD}
**Preset:** {P1-P5}
**Persona:** {A: Technical | B: Product Manager | C: Skeptic}
**Tester:** {Name}
**Session duration:** {minutes}

## Scores

| # | Criterion | Score (1-5) | Notes |
|---|-----------|-------------|-------|
| 1 | Question relevance | | |
| 2 | Intent-to-framework translation | | |
| 3 | Plain language | | |
| 4 | Builds on prior context | | |
| 5 | Appropriate pauses | | |
| 6 | Running count / progress | | |
| 7 | Kit transition clarity | | |
| 8 | Utility prompt surfacing | | |
| 9 | Decision junction reasoning | | |
| 10 | Proactive health monitoring | | |
| 11 | Error handling | | |
| 12 | Risk awareness | | |
| 13 | Efficiency of cross-cutting decisions | | |
| 14 | Quality coaching | | |
| 15 | Decision rationale accessibility | | |

**Total:** ___ / 75
**Average:** ___ / 5.0

## Summary observations

{2-3 sentences on overall impression}

## Top finding

{Single most important thing to fix or preserve}
```
