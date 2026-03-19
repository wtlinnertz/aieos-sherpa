# AIEOS Sherpa

AI guide for the AIEOS governance framework. Platform-agnostic — works with any AI that can read files.

## What This Is

The sherpa is an AI-powered guide that walks users through the full AIEOS initiative lifecycle: routing, artifact generation, validation, freeze, kit transitions, and completion. It maintains an Engagement Record (the "passport") and a Sherpa Journal (the "reasoning log") throughout.

## Repository Structure

```
aieos-sherpa/
  sherpa-prompt.md              # Canonical sherpa instructions (single source of truth)
  adapters/
    claude-code/SKILL.md        # Claude Code skill wrapper
    generic/bootstrap-prompt.md # Paste-anywhere minimal version
  docs/
    journal-format.md           # Journal entry types and lifecycle
    conversation-rubric.md      # 15-criteria manual evaluation rubric
    test-log.md                 # Historical test session observations
  tests/integration/            # Automated behavioral test suite
    drivers/                    # Bash scripts invoking headless AI sessions
    fixtures/                   # Pre-scripted user interaction scenarios
    configs/                    # JSON configs defining expected checks per preset
    validate-sherpa-run.py      # Post-run behavioral analysis
    README.md                   # Test framework documentation
```

## How to Use

**With Claude Code:** Copy `adapters/claude-code/SKILL.md` to `.claude/skills/sherpa/SKILL.md` in your project. Invoke with `/sherpa`.

**With any AI:** Paste `sherpa-prompt.md` as the system prompt or opening message. Ensure the AI has file access to the AIEOS framework directory.

**Minimal bootstrap:** Paste `adapters/generic/bootstrap-prompt.md` for the shortest path to a working sherpa session.

## Relationship to AIEOS Framework

The sherpa **consumes** the AIEOS governance framework — it reads specs, templates, prompts, validators, navigation maps, and playbooks from the `aieos-governance-foundation` and kit repositories. It does not modify framework files.

The sherpa **produces** project artifacts (PRD, SAD, TDD, etc.) in the user's initiative directory, following the framework's rules.

## Editing the Sherpa

**Always edit `sherpa-prompt.md`** — this is the canonical file. Then regenerate platform adapters as needed. Do NOT edit adapter files directly (except for platform-specific metadata like YAML frontmatter).

The `.claude/skills/sherpa/SKILL.md` in the parent aieos directory should be replaced with `adapters/claude-code/SKILL.md` from this repo.
