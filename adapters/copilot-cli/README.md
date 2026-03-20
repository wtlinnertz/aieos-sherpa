# Using the AIEOS Sherpa with GitHub Copilot CLI

This guide explains how to run the AIEOS sherpa — the AI-powered guide that walks you through building structured artifacts — inside a GitHub Copilot CLI session.

The sherpa works the same regardless of which AI runs it. Copilot CLI has a few differences from Claude Code, and this guide covers exactly what to expect and how to handle them.

---

## Quick Start

1. Open a terminal in your project directory (the one containing the `aieos-sherpa/` folder).
2. Start a Copilot CLI session (e.g., `gh copilot` or however your Copilot CLI is invoked).
3. Load the sherpa prompt using one of the approaches below.
4. **Quick test:** After loading, the sherpa should greet you and ask what you want to build or accomplish. If it does, you're ready to go.

---

## Loading the Sherpa

Pick the approach that matches your Copilot CLI setup.

### Approach A: Copilot CLI Can Read Files

If your Copilot CLI session can read files from disk, send this as your first message:

```
Read aieos-sherpa/sherpa-prompt.md and follow all instructions in it.
```

This is the simplest path. The sherpa prompt contains all the rules, routing logic, and behavioral instructions the AI needs.

### Approach B: Paste the Prompt Directly

If Copilot CLI cannot read files on its own:

1. Open `aieos-sherpa/sherpa-prompt.md` in a text editor.
2. Copy the entire contents.
3. Paste it as your first message in the Copilot CLI session.

The AI will read the instructions and begin operating as the sherpa.

### Approach C: Limited Context Window

If Copilot CLI is running a model with a small context window and the full prompt causes issues:

- Use `aieos-sherpa/sherpa-prompt-compact.md` instead (when available — see XAI-004 for the compressed variant).
- Follow the same steps as Approach A or B, but with the compact file.

---

## Known Limitations

These are differences between Copilot CLI and Claude Code that affect how the sherpa operates. None of them prevent the sherpa from working — they just change the workflow slightly.

### No Parallel Sub-Agent Orchestration

The sherpa sometimes offers to generate multiple artifacts in parallel (e.g., "I can draft the TDD and SAD at the same time"). Copilot CLI cannot fan out to multiple sub-agents. When this happens, the sherpa will proceed sequentially instead. Same artifacts, same quality, just one at a time.

### Session Persistence Varies

Copilot CLI sessions may not carry state between invocations. If you close a session and start a new one, the AI won't remember where you left off. This is handled by:

- The **Engagement Record** (ER §1b state block) — tracks which artifacts are complete, in-progress, or not started.
- The **Sherpa Journal** — a per-session log of decisions and progress.

Together, these give the sherpa everything it needs to pick up where you left off.

### Context Window Size Depends on the Model

Copilot CLI may use different models with different context limits. If you notice responses getting shorter, less accurate, or repetitive, the context window may be full. Start a new session and resume (see Workarounds below).

### Tool Names Differ

Claude Code uses specific tool names (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`). Copilot CLI uses its own file and shell operations. The sherpa's artifact generation and validation logic doesn't depend on specific tool names — it works with whatever file access the AI has.

---

## Workarounds

| Situation | What to Do |
|-----------|------------|
| **Sherpa offers parallel artifact generation** | Proceed sequentially. Tell it: "Generate them one at a time." The sherpa detects this and adapts. |
| **Session breaks or crashes** | Start a new session. The sherpa journal and ER state block have everything needed to resume. See the resumption command below. |
| **AI can't search for files** | Manually list the files the sherpa needs. Check the kit's `docs/playbook.md` for the expected file paths, or run `ls` in your terminal and paste the output. |
| **Context window exhausted** | Start a new session and send this as the first message: |

**Resumption command** (paste this into a new session):

```
Read aieos-sherpa/sherpa-prompt.md and resume initiative {NAME} from the ER at {path/to/er-NAME.md}.
```

Replace `{NAME}` with your initiative name and `{path/to/er-NAME.md}` with the actual path to your Engagement Record.

---

## What Works the Same

These sherpa capabilities work identically in Copilot CLI and Claude Code:

- **All artifact generation** — PRDs, TDDs, SADs, WDDs, and every other artifact type. The sherpa uses the same specs, templates, and prompts regardless of which AI is running.
- **All validation** — Validators produce the same PASS/FAIL JSON output. The sherpa applies the same hard gates.
- **Freeze protocol** — Artifacts are frozen the same way. Freeze-before-promote rules are enforced by the sherpa's logic, not by the AI platform.
- **Engagement Record and Sherpa Journal** — These are Markdown files. Any AI that can read and write files can maintain them.
- **Decision tables and routing logic** — The sherpa uses the same junction decisions (build/buy/adopt, fast-path criteria, escalation triggers) on every platform.
- **All 15 rubric criteria** — The conversation quality rubric applies to the sherpa's behavior regardless of which AI is underneath.
- **Specs, templates, prompts, and validators** — The entire four-file system is platform-independent Markdown. Nothing changes.
