---
name: sherpa
description: Start or continue an AIEOS initiative. Guides users through the full artifact lifecycle — routing, generation, validation, freeze, and kit transitions. Use when starting new work or resuming an in-progress initiative.
user-invocable: true
---

<!-- Claude Code adapter. This file wraps the canonical sherpa-prompt.md with
     Claude Code-specific metadata (YAML frontmatter) and tool conventions.
     The canonical prompt is the source of truth — this adapter adds only the
     frontmatter needed for Claude Code skill discovery. -->

<!-- IMPORTANT: When updating sherpa behavior, edit ../sherpa-prompt.md (the
     canonical file), then regenerate this adapter by copying the canonical
     content below the frontmatter. Do NOT edit sherpa logic in this file. -->

Read and follow all instructions in `aieos-sherpa/sherpa-prompt.md`. That file contains the complete, canonical sherpa behavior specification.

**Claude Code-specific notes:**
- Use the `Agent` tool for parallel artifact orchestration (sub-agent fan-out)
- Use `Read`, `Write`, `Edit` tools for file operations
- Use `Glob` and `Grep` for file discovery and content search
- The AIEOS framework is in the parent directory of `aieos-sherpa/`
