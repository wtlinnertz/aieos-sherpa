#!/usr/bin/env python3
"""
validate-sherpa-run.py — Config-driven post-run analysis for sherpa integration tests.

Loads a preset config from configs/<preset>.json and runs the checks specified there.
Each check function is registered by name and only executed if listed in the config's
hard_checks or soft_checks arrays.

Usage: python3 validate-sherpa-run.py <preset> <run_dir> <project_dir>
"""

import json
import re
import sys
from pathlib import Path


# ─── Config Loading ──────────────────────────────────────────────────────────

def load_config(preset: str) -> dict:
    """Load preset config from configs/<preset>.json."""
    config_dir = Path(__file__).parent / "configs"
    config_path = config_dir / f"{preset}.json"
    if not config_path.exists():
        print(f"  ERROR  Config not found: {config_path}")
        sys.exit(1)
    return json.loads(config_path.read_text())


# ─── Check Functions ─────────────────────────────────────────────────────────
# Each returns a list of issue strings (empty = pass).

def check_ar_origin(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that every assumption in the AR has an Origin field."""
    issues = []
    ar_files = list(project_dir.glob("docs/sdlc/*ar*.md"))
    if not ar_files:
        issues.append("AR file not found")
        return issues

    ar_content = ar_files[0].read_text()
    asm_count = len(re.findall(r"### ASM-\d+", ar_content))
    origin_count = len(re.findall(r"\|\s*Origin\s*\|", ar_content, re.IGNORECASE))

    if asm_count == 0:
        issues.append("No assumptions found in AR")
    elif origin_count < asm_count:
        issues.append(
            f"AR has {asm_count} assumptions but only {origin_count} Origin fields"
        )

    origin_values = re.findall(
        r"\|\s*Origin\s*\|\s*(.+?)\s*\|", ar_content, re.IGNORECASE
    )
    for val in origin_values:
        val_clean = val.strip()
        if val_clean not in ("User-stated", "AI-derived"):
            issues.append(f"Invalid Origin value: '{val_clean}' (expected User-stated or AI-derived)")

    return issues


def check_el_draft(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that EL is Draft, not Frozen."""
    issues = []
    el_files = list(project_dir.glob("docs/sdlc/*el*.md"))
    if not el_files:
        issues.append("EL file not found")
        return issues

    el_content = el_files[0].read_text()
    if "Status | Frozen" in el_content or "| Frozen | Yes |" in el_content:
        issues.append("EL should be Draft (results pending), but found Frozen status")

    return issues


def check_routing_record(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check routing record exists and references correct preset."""
    issues = []
    rr_path = project_dir / "docs/sdlc/00-routing-record.md"
    if not rr_path.exists():
        candidates = list(project_dir.glob("docs/sdlc/*routing*.md"))
        if not candidates:
            issues.append("Routing record not found")
            return issues
        rr_path = candidates[0]

    rr_content = rr_path.read_text()
    preset = config["preset"]
    preset_name = config["preset_name"]

    if preset not in rr_content and preset_name not in rr_content:
        issues.append(f"Routing record does not reference {preset} or {preset_name}")

    return issues


def check_er_completeness(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check ER has artifact IDs for all expected artifacts."""
    issues = []
    initiative = config["initiative_pattern"]

    # Find ER file case-insensitively
    er_candidates = (
        list(project_dir.glob(f"docs/engagement/er-*{initiative.lower()}*.md")) +
        list(project_dir.glob(f"docs/engagement/er-*{initiative.upper()}*.md")) +
        list(project_dir.glob(f"docs/engagement/er-*{initiative}*.md"))
    )
    # Deduplicate
    seen = set()
    er_files = []
    for p in er_candidates:
        if p not in seen:
            seen.add(p)
            er_files.append(p)

    if not er_files:
        issues.append("Engagement Record not found")
        return issues

    er_content = er_files[0].read_text()

    for pattern_template in config.get("er_artifact_patterns", []):
        pattern = pattern_template.replace("{INIT}", initiative)
        label = pattern.split("-")[0]  # e.g., "WCR"
        if not re.search(pattern, er_content):
            issues.append(f"ER missing artifact ID for {label} (expected pattern: {pattern})")

    return issues


def check_frozen_artifacts(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that artifacts marked frozen in config actually have Frozen status."""
    issues = []
    for artifact in config.get("expected_artifacts", []):
        if not artifact.get("frozen", False):
            continue
        glob_pattern = artifact["glob"]
        files = list(project_dir.glob(f"docs/sdlc/{glob_pattern}.md"))
        if not files:
            # Existence is checked separately by the driver
            continue
        content = files[0].read_text().lower()
        if "frozen" not in content:
            issues.append(f"{files[0].name} should be Frozen but is not")

    return issues


def check_provenance(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that AI-generated artifacts have provenance fields."""
    issues = []
    provenance_fields = [
        "Governance Model Version",
        "Spec Version",
    ]

    # Check all artifacts except intake, routing-record, and non-frozen EL
    skip_types = {"routing-record", "intake"}
    for artifact in config.get("expected_artifacts", []):
        if artifact["type"] in skip_types:
            continue
        # Skip human-authored artifacts
        if artifact["type"] in ("WCR", "intake"):
            continue
        glob_pattern = artifact["glob"]
        files = list(project_dir.glob(f"docs/sdlc/{glob_pattern}.md"))
        for f in files:
            content = f.read_text()
            for field in provenance_fields:
                if field not in content:
                    issues.append(f"{f.name} missing provenance field: {field}")

    return issues


def check_no_ready_prompts(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check session transcript for 'Ready?' and other permission-seeking prompts."""
    issues = []
    transcript = run_dir / "session-transcript.md"
    if not transcript.exists():
        return issues

    content = transcript.read_text()
    # Strip self-assessment and summary sections that may discuss the term
    search_content = re.split(
        r'##\s+(?:\d+\.\s+)?"?Ready\b|## Summary|## Session Statistics|## Utility Prompts',
        content, flags=re.IGNORECASE
    )[0]
    # Remove self-assessment lines that discuss whether "Ready?" was asked
    search_content = re.sub(
        r"^.*(?:Asked.*Ready|Ready.*Asked|permission.seeking|prohibition).*$",
        "", search_content, flags=re.MULTILINE | re.IGNORECASE
    )
    # Remove lines that quote the prohibition rule itself (e.g., "The rule says no 'Shall I…?'")
    search_content = re.sub(
        r"^.*(?:rule|prohibit|never ask|critical rules).*$",
        "", search_content, flags=re.MULTILINE | re.IGNORECASE
    )

    # Pattern 1: "Ready?" variants
    ready_matches = re.findall(
        r"[Rr]eady\s*(to\s+(proceed|continue|move|go))?\s*\?", search_content
    )
    # Pattern 2: "Shall I…?" permission-seeking
    shall_matches = re.findall(
        r"[Ss]hall I\s+(validate|go ahead|generate|proceed|continue|create|run|start)\b.*\?",
        search_content
    )
    # Pattern 3: "Want me to…?" permission-seeking
    want_matches = re.findall(
        r"[Ww]ant me to\s+(validate|generate|proceed|continue|create|run|start|go)\b.*\?",
        search_content
    )

    total = len(ready_matches) + len(shall_matches) + len(want_matches)
    if total:
        parts = []
        if ready_matches:
            parts.append(f"{len(ready_matches)} 'Ready?' prompt(s)")
        if shall_matches:
            parts.append(f"{len(shall_matches)} 'Shall I…?' prompt(s)")
        if want_matches:
            parts.append(f"{len(want_matches)} 'Want me to…?' prompt(s)")
        issues.append(
            f"Session transcript contains {', '.join(parts)} — "
            f"permission-seeking between sequential artifacts is prohibited"
        )

    return issues


def check_utility_prompts_mentioned(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that utility prompts were actively offered.

    WARN rationale: Utility prompts are optional enhancements. The sherpa correctly
    prioritizes artifact generation over utility offers in budget-constrained sessions.
    Promote to hard check when: interactive session tests show >80% offer rate.
    """
    issues = []
    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    offer_patterns = [
        r"optional.{0,20}(step|tool|prompt)",
        r"(want|like)\s+to\s+(run|try|do).{0,30}(stress|adversarial|brownfield|stakeholder)",
        r"before\s+we\s+(design|generate|move).{0,30}(stress|adversarial)",
        r"assumption.stress.test",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in offer_patterns)
    if not found:
        issues.append(
            "No utility prompts actively offered during session (sherpa should offer assumption stress test before EL)"
        )

    return issues


def check_kit_transition_explanations(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify kit transitions are mentioned in transcript."""
    issues = []
    transitions = config.get("kit_transitions", [])
    if not transitions:
        return issues

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        issues.append("No transcript available to check kit transitions")
        return issues

    for transition in transitions:
        # Transition format: "PIK→EEK" or "ODK→EEK"
        kits = re.split(r"[→>-]", transition)
        if len(kits) < 2:
            continue
        from_kit = kits[0].strip()
        to_kit = kits[1].strip()

        # Look for any mention of transitioning between the kits
        patterns = [
            rf"{from_kit}.*{to_kit}",
            rf"Layer\s+\d+.*Layer\s+\d+",
            rf"(transition|move|handoff|hand.off|proceed).*({from_kit}|{to_kit})",
        ]
        found = any(re.search(pat, content, re.IGNORECASE) for pat in patterns)
        if not found:
            issues.append(f"Kit transition {transition} not explained in transcript")

    return issues


def check_cross_cutting_adoption(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify ER notes adoption decisions for cross-cutting kits."""
    issues = []

    er_candidates = list(project_dir.glob("docs/engagement/er-*.md"))
    if not er_candidates:
        return issues

    er_content = er_candidates[0].read_text()

    # Look for cross-cutting adoption language
    adoption_patterns = [
        r"(adopt|decline|skip|defer).{0,30}(QAK|SCK|DCK|DKK|PRK|BPK|PINFK)",
        r"(QAK|SCK|DCK|DKK|PRK|BPK|PINFK).{0,30}(adopt|decline|skip|defer|not.adopted|not.required)",
        r"cross.cutting.{0,30}(decision|adoption)",
    ]
    found = any(re.search(pat, er_content, re.IGNORECASE) for pat in adoption_patterns)
    if not found:
        issues.append("ER does not document cross-cutting kit adoption decisions")

    return issues


def check_convergence_loop(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify that a validation failure occurred and was corrected (retry evidence)."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    # Convergence evidence may be split across output log and transcript —
    # check both sources combined.
    parts = []
    if output_log.exists():
        parts.append(output_log.read_text())
    if transcript.exists():
        parts.append(transcript.read_text())
    content = "\n".join(parts)

    if not content:
        issues.append("No transcript available to check convergence loop")
        return issues

    # Look for evidence of validation failure followed by retry
    fail_patterns = [
        r"FAIL",
        r"validation.{0,20}fail",
        r"did\s+not\s+pass",
        r"gate.{0,10}fail",
        r"blocking.issue",
    ]
    retry_patterns = [
        r"(retry|re.?generat|correct|fix|revis|update).{0,30}(intake|artifact|section|content)",
        r"(clean|remov).{0,30}(solution|product|vendor|pricing)",
        r"second.{0,20}(attempt|pass|try)",
        r"convergence",
    ]

    has_fail = any(re.search(pat, content, re.IGNORECASE) for pat in fail_patterns)
    has_retry = any(re.search(pat, content, re.IGNORECASE) for pat in retry_patterns)

    if not has_fail:
        issues.append("No validation failure evidence found (convergence loop requires initial FAIL)")
    if not has_retry:
        issues.append("No retry/correction evidence found (convergence loop requires correction attempt)")

    return issues


def check_ker_justification(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify KER exists and contains Path B justification."""
    issues = []
    ker_files = list(project_dir.glob("docs/sdlc/*ker*.md"))
    if not ker_files:
        issues.append("KER file not found (required for Path B entry)")
        return issues

    ker_content = ker_files[0].read_text()

    # Check for Path B justification content
    path_b_patterns = [
        r"Path\s*B",
        r"direct\s+entry",
        r"bypass.{0,20}discovery",
        r"scope.{0,20}(understood|known|clear|defined)",
    ]
    found = any(re.search(pat, ker_content, re.IGNORECASE) for pat in path_b_patterns)
    if not found:
        issues.append("KER does not contain Path B justification")

    return issues


def check_no_force_routing(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa asked clarifying question instead of force-routing."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        issues.append("No transcript available to check routing behavior")
        return issues

    # Look for evidence of clarifying question
    clarify_patterns = [
        r"(clarif|understand|tell\s+me\s+more|could\s+you|can\s+you)",
        r"(which|what).{0,30}(describe|best|closer|sound)",
        r"(few|some).{0,20}question",
        r"(help\s+me|let\s+me).{0,20}understand",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in clarify_patterns)
    if not found:
        issues.append("No clarifying question found — sherpa may have force-routed")

    return issues


def check_el_pause_outcome(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify EL has pause/stop outcome (negative experiment results)."""
    issues = []
    el_files = list(project_dir.glob("docs/sdlc/*el*.md"))
    if not el_files:
        issues.append("EL file not found")
        return issues

    el_content = el_files[0].read_text()

    pause_patterns = [
        r"(pause|stop|halt|discontinue|do\s+not\s+proceed)",
        r"(below|under|did\s+not\s+meet).{0,30}(threshold|falsification|target)",
        r"outcome.{0,20}(pause|stop|negative|fail)",
    ]
    found = any(re.search(pat, el_content, re.IGNORECASE) for pat in pause_patterns)
    if not found:
        issues.append("EL does not indicate pause/stop outcome for negative results")

    return issues


def check_no_dprd(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify that no DPRD was generated (expected for pause outcomes)."""
    issues = []
    dprd_files = list(project_dir.glob("docs/sdlc/*dprd*.md"))
    if dprd_files:
        issues.append(f"DPRD was generated ({dprd_files[0].name}) but should not exist for pause outcome")
    return issues


def check_intent_resolution(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa translated user intent to framework vocabulary before routing."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of intent-to-framework translation
    intent_patterns = [
        r"(translat|map|interpret).{0,30}(framework|AIEOS|preset|entry)",
        r"(sounds like|this is|this maps to|I.d classify|I.d categorize).{0,30}(P[1-5]|preset|new feature|enhancement|compliance|incident|exploratory)",
        r"(entry point|starting kit|starting at).{0,20}(PIK|EEK|ODK|RRK|PINFK)",
        r"J-ENTRY",  # Decision table reference
        # WS1: Broader natural-language translation patterns
        r"(this|your|you.re).{0,20}(describing|asking|looking).{0,20}(enhancement|new feature|compliance|incident|performance|exploratory)",
        r"(sounds like|looks like|this is).{0,30}(enhancement|new feature|existing|improvement)",
        r"(P[1-5]).{0,20}(preset|path|flow)",
        r"(classify|categorize|route|routing).{0,20}(this|your|initiative)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in intent_patterns)
    if not found:
        issues.append(
            "No intent-to-framework translation evidence found (sherpa should map user language to AIEOS concepts)"
        )

    return issues


def check_intent_translation_timing(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa translates intent to framework vocabulary in its first response.

    The sherpa should apply Step 1a (Intent Resolution) immediately in its first
    response — not defer translation to the second exchange. This check looks for
    framework vocabulary in the first assistant response block.
    """
    issues = []

    transcript = run_dir / "session-transcript.md"
    output_log = run_dir / "claude-output.log"

    content = ""
    if transcript.exists():
        content = transcript.read_text()
    elif output_log.exists():
        content = output_log.read_text()

    if not content:
        return issues

    # Extract the first assistant response (before the second user message)
    # Typical transcript format: user message, then assistant response, then user again
    # Look for framework vocabulary in the first ~2000 chars of assistant output
    first_block = content[:3000]

    translation_patterns = [
        r"(sounds like|this is|this maps to|I.d classify|I.d categorize).{0,30}(P[1-5]|preset|new feature|enhancement|compliance|incident|exploratory)",
        r"(translat|map|interpret).{0,30}(framework|AIEOS|preset|entry)",
        r"(this|your|you.re).{0,20}(describing|asking|looking).{0,20}(enhancement|new feature|compliance|incident|performance|exploratory)",
        r"(P[1-5]).{0,20}(preset|path|flow)",
        r"(entry point|starting kit|starting at).{0,20}(PIK|EEK|ODK|RRK)",
    ]
    found = any(re.search(pat, first_block, re.IGNORECASE) for pat in translation_patterns)
    if not found:
        issues.append(
            "No intent translation in first response — sherpa should map user intent "
            "to framework vocabulary immediately, not defer to second exchange"
        )

    return issues


def check_conditional_opening(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa doesn't re-ask 'What are you trying to build?' when user already stated intent.

    The sherpa should skip the stock opening question if the user's initial message
    already describes what they want to build. This check looks for the stock question
    in sessions where the driver provides upfront context.
    """
    issues = []

    transcript = run_dir / "session-transcript.md"
    output_log = run_dir / "claude-output.log"

    content = ""
    if transcript.exists():
        content = transcript.read_text()
    elif output_log.exists():
        content = output_log.read_text()

    if not content:
        return issues

    # Check if the config indicates the driver provides upfront context
    # (i.e., this is NOT an ambiguous routing test where the question is expected)
    if config.get("preset") == "ambiguous":
        return issues  # Stock question is appropriate for ambiguous inputs

    # Look for the stock opening question in assistant output
    stock_question = re.search(
        r"[Ww]hat are you trying to build or accomplish\s*\?", content
    )

    if stock_question:
        # Only flag if the user's initial message clearly described their goal
        # Check the driver config for a descriptive initial prompt
        driver_prompt = config.get("driver_prompt", "")
        if driver_prompt and len(driver_prompt) > 50:
            issues.append(
                "Sherpa asked stock opening question 'What are you trying to build?' "
                "even though the user's message already described their goal — "
                "should acknowledge description and apply Intent Resolution immediately"
            )

    return issues


def check_intake_quality_probe(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa probes thin intake sections instead of silently accepting them.

    When a user-provided intake section has <2 substantive sentences or only generic
    language, the sherpa should ask one follow-up linking the gap to downstream impact.
    """
    issues = []

    # Only relevant for configs that include intake artifacts
    has_intake = any(
        a.get("type") == "intake" for a in config.get("expected_artifacts", [])
    )
    if not has_intake:
        return issues

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of intake probing behavior
    probe_patterns = [
        # Direct probe language
        r"(section|field|input).{0,30}(light|thin|brief|sparse|generic|vague)",
        r"could you (add|provide|elaborate|expand).{0,30}(specific|detail|more)",
        r"(feeds|flows|goes) (directly )?into.{0,20}(downstream|next|PRD|SAD|PFD)",
        # Downstream impact linkage
        r"(this|that) (feeds|affects|determines|shapes).{0,30}(downstream|PRD|PFD|VH|SAD)",
        r"(quality|detail).{0,20}(determines|affects|shapes).{0,20}(everything|downstream)",
        # Acceptance after probe
        r"(accept|proceed|move on|good enough).{0,20}(as.is|with what|after)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in probe_patterns)
    if not found:
        issues.append(
            "No intake quality probing evidence found — sherpa should ask one "
            "follow-up when intake sections are thin, linking the gap to downstream impact"
        )

    return issues


def check_decision_explanation(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa provides plain-language reasoning at decision junctions."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of structured decision explanation
    explanation_patterns = [
        r"J-[A-Z]+-[A-Z]+",  # Decision table ID (e.g., J-ENTRY-1, J-EEK-PATH)
        r"decision\s+table",
        r"(criteria|condition).{0,30}(met|satisfied|match)",
        r"(recommend|routing).{0,30}(because|since|given)",
        # WS1: Broader informal reasoning patterns
        r"(because|since|given).{0,30}(you|your|this|the).{0,30}(existing|new|compliance|incident)",
        r"(path|preset|route).{0,20}(A|B|[1-5]).{0,20}(because|since|fits|matches)",
        r"(this means|that means|so|therefore).{0,20}(we.ll|we should|I recommend|path)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in explanation_patterns)
    if not found:
        issues.append(
            "No decision explanation evidence found (sherpa should cite decision tables and criteria at junctions)"
        )

    return issues


def check_health_dashboard(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa surfaced health signals after 3+ artifacts frozen."""
    issues = []

    # Only check if enough artifacts were expected to trigger health check
    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues  # Not enough artifacts to trigger health dashboard

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    health_patterns = [
        r"health\s+(check|signal|dashboard|status)",
        r"(staleness|stale|overdue).{0,30}(kit|artifact|cross.cutting)",
        r"cross.cutting\s+(gap|missing|not\s+started)",
        r"upcoming\s+(junction|decision)",
        r"position.check",
        # WS4: Structured health dashboard block patterns
        r"Health Check.{0,10}(after|following)",
        r"Frozen:\s*\d+\s*of",
        r"Cross.cutting status:",
        r"Overdue triggers:",
        r"Next junction:",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in health_patterns)
    if not found:
        issues.append(
            "No health dashboard evidence found (sherpa should surface health signals after 3+ artifact freezes)"
        )

    return issues


def check_journal_exists(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that a Sherpa Journal file was created."""
    issues = []
    journal_files = list(project_dir.glob("docs/engagement/sherpa-journal-*.md"))
    if not journal_files:
        issues.append("Sherpa Journal not found in docs/engagement/")
    return issues


def check_journal_entries(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Check that the journal has expected entry types for the preset."""
    issues = []
    journal_files = list(project_dir.glob("docs/engagement/sherpa-journal-*.md"))
    if not journal_files:
        issues.append("Sherpa Journal not found — cannot check entries")
        return issues

    content = journal_files[0].read_text()

    # Every initiative should have a routing-decision entry
    if "routing-decision" not in content.lower() and "routing decision" not in content.lower():
        issues.append("Journal missing routing-decision entry")

    # Check for artifact-freeze entries — count should match expected frozen artifacts
    freeze_count = len(re.findall(r"artifact.freeze", content, re.IGNORECASE))
    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen > 0 and freeze_count == 0:
        issues.append(
            f"Journal has no artifact-freeze entries but {expected_frozen} artifacts should be frozen"
        )

    return issues


def check_rationale_replay(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa can replay decision rationale when asked (requires transcript with 'why' question)."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Only check if the test fixture included a "why did we decide" question
    why_asked = re.search(
        r"why\s+did\s+we\s+(decide|choose|pick|select|skip)", content, re.IGNORECASE
    )
    if not why_asked:
        return issues  # No replay was requested in this test

    # Look for evidence of replay with citations
    replay_patterns = [
        r"journal\s+entry\s+#?\d+",
        r"entry\s+\[?\d+\]?.*routing",
        r"decision\s+table\s+J-",
        r"at\s+that\s+point.*because",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in replay_patterns)
    if not found:
        issues.append(
            "Rationale replay requested but no evidence of journal-cited reasoning in response"
        )

    return issues


def check_elicitation_applied(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa applied elicitation protocol before high-value artifact generation.

    WARN rationale: Elicitation is the most advanced cognitive behavior — applying named
    reasoning techniques (pre-mortem, inversion, etc.) before generation. Forcing it risks
    cargo-cult application. Will improve as the skill is refined. Promote to hard check when:
    elicitation application shows measurable quality improvement in artifact scores.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of elicitation protocol application
    elicitation_patterns = [
        r"elicitation",
        r"pre.mortem",
        r"first.principles",
        r"inversion",
        r"stakeholder.lens",
        r"constraint.removal",
        r"assumption.surfacing",
        r"<!-- Elicitation:",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in elicitation_patterns)
    if not found:
        issues.append(
            "No elicitation protocol evidence found (sherpa should apply elicitation techniques before generating high-gate-count artifacts)"
        )

    return issues


def check_adversarial_lens_offered(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa offered the adversarial review lens at appropriate review points."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of adversarial lens being offered or discussed
    adversarial_patterns = [
        r"adversarial\s+(lens|review)",
        r"review.adversarial",
        r"minimum.findings",
        r"(attack|probe|skeptic).{0,30}(assumption|boundary|failure)",
        r"(optional|recommend).{0,30}adversarial",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in adversarial_patterns)
    if not found:
        issues.append(
            "No adversarial lens mention found (sherpa should offer adversarial review for high-impact artifacts like SAD, TDD, ORD)"
        )

    return issues


def check_decision_explanation_depth(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa provides structured 5-part decision explanations at junctions.

    The 5-part protocol: (1) cite decision table ID, (2) state criteria evaluated,
    (3) cite evidence, (4) name the outcome, (5) recommend action.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Part 1: Decision table ID cited
    has_table_id = bool(re.search(r"J-[A-Z]+-[A-Z0-9]+", content))

    # Part 2: Criteria evaluated
    criteria_patterns = [
        r"(criteria|condition|question).{0,30}(evaluat|check|assess|met|satisfied)",
        r"routing\s+question",
        r"(is\s+this|does\s+this|has\s+the).{0,30}\?",
    ]
    has_criteria = any(re.search(pat, content, re.IGNORECASE) for pat in criteria_patterns)

    # Part 3: Evidence cited
    evidence_patterns = [
        r"(because|since|given\s+that|evidence|based\s+on).{0,40}(frozen|artifact|intake|ER|DPRD|ORD|PRD)",
        r"(from|per|according\s+to).{0,30}(upstream|PIK|EEK|SSK|QAK|REK|RRK|ODK)",
    ]
    has_evidence = any(re.search(pat, content, re.IGNORECASE) for pat in evidence_patterns)

    # Part 4: Outcome named (Decision Outcome Taxonomy: Approve, Block, Defer, etc.)
    outcome_patterns = [
        r"(recommend|route|routing|proceed|select).{0,30}(P[1-5]|Path\s+[AB]|PIK|EEK|ODK|SSK|PINFK)",
        r"(entry\s+point|preset|starting\s+kit)\s*[:=]?\s*(PIK|EEK|ODK|SSK|PINFK|P[1-5])",
        r"(approve|block|defer|require.redesign|rollback|remediate)",
    ]
    has_outcome = any(re.search(pat, content, re.IGNORECASE) for pat in outcome_patterns)

    parts_found = sum([has_table_id, has_criteria, has_evidence, has_outcome])

    if parts_found < 2:
        issues.append(
            f"Decision explanation lacks depth: found {parts_found}/4 protocol parts "
            f"(table_id={has_table_id}, criteria={has_criteria}, evidence={has_evidence}, outcome={has_outcome}). "
            f"Sherpa should cite decision table ID, evaluate criteria with evidence, and name the routing outcome."
        )

    return issues


def check_position_check_invoked(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa invoked position-check tool after 3+ artifact freezes or at context switches."""
    issues = []

    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues  # Not enough artifacts to trigger position-check

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    position_patterns = [
        r"position.check",
        r"TOOL.POSITION.CHECK",
        r"(where\s+(are\s+)?we|current\s+position|you\s+are\s+at|you\s+are\s+here)",
        r"(ER|engagement\s+record).{0,30}(shows|indicates|confirms|has).{0,30}(frozen|artifact)",
        r"(reading|checking|reviewing).{0,30}(ER|engagement\s+record|artifact\s+director)",
        # WS4: Structured position check output pattern
        r"Position check:\s*(ER|engagement)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in position_patterns)
    if not found:
        issues.append(
            f"No position-check evidence found after {expected_frozen} frozen artifacts "
            f"(sherpa should invoke position-check to orient after 3+ freezes)"
        )

    return issues


def check_handoff_navigator_invoked(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa invoked handoff-navigator at kit transitions."""
    issues = []

    transitions = config.get("kit_transitions", [])
    if not transitions:
        return issues  # No kit transitions

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    handoff_patterns = [
        r"handoff.navigator",
        r"TOOL.HANDOFF.NAVIGATOR",
        r"(exit\s+condition|entry.from|boundary\s+(contract|briefing))",
        r"(handoff|hand.off).{0,30}(artifact|checklist|requirement|complete)",
        r"(verif|confirm|check).{0,30}(exit|handoff|transition).{0,30}(condition|requirement|complete)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in handoff_patterns)
    if not found:
        issues.append(
            f"No handoff-navigator evidence found at kit transition(s) {transitions} "
            f"(sherpa should verify exit conditions and boundary contracts at transitions)"
        )

    return issues


def check_decision_router_invoked(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa invoked decision-router at junction points."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of structured junction navigation
    router_patterns = [
        r"decision.router",
        r"TOOL.DECISION.ROUTER",
        r"J-[A-Z]+-[A-Z0-9]+",  # Decision table citation
        r"(junction|decision\s+point|fork).{0,30}(option|path|route|choice)",
        r"(option\s+\d|choice\s+\d).{0,20}(:|—|-)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in router_patterns)
    if not found:
        issues.append(
            "No decision-router evidence found (sherpa should present options and cite decision tables at junctions)"
        )

    return issues


def check_briefing_distillation_offered(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa offered briefing distillation at kit transitions."""
    issues = []

    transitions = config.get("kit_transitions", [])
    if not transitions:
        return issues  # No kit transitions — distillation not applicable

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of briefing distillation being offered or used
    distillation_patterns = [
        r"briefing.distillation",
        r"distill.{0,20}(artifact|frozen|upstream)",
        r"compress.{0,20}(artifact|frozen|upstream)",
        r"briefing.{0,20}(downstream|consumption|summary)",
        r"TOOL.BRIEFING.DISTILLATION",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in distillation_patterns)
    if not found:
        issues.append(
            "No briefing distillation mention found at kit transition (sherpa should offer to distill frozen artifacts for downstream consumption)"
        )

    return issues


def check_session_resumption(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa discovered existing ER and resumed from correct position."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        issues.append("No transcript available to check session resumption")
        return issues

    # Look for evidence of discovering existing state
    resume_patterns = [
        r"(found|discover|detect|see|existing).{0,30}(ER|engagement|artifact|progress)",
        r"(resum|continu|pick\s+up).{0,20}(where|from|session)",
        r"(current|existing).{0,20}(position|state|progress)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in resume_patterns)
    if not found:
        issues.append("No evidence sherpa discovered existing ER and resumed session")

    return issues


# ─── Check Registry ──────────────────────────────────────────────────────────
# Maps check name (used in config JSON) to function

def check_convergence_loop_depth(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify convergence loop follows stopping rules and tracks iterations.

    Enhanced version of convergence_loop: checks for iteration counting,
    max-iteration awareness, and escalation when convergence fails.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    parts = []
    if output_log.exists():
        parts.append(output_log.read_text())
    if transcript.exists():
        parts.append(transcript.read_text())
    content = "\n".join(parts)

    if not content:
        return issues

    # Check for iteration tracking
    iteration_patterns = [
        r"(iteration|attempt|try|pass)\s*[#:]?\s*[123]",
        r"(first|second|third)\s+(attempt|pass|try|iteration)",
        r"(1|2|3)\s+of\s+(3|max)",
        r"max.{0,10}(iteration|attempt|retries)",
    ]
    has_iteration = any(re.search(pat, content, re.IGNORECASE) for pat in iteration_patterns)

    # Check for stopping rule awareness
    stopping_patterns = [
        r"(max|limit).{0,20}(iteration|attempt|retries|3)",
        r"(convergence|converge).{0,20}(fail|not|unable|exhaust)",
        r"(escalat|human\s+review).{0,20}(convergence|iteration|attempt)",
        r"(same|identical|repeat).{0,20}(fail|error|issue)",  # oscillation detection
    ]
    has_stopping = any(re.search(pat, content, re.IGNORECASE) for pat in stopping_patterns)

    if not has_iteration and not has_stopping:
        issues.append(
            "Convergence loop lacks depth: no iteration tracking or stopping rule awareness "
            "(sherpa should count iterations and know the max=3 limit)"
        )

    return issues


def check_utility_prompts_per_kit(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa offered kit-specific utility prompts at the right moments.

    Enhanced version: checks for specific utility prompts per kit based on
    the preset and which kits are traversed.

    WARN rationale: Kit-specific utility prompt offers are optional enhancements.
    Budget-constrained headless sessions correctly prioritize artifact generation
    over per-kit utility offers. Promote to hard check when: interactive session
    tests show >80% offer rate per applicable kit.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    entry_kit = config.get("entry_kit", "")

    # Kit-specific utility prompt patterns
    kit_utilities = {
        "PIK": [
            (r"(stress.test|assumption.stress|adversarial.{0,10}assumption)", "assumption-stress-test"),
            (r"(brownfield|existing.{0,10}(system|code))", "brownfield-analysis"),
            (r"(stakeholder|alignment|conflict)", "stakeholder-alignment"),
        ],
        "EEK": [
            (r"(codebase.analysis|existing.{0,10}codebase|brownfield)", "codebase-analysis"),
            (r"(impact.analysis|downstream.{0,10}impact|cascade)", "impact-analysis"),
        ],
        "REK": [
            (r"(rollout.risk|risk.assessment|adversarial.{0,10}release)", "rollout-risk-assessment"),
            (r"(release.communication|stakeholder.{0,10}communi)", "release-communication"),
        ],
        "RRK": [
            (r"(slo.calibration|calibrat.{0,10}slo|baseline.{0,10}data)", "slo-calibration"),
            (r"(escalation.assessment|trigger.{0,10}escalation)", "escalation-assessment"),
        ],
    }

    # Check utilities for the entry kit
    if entry_kit in kit_utilities:
        utilities = kit_utilities[entry_kit]
        found_any = any(
            re.search(pattern, content, re.IGNORECASE)
            for pattern, _ in utilities
        )
        if not found_any:
            names = [name for _, name in utilities]
            issues.append(
                f"No {entry_kit}-specific utility prompts offered: expected one of {names}"
            )

    # Check utilities for transitioning kits
    for transition in config.get("kit_transitions", []):
        kits = re.split(r"[→>-]", transition)
        if len(kits) >= 2:
            to_kit = kits[1].strip()
            if to_kit in kit_utilities:
                utilities = kit_utilities[to_kit]
                found_any = any(
                    re.search(pattern, content, re.IGNORECASE)
                    for pattern, _ in utilities
                )
                if not found_any:
                    names = [name for _, name in utilities]
                    issues.append(
                        f"No {to_kit}-specific utility prompts offered at transition: expected one of {names}"
                    )

    return issues


def check_cross_cutting_timing(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa mentioned cross-cutting kit trigger points at the right time.

    Cross-cutting kits should be surfaced when their trigger artifact is frozen,
    not before and not forgotten.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Check if the test generated enough artifacts for cross-cutting to matter
    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 4:
        return issues  # Too few artifacts for cross-cutting timing to be testable

    # Trigger awareness patterns
    trigger_patterns = [
        r"(SAD|architecture).{0,30}(trigger|activat|time\s+to|now.{0,10}(SCK|security|threat))",
        r"(TDD|design).{0,30}(trigger|activat|time\s+to|now.{0,10}(DCK|config|DKK|doc|API\s+ref))",
        r"(ORD|code\s+complete).{0,30}(trigger|activat|time\s+to|now.{0,10}(SCK|DAR|dependency))",
        r"(cross.cutting|optional\s+kit).{0,30}(trigger|activated|now|ready)",
        r"(SCK|DCK|DKK|BPK|PINFK|PRK).{0,30}(trigger|activated|should|can\s+now|at\s+this\s+point)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in trigger_patterns)
    if not found:
        issues.append(
            "No cross-cutting kit trigger timing evidence found "
            "(sherpa should surface cross-cutting kits when their trigger artifact freezes)"
        )

    return issues


def check_health_dashboard_depth(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify health dashboard includes specific calculations, not just keywords.

    Enhanced version: checks for staleness signals, cross-cutting gap analysis,
    and upcoming junction forecasting.
    """
    issues = []

    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    depth_parts = 0

    # Part 1: Artifact status summary (counts or inventory)
    status_patterns = [
        r"\d+\s+(artifact|frozen|validated|generated)",
        r"(frozen|validated|draft)[:=]\s*\d+",
        r"(complete|remaining|next).{0,20}\d+",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in status_patterns):
        depth_parts += 1

    # Part 2: Cross-cutting gap detection
    gap_patterns = [
        r"(cross.cutting|optional).{0,30}(not\s+started|gap|missing|pending|deferred)",
        r"(SCK|QAK|DCK|DKK|PINFK|PRK|BPK).{0,30}(not\s+(yet|started)|pending|deferred|skipped)",
        r"(adopt|skip).{0,20}decision.{0,20}(pending|needed|outstanding)",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in gap_patterns):
        depth_parts += 1

    # Part 3: Upcoming junction forecast
    junction_patterns = [
        r"(next|upcoming|approaching).{0,30}(decision|junction|fork|choice)",
        r"(will\s+need|should\s+decide|coming\s+up).{0,30}(QAK|SSK|Path|release|deploy)",
        r"(before|after).{0,20}(freeze|generate).{0,20}(decide|choose)",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in junction_patterns):
        depth_parts += 1

    if depth_parts < 1:
        issues.append(
            f"Health dashboard lacks depth: found {depth_parts}/3 elements "
            f"(sherpa should include artifact status counts, cross-cutting gap analysis, "
            f"and upcoming junction forecasts)"
        )

    return issues


def check_sub_agent_awareness(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa demonstrated awareness of parallel execution patterns.

    Checks for mentions of parallelism (PRK lens independence, ACF||SAD,
    cross-cutting independence) in the transcript.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    parallel_patterns = [
        r"(parallel|simultaneous|concurrent|independent).{0,30}(lens|review|execution|session)",
        r"(ACF|SAD).{0,10}(and|&).{0,10}(ACF|SAD).{0,20}(parallel|simultaneous|both)",
        r"(lens|review).{0,20}independen",
        r"(fan.out|reconverg|aggregat).{0,20}(lens|result|output)",
        r"cross.cutting.{0,20}(parallel|independent|do\s+not\s+block)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in parallel_patterns)
    if not found:
        issues.append(
            "No parallelism awareness evidence found "
            "(sherpa should mention lens independence, ACF||SAD parallelism, or cross-cutting independence)"
        )

    return issues


def check_reentry_awareness(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa demonstrated awareness of re-entry protocols.

    Checks for mentions of material vs non-material changes, impact analysis,
    or cascade implications when modifying frozen artifacts.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Only check if there are frozen artifacts that could trigger re-entry discussion
    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 2:
        return issues

    reentry_patterns = [
        r"(material|non.material).{0,20}(change|amendment|modification)",
        r"(impact.analysis|downstream.{0,10}impact|cascade)",
        r"(amend|amendment).{0,20}(log|in.place|non.material)",
        r"(frozen|immutable).{0,20}(cannot|must\s+not|do\s+not).{0,10}(edit|change|modify)",
        r"re.entry.{0,20}(protocol|process|procedure)",
        r"(change|modif).{0,20}frozen.{0,20}(artifact|document)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in reentry_patterns)
    if not found:
        issues.append(
            "No re-entry protocol awareness found "
            "(sherpa should mention material vs non-material changes and immutability of frozen artifacts)"
        )

    return issues


def check_session_resumption_depth(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify session resumption includes journal reconstruction and position-check.

    Enhanced version: beyond detecting existing ER, checks for journal context
    loading and explicit position determination.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    depth_parts = 0

    # Part 1: ER discovery
    er_patterns = [
        r"(found|discover|see|existing).{0,30}(ER|engagement\s+record)",
        r"(ER|engagement\s+record).{0,20}(exists|found|present)",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in er_patterns):
        depth_parts += 1

    # Part 2: Journal reconstruction
    journal_patterns = [
        r"(journal|sherpa.journal).{0,30}(read|load|review|found|check)",
        r"(prior|previous|last).{0,20}(session|decision|routing)",
        r"(history|context).{0,20}(from|in).{0,20}(journal|ER|prior)",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in journal_patterns):
        depth_parts += 1

    # Part 3: Position determination
    position_patterns = [
        r"(current|your).{0,20}(position|state|progress).{0,20}(is|at|in)",
        r"(left\s+off|resume|continue|pick\s+up).{0,20}(at|from|where)",
        r"(next|remaining).{0,20}(artifact|step|action)",
    ]
    if any(re.search(pat, content, re.IGNORECASE) for pat in position_patterns):
        depth_parts += 1

    if depth_parts < 2:
        issues.append(
            f"Session resumption lacks depth: found {depth_parts}/3 elements "
            f"(sherpa should discover ER, load journal context, and determine current position)"
        )

    return issues


def check_risk_surfaced(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa surfaced upstream risk signals before artifact generation."""
    issues = []

    # Only check if there are enough artifacts to have upstream risks
    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues  # Too few artifacts — risk scan not meaningful

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    risk_patterns = [
        r"(risk|concern|flag|notice|heads.up).{0,30}(upstream|frozen|prior|earlier)",
        r"(TBD|to\s+be\s+determined|out\s+of\s+scope\s+for\s+now).{0,30}(in|from|upstream)",
        r"assumption.{0,20}(untested|AI.derived|unvalidated)",
        r"(missing|gap|inconsistenc).{0,30}(cross.reference|between|PRD|SAD|TDD)",
        r"(conflict|contradict).{0,30}(constraint|requirement|upstream)",
        r"before\s+(I\s+)?generat.{0,30}(notice|flag|found|see)",
        # WS4: Structured risk scan output pattern
        r"Risk scan:\s*\d+\s*signal",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in risk_patterns)
    if not found:
        issues.append(
            "No upstream risk surfacing evidence found (sherpa should scan frozen artifacts for risk patterns before generating)"
        )

    return issues


def check_path_prediction(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa presented a predictive path summary at routing time."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of concrete artifact counts and bottleneck warnings
    prediction_patterns = [
        r"\d+\s+(required\s+)?artifact",
        r"(cross.cutting|optional)\s+kit",
        r"decision\s+(point|junction)",
        r"(bottleneck|high.effort|pause|typically\s+requires)",
        r"(roadmap|journey|path).{0,30}\d+",
    ]
    found_count = sum(
        1 for pat in prediction_patterns
        if re.search(pat, content, re.IGNORECASE)
    )
    if found_count < 2:
        issues.append(
            f"Path prediction lacks specificity: found {found_count}/5 prediction elements "
            f"(sherpa should present exact artifact count, cross-cutting kits, decision points, and bottleneck alerts)"
        )

    return issues


def check_fast_path_used(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa used fast-path detection for cross-cutting kit decisions."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    # Look for evidence of pre-filled recommendations
    fast_path_patterns = [
        r"(recommend|suggesting).{0,30}(skip|adopt|include|decline).{0,30}(SCK|QAK|DCK|PINFK|DKK|PRK|BPK)",
        r"(skip|decline).{0,30}(because|since|no\s+PII|no\s+auth|no\s+API|internal|solo)",
        r"(adopt|include).{0,30}(because|since|PII|auth|compliance|external|user.facing)",
        r"sound\s+right",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in fast_path_patterns)
    if not found:
        issues.append(
            "No fast-path cross-cutting kit decision evidence found (sherpa should pre-fill obvious skip/adopt decisions with reasoning)"
        )

    return issues


def check_quality_score_surfaced(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa surfaced completeness scores after validation.

    WARN rationale: The completeness score exists in validator JSON output; verbal
    announcement to the user is a nice-to-have quality coaching behavior. The score
    is captured in the ER regardless. Promote to hard check when: validator output
    parsing confirms score is always computed (i.e., the issue is announcement, not
    computation).
    """
    issues = []

    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 2:
        return issues

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    score_patterns = [
        r"completeness.{0,10}(score|rating).{0,10}\d+",
        r"score.{0,5}\d+\s*/\s*100",
        r"\d+/100",
        r"(strong|adequate|thin).{0,20}(score|completeness|quality)",
        r"(score|completeness).{0,10}(of\s+)?\d+",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in score_patterns)
    if not found:
        issues.append(
            "No completeness score surfaced after validation (sherpa should present score with assessment)"
        )

    return issues


def check_consistency_check_run(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa ran cross-artifact consistency checks."""
    issues = []

    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues  # Need enough artifacts for cross-checking

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    consistency_patterns = [
        r"consistency.{0,20}check",
        r"cross.artifact.{0,20}(check|verify|align|consistent)",
        r"(PRD|SAD|TDD|WDD).{0,30}(covers|maps|aligns|matches|consistent).{0,30}(PRD|SAD|TDD|WDD|capability|component|interface)",
        r"\d+\s+of\s+\d+\s+(capabilit|component|interface|item)",
        r"(missing|gap|mismatch).{0,30}(PRD|SAD|TDD|WDD|§)",
        # WS4: Structured consistency check output patterns
        r"Consistency:\s*(PRD|SAD|TDD|WDD|VH|DPRD|ORD)",
        r"\d+\s+of\s+\d+.{0,20}(mapped|covered|aligned)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in consistency_patterns)
    if not found:
        issues.append(
            "No cross-artifact consistency check evidence found (sherpa should verify alignment between frozen artifacts)"
        )

    return issues


def check_finding_accumulated(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa detected or offered to log framework findings during the initiative.

    WARN rationale: Finding accumulation is a meta-cognitive task requiring simultaneous
    artifact generation + framework critique. Rare in single-pass headless sessions where
    budget is focused on artifact production. Promote to hard check when: multi-session
    tests show >50% detection rate for planted framework gaps.
    """
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    finding_patterns = [
        r"framework\s+(gap|finding|issue)",
        r"(template|spec|validator).{0,20}(gap|mismatch|doesn.t\s+(apply|fit|cover))",
        r"(log|record|note).{0,20}(finding|gap|issue)",
        r"FINDING-\d+",
        r"(this|that).{0,20}(might|could|looks\s+like).{0,20}(framework|gap|finding)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in finding_patterns)
    if not found:
        issues.append(
            "No framework finding detection evidence found (sherpa should watch for template mismatches, spec gaps, and offer to log findings)"
        )

    return issues


def check_template_prepopulated(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa pre-populated template sections from upstream artifacts."""
    issues = []

    expected_frozen = sum(
        1 for a in config.get("expected_artifacts", []) if a.get("frozen", False)
    )
    if expected_frozen < 3:
        return issues  # Need enough artifacts for pre-population to matter

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    prepop_patterns = [
        r"pre.fill",
        r"pre.populat",
        r"(filled|populated).{0,20}(from|using|based\s+on).{0,20}(upstream|frozen|prior|PRD|SAD|PFD)",
        r"\d+\s+of\s+\d+\s+section",
        r"(carried|copied|inherited).{0,20}(from|over).{0,20}(upstream|frozen|PRD|SAD|TDD)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in prepop_patterns)
    if not found:
        issues.append(
            "No template pre-population evidence found (sherpa should pre-fill sections from frozen upstream artifacts)"
        )

    return issues


def check_retrospective_generated(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify initiative retrospective was generated at completion."""
    issues = []
    retro_files = list(project_dir.glob("docs/engagement/retrospective-*.md"))
    if not retro_files:
        # Check transcript for retrospective content (may not have been saved as file in test)
        output_log = run_dir / "claude-output.log"
        transcript = run_dir / "session-transcript.md"

        content = ""
        if output_log.exists():
            content = output_log.read_text()
        elif transcript.exists():
            content = transcript.read_text()

        if content:
            retro_patterns = [
                r"retrospective",
                r"artifact\s+timeline",
                r"quality\s+trajectory",
                r"decision\s+log",
                r"cycle\s+metrics",
            ]
            found = any(re.search(pat, content, re.IGNORECASE) for pat in retro_patterns)
            if not found:
                issues.append("No retrospective generated at completion")
        else:
            issues.append("No retrospective file or content found")

    return issues


def check_self_score_generated(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa self-scoring was generated at completion."""
    issues = []

    # Check for self-score file
    score_files = list(run_dir.glob("self-score-*.md"))
    if score_files:
        return issues

    # Check output directory
    output_dir = project_dir.parent / "aieos-governance-foundation" / "tests" / "integration" / "output"
    if output_dir.exists():
        score_files = list(output_dir.glob("self-score-*.md"))
        if score_files:
            return issues

    # Check transcript for self-scoring content
    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if content:
        score_patterns = [
            r"self.scor",
            r"(criterion|criteria).{0,20}(score|rating|evaluation)",
            r"(my|sherpa).{0,20}(performance|evaluation|assessment)",
            r"\d+\s*/\s*(5|75)",
        ]
        found = any(re.search(pat, content, re.IGNORECASE) for pat in score_patterns)
        if not found:
            issues.append("No self-scoring generated at completion")
    else:
        issues.append("No self-score file or content found")

    return issues


def check_ideation_mode_offered(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa offered ideation mode when user signaled no concrete idea."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    ideation_patterns = [
        r"ideation",
        r"brainstorm",
        r"workshop",
        r"(generate|come\s+up\s+with|explore).{0,20}(ideas|opportunities|options)",
        r"(jobs.to.be.done|constraint\s+removal|competitive\s+gap|technology\s+enablement|inversion|SCAMPER|signal\s+synthesis)",
        r"(technique|approach).{0,20}(brainstorm|ideate|generate\s+ideas)",
        r"ideation.workshop.record",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in ideation_patterns)
    if not found:
        issues.append(
            "No ideation mode evidence found (sherpa should offer structured ideation when user signals 'I don't know what to build')"
        )

    return issues


def check_cross_initiative_scan(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa scanned for sibling initiatives and mentioned any found."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    scan_patterns = [
        r"(found|detect|scan|discover).{0,30}(initiative|project|ER|engagement)",
        r"(other|sibling|parallel|active).{0,20}initiative",
        r"(no|zero|0).{0,20}(other|sibling).{0,20}initiative",
        r"(overlap|conflict|shared).{0,20}(component|system|module)",
        r"cross.initiative",
        # WS1: "Scan found nothing" patterns (correct behavior in test environment)
        r"(no|don.t see|didn.t find).{0,30}(other|sibling|existing).{0,20}(initiative|project|ER)",
        r"(only|single|just).{0,20}(initiative|project)",
        r"(scann|check|look).{0,30}(parent|sibling|adjacent).{0,20}(director|folder|project)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in scan_patterns)
    if not found:
        issues.append(
            "No cross-initiative scan evidence found (sherpa should scan for sibling initiatives at routing)"
        )

    return issues


def check_parallel_execution(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa offered or used parallel artifact generation where applicable."""
    issues = []

    # Only check if the preset traverses EEK (where parallelism is most relevant)
    expected_types = [a["type"] for a in config.get("expected_artifacts", [])]
    has_parallel_candidates = (
        ("ACF" in expected_types and "SAD" in expected_types) or
        ("DCF" in expected_types and "TDD" in expected_types)
    )
    if not has_parallel_candidates:
        return issues  # No parallelizable pairs in this preset

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    parallel_patterns = [
        r"(parallel|simultaneous|concurrent).{0,30}(generat|creat|produc)",
        r"(ACF|SAD|DCF|TDD).{0,10}(and|&|\+).{0,10}(ACF|SAD|DCF|TDD).{0,20}(parallel|same\s+time|simultaneous)",
        r"(independent|both\s+depend).{0,30}(parallel|simultaneous)",
        r"(fan.out|sub.agent|agent).{0,30}(parallel|concurrent|simultaneous)",
        r"(save\s+time|faster|efficient).{0,30}(parallel|both|simultaneous)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in parallel_patterns)
    if not found:
        issues.append(
            "No parallel execution evidence found (sherpa should offer to generate parallelizable artifact pairs like ACF+SAD or DCF+TDD simultaneously)"
        )

    return issues


def check_artifact_id_discipline(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify generated artifacts use correct ID format: {TYPE}-{INITIATIVE}-{NNN}."""
    issues = []
    initiative = config.get("initiative_pattern", "")
    if not initiative:
        return issues

    for artifact in config.get("expected_artifacts", []):
        if artifact["type"] in ("routing-record", "intake"):
            continue
        glob_pattern = artifact["glob"]
        files = list(project_dir.glob(f"docs/sdlc/{glob_pattern}.md"))
        for f in files:
            content = f.read_text()
            artifact_type = artifact["type"]
            # Check for properly formatted artifact ID
            id_pattern = rf"{artifact_type}-{initiative}-\d{{3}}"
            if not re.search(id_pattern, content, re.IGNORECASE):
                # Also check uppercase initiative
                id_pattern_upper = rf"{artifact_type}-{initiative.upper()}-\d{{3}}"
                if not re.search(id_pattern_upper, content):
                    issues.append(
                        f"{f.name} missing properly formatted artifact ID "
                        f"(expected {artifact_type}-{initiative.upper()}-NNN)"
                    )

    return issues


def check_generation_validation_separation(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa enforced separate generation and validation sessions."""
    issues = []

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    separation_patterns = [
        r"separate.{0,20}(session|step|pass)",
        r"(validat|evaluat).{0,20}(separate|different|new).{0,20}(session|step|pass)",
        r"(now|next).{0,10}(validat|evaluat)",
        r"(generat|produc).{0,30}(then|now).{0,10}(validat|evaluat)",
        r"(do\s+not|never).{0,20}(self.validat|validat.{0,10}(same|own))",
        # WS1: Implicit separation (sherpa re-reads file for validation)
        r"(let me|I.ll|going to).{0,20}(review|check|validate|evaluate).{0,20}(against|using).{0,20}(gate|spec|validator)",
        r"(reading|checking|evaluating).{0,20}(hard gate|validator|spec)",
        r"(gate\s+\d+|hard.gate).{0,10}(PASS|FAIL|pass|fail)",
        r"(all\s+\d+\s+gates?\s+pass|passed\s+all)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in separation_patterns)
    if not found:
        issues.append(
            "No evidence of generation/validation separation "
            "(sherpa should generate then validate in distinct steps)"
        )

    return issues


def check_boundary_contract_verified(config: dict, run_dir: Path, project_dir: Path) -> list[str]:
    """Verify sherpa checked boundary contracts at kit transitions."""
    issues = []

    transitions = config.get("kit_transitions", [])
    if not transitions:
        return issues

    output_log = run_dir / "claude-output.log"
    transcript = run_dir / "session-transcript.md"

    content = ""
    if output_log.exists():
        content = output_log.read_text()
    elif transcript.exists():
        content = transcript.read_text()

    if not content:
        return issues

    boundary_patterns = [
        r"entry.from",
        r"boundary.{0,20}(contract|briefing|check)",
        r"(upstream|input).{0,20}(artifact|document).{0,20}(present|confirmed|available|frozen)",
        r"(DPRD|ORD|RR|QGR|SDR).{0,20}(frozen|confirmed|received|present)",
        r"(prerequisite|required\s+input).{0,20}(check|confirm|verify)",
        # WS4: Structured boundary check output patterns
        r"Boundary check:\s*Read entry.from",
        r"All present:\s*(yes|no)",
    ]
    found = any(re.search(pat, content, re.IGNORECASE) for pat in boundary_patterns)
    if not found:
        issues.append(
            f"No boundary contract verification found at kit transition(s) {transitions} "
            f"(sherpa should verify upstream artifacts are frozen and read entry-from docs)"
        )

    return issues


CHECK_REGISTRY: dict[str, callable] = {
    "ar_origin":                    check_ar_origin,
    "el_draft":                     check_el_draft,
    "routing_record":               check_routing_record,
    "er_completeness":              check_er_completeness,
    "frozen_artifacts":             check_frozen_artifacts,
    "provenance":                   check_provenance,
    "no_ready_prompts":             check_no_ready_prompts,
    "utility_prompts_mentioned":    check_utility_prompts_mentioned,
    "kit_transition_explanations":  check_kit_transition_explanations,
    "cross_cutting_adoption":       check_cross_cutting_adoption,
    "convergence_loop":             check_convergence_loop,
    "ker_justification":            check_ker_justification,
    "no_force_routing":             check_no_force_routing,
    "el_pause_outcome":             check_el_pause_outcome,
    "no_dprd":                      check_no_dprd,
    "session_resumption":           check_session_resumption,
    "elicitation_applied":          check_elicitation_applied,
    "adversarial_lens_offered":     check_adversarial_lens_offered,
    "briefing_distillation_offered": check_briefing_distillation_offered,
    "decision_explanation_depth":   check_decision_explanation_depth,
    "position_check_invoked":       check_position_check_invoked,
    "handoff_navigator_invoked":    check_handoff_navigator_invoked,
    "decision_router_invoked":      check_decision_router_invoked,
    "intent_resolution":            check_intent_resolution,
    "intent_translation_timing":    check_intent_translation_timing,
    "conditional_opening":          check_conditional_opening,
    "intake_quality_probe":         check_intake_quality_probe,
    "decision_explanation":         check_decision_explanation,
    "health_dashboard":             check_health_dashboard,
    "journal_exists":               check_journal_exists,
    "journal_entries":              check_journal_entries,
    "rationale_replay":             check_rationale_replay,
    "risk_surfaced":                check_risk_surfaced,
    "path_prediction":              check_path_prediction,
    "fast_path_used":               check_fast_path_used,
    "quality_score_surfaced":       check_quality_score_surfaced,
    "consistency_check_run":        check_consistency_check_run,
    "finding_accumulated":          check_finding_accumulated,
    "cross_initiative_scan":        check_cross_initiative_scan,
    "ideation_mode_offered":        check_ideation_mode_offered,
    "parallel_execution":           check_parallel_execution,
    "template_prepopulated":        check_template_prepopulated,
    "retrospective_generated":      check_retrospective_generated,
    "self_score_generated":         check_self_score_generated,
    "convergence_loop_depth":       check_convergence_loop_depth,
    "utility_prompts_per_kit":      check_utility_prompts_per_kit,
    "cross_cutting_timing":         check_cross_cutting_timing,
    "health_dashboard_depth":       check_health_dashboard_depth,
    "sub_agent_awareness":          check_sub_agent_awareness,
    "reentry_awareness":            check_reentry_awareness,
    "session_resumption_depth":     check_session_resumption_depth,
    "artifact_id_discipline":       check_artifact_id_discipline,
    "generation_validation_separation": check_generation_validation_separation,
    "boundary_contract_verified":   check_boundary_contract_verified,
}


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <preset> <run_dir> <project_dir>")
        sys.exit(1)

    preset = sys.argv[1]
    run_dir = Path(sys.argv[2])
    project_dir = Path(sys.argv[3])

    config = load_config(preset)

    preset_label = config.get("preset_name", preset)
    print(f"\n  Sherpa {config['preset']} Post-Analysis ({preset_label})")
    print("  " + "─" * 40)

    all_issues = []

    # Run hard checks
    hard_check_names = config.get("hard_checks", [])
    hard_results = []
    for name in hard_check_names:
        fn = CHECK_REGISTRY.get(name)
        if fn is None:
            print(f"  SKIP  {name} (unknown check)")
            continue
        issues = fn(config, run_dir, project_dir)
        hard_results.append((name, issues))

    # Run soft checks
    soft_check_names = config.get("soft_checks", [])
    soft_results = []
    for name in soft_check_names:
        fn = CHECK_REGISTRY.get(name)
        if fn is None:
            print(f"  SKIP  {name} (unknown check)")
            continue
        issues = fn(config, run_dir, project_dir)
        soft_results.append((name, issues))

    # Print hard check results
    for name, issues in hard_results:
        if issues:
            print(f"  FAIL  {name}")
            for issue in issues:
                print(f"         └─ {issue}")
            all_issues.extend(issues)
        else:
            print(f"  PASS  {name}")

    # Print soft check results
    for name, issues in soft_results:
        if issues:
            print(f"  WARN  {name} (non-deterministic LLM behavior)")
            for issue in issues:
                print(f"         └─ {issue}")
        else:
            print(f"  PASS  {name}")

    print("  " + "─" * 40)

    # Write results
    total = len(hard_results) + len(soft_results)
    results = {
        "preset": config["preset"],
        "total_checks": total,
        "passed": sum(1 for _, issues in hard_results + soft_results if not issues),
        "failed": sum(1 for _, issues in hard_results if issues),
        "warned": sum(1 for _, issues in soft_results if issues),
        "issues": all_issues,
    }

    results_file = run_dir / "post-analysis.json"
    results_file.write_text(json.dumps(results, indent=2))
    print(f"  Results written to: {results_file}")

    if all_issues:
        print(f"\n  Result: FAIL ({len(all_issues)} issue(s))")
        return 1
    else:
        print("\n  Result: PASS")
        return 0


if __name__ == "__main__":
    sys.exit(main())
