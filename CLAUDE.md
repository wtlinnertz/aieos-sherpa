# AIEOS Sherpa

AI guide for the AIEOS governance framework. Platform-agnostic — works with any AI that can read files.

## What This Is

The sherpa is an AI-powered guide that walks users through the full AIEOS initiative lifecycle: routing, artifact generation, validation, freeze, kit transitions, and completion. It maintains an Engagement Record (the "passport") and a Sherpa Journal (the "reasoning log") throughout.

## Repository Structure

```
aieos-sherpa/
  sherpa-prompt.md              # Canonical sherpa instructions (single source of truth)
  VERSION                       # Sherpa version
  adapters/
    generic/bootstrap-prompt.md   # Paste-anywhere minimal version
    copilot-cli/README.md         # Copilot CLI loading guide
  docs/                         # Reference pointers to governance-foundation docs
  tests/integration/            # Behavioral test suite (configs, drivers, fixtures)
```

## How to Use

**With Claude Code:** The `.claude/skills/sherpa/SKILL.md` in the parent AIEOS workspace delegates to `sherpa-prompt.md`. Invoke with `/sherpa`.

**With any AI:** Paste `sherpa-prompt.md` as the system prompt or opening message. Ensure the AI has file access to the AIEOS framework directory.

**Minimal bootstrap:** Paste `adapters/generic/bootstrap-prompt.md` for the shortest path to a working sherpa session.

## Relationship to AIEOS Framework

The sherpa **consumes** the AIEOS governance framework — it reads specs, templates, prompts, validators, navigation maps, and playbooks from the `aieos-governance-foundation` and kit repositories. It does not modify framework files.

The sherpa **produces** project artifacts (PRD, SAD, TDD, etc.) in the user's initiative directory, following the framework's rules.

## Editing the Sherpa

**Always edit `sherpa-prompt.md`** — this is the canonical file. Platform adapters and the Claude Code skill delegate to it. Do NOT inline sherpa logic in adapter or skill files.

The Claude Code skill at `.claude/skills/sherpa/SKILL.md` (in the parent AIEOS workspace) is a thin wrapper — it reads `sherpa-prompt.md` and adds Claude Code-specific tool notes.
