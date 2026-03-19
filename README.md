# AIEOS Sherpa

Platform-agnostic AI guide for the [AIEOS governance framework](https://github.com/wtlinnertz/aieos-governance-foundation). Works with any AI that can read files — Claude, ChatGPT, Cursor, or any LLM with file system access.

## What It Does

The sherpa walks users through the full AIEOS initiative lifecycle:

1. **Discovery** — understands what you want to build, routes to the right preset (P1–P5)
2. **Setup** — creates project structure, Engagement Record, and Sherpa Journal
3. **Artifact Generation** — generates, validates, and freezes governance artifacts in sequence
4. **Kit Transitions** — manages handoffs between organizational layers (PIK → EEK → REK → RRK → IEK)
5. **Completion** — produces initiative retrospective, framework findings summary, and self-scoring

## Quick Start

**With Claude Code:**
```bash
# From the AIEOS root directory (where kit directories live)
# The .claude/skills/sherpa/SKILL.md delegates to this project
/sherpa
```

**With any AI:**
Paste the contents of `sherpa-prompt.md` as the system prompt or opening message. The AI needs file access to the AIEOS kit directories.

**Minimal:**
Paste `adapters/generic/bootstrap-prompt.md` — it points the AI to the canonical prompt.

## Prerequisites

This project **consumes** the AIEOS governance framework. It expects sibling directories:
```
your-workspace/
  aieos-governance-foundation/    # Required — specs, navigation map, tools
  aieos-product-intelligence-kit/ # Required for Layer 2 initiatives
  aieos-engineering-execution-kit/# Required for Layer 4 initiatives
  aieos-sherpa/                   # This project
  ...other kits as needed...
```

## Project Structure

```
sherpa-prompt.md              # Canonical prompt (single source of truth)
adapters/
  generic/bootstrap-prompt.md # Minimal paste-anywhere pointer
docs/                         # References to governance-foundation docs
tests/integration/            # Behavioral test suite
  configs/                    # 11 JSON configs (P1-P5, edge cases)
  drivers/                    # 9 headless AI test drivers
  fixtures/                   # Pre-scripted user scenarios
  validate-sherpa-run.py      # Post-run analysis (53+ behavioral checks)
```

## Editing

**Always edit `sherpa-prompt.md`** — this is the canonical file. Platform adapters delegate to it. Do not inline sherpa logic in adapter files.

The Claude Code skill at `.claude/skills/sherpa/SKILL.md` (in the parent AIEOS workspace) is a thin wrapper that reads `sherpa-prompt.md`.

## Version

See `VERSION` file.

## License

[MIT](LICENSE)
