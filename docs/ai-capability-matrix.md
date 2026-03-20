# AI Capability Matrix for AIEOS Sherpa

This document maps the capabilities the sherpa expects from an AI assistant, which platforms provide them natively, and what to do when a capability is missing.

---

## Capability Matrix

| Capability | Required? | Claude Code | Copilot CLI | ChatGPT | Cursor | Generic Fallback |
|-----------|----------|-------------|-------------|---------|--------|-----------------|
| Read files from disk | Yes | `Read` tool | Native CLI file access | File upload or browsing | Native workspace access | User pastes file content into session |
| Write/create files | Yes | `Write`/`Edit` tools | Native CLI file creation | Code blocks (user saves) | Native workspace writes | User copies AI output to files manually |
| Search files by name/pattern | Recommended | `Glob` tool | `find`/`ls` via shell | Not available | Native search | User lists relevant files manually |
| Search file content | Recommended | `Grep` tool | `grep`/`rg` via shell | Not available | Native search | User searches and pastes relevant matches |
| Execute shell commands | Optional | `Bash` tool | Native shell access | Not available | Terminal integration | User runs commands in separate terminal |
| Parallel sub-agents | Optional | `Agent` tool | Not available | Not available | Not available | Sequential execution; sherpa skips parallel offers |
| Context window >100k tokens | Recommended | 1M tokens | Model-dependent (varies) | 128k (GPT-4o) | Model-dependent | Use compressed prompt variant (`sherpa-prompt-compact.md`) |
| Persistent memory across sessions | Recommended | `.claude/` memory system | Not available | Custom GPTs with memory | Not available | ER State Block (section 1b) + Sherpa Journal for resumption |
| Structured tool output (JSON) | Optional | Supported | Varies | Supported | Supported | AI outputs Markdown; validator JSON is best-effort |

---

## How the Sherpa Adapts

The sherpa is designed to degrade gracefully. When a capability is missing, it adjusts automatically or tells you what to do instead.

- **If parallel sub-agents are unavailable** — The sherpa generates artifacts sequentially instead of in parallel. No quality loss; it just takes more turns. The sherpa detects this and stops offering parallel generation.

- **If the context window is small** — Use the compressed prompt (`sherpa-prompt-compact.md`, when available). The sherpa still functions with all rules intact — the compressed version removes examples and verbose explanations, not rules.

- **If file search is unavailable** — The sherpa asks you to provide file listings or reads from known paths documented in each kit's playbook. You can run `ls` or `find` in a separate terminal and paste the results.

- **If persistent memory is unavailable** — The Engagement Record state block and Sherpa Journal provide full resumption capability. These were designed specifically for this case. When starting a new session, point the sherpa at these files and it picks up exactly where it left off.

- **If shell commands are unavailable** — You run structural validation (`check-structure.sh`) and other commands in a separate terminal and report the results back to the sherpa. The sherpa tells you exactly what to run.

---

## Minimum Viable AI for Sherpa

An AI needs only **two capabilities** to run the sherpa:

1. **Read files** (or receive pasted file content)
2. **Generate text output** (that the user saves as files)

That's it. Everything else — file search, shell commands, parallel agents, persistent memory — improves the experience but is not required.

With just these two capabilities, you can:
- Load the sherpa prompt (by pasting it)
- Generate every artifact type (the AI outputs text, you save it)
- Run validation (you run the validator prompt manually and paste results)
- Maintain the Engagement Record and Sherpa Journal (AI generates updates, you save them)
- Complete an entire initiative from Layer 1 through Layer 7

The sherpa was built to be AI-platform-independent. The framework is Markdown files. The rules live in specs. The routing lives in decision tables. None of that depends on any specific AI's tooling.
