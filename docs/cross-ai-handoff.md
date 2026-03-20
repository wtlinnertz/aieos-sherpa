# Cross-AI Session Handoff Protocol

How to move an in-progress AIEOS initiative between different AI providers (e.g., Claude at home, Copilot at work, ChatGPT on mobile) without losing position, context, or artifact integrity.

---

## When to Hand Off

- **Switching machines or environments** — home to work, laptop to desktop
- **Switching AI providers** — context window exhausted, provider preference, availability or outage
- **Session timeout or crash recovery** — the session ended before work was complete
- **Collaborative work** — one person uses Claude, another uses Copilot, both contribute to the same initiative

---

## Before Handing Off (Checklist)

Complete all five items before closing the current session. Target: under 2 minutes.

1. **Artifact state is clean.** The current artifact is either frozen or explicitly saved as a Draft file on disk. No artifact exists only in the chat window.
2. **ER State Block is current.** Verify `er-{INITIATIVE}-001.md` §1b — the `Last Updated` timestamp matches the latest activity and `Current Step` reflects where you actually are.
3. **Sherpa journal is up to date.** All recent decisions, freezes, and deferred items have entries in `sherpa-journal-{INITIATIVE}.md`.
4. **No in-flight validation.** If a validation was started, finish it. Do not hand off between "submit artifact" and "receive verdict."
5. **Partial intake is saved.** If you are mid-intake (answering discovery or routing questions), ask the AI to save partial responses into the artifact file before ending.

---

## What the New AI Needs to Read

Priority order (most important first):

| Priority | File | Why |
|----------|------|-----|
| 1 | `aieos-sherpa/sherpa-prompt.md` | The sherpa operating instructions. Load as system prompt or paste as the opening message. |
| 2 | `docs/engagement/er-{INITIATIVE}-001.md` | The Engagement Record, especially §1b State Block for current position and the artifact table for what exists. |
| 3 | `docs/engagement/sherpa-journal-{INITIATIVE}.md` | Decision context, user preferences, deferred items, health signals. |
| 4 | `docs/sdlc/00-routing-record.md` | The routing decision and preset selection — prevents the AI from re-asking routing questions. |
| 5 | Last 2–3 frozen artifacts | Immediate context on what was just produced. Check the ER artifact table for file paths. |
| 6 | Current kit's `CLAUDE.md` and `docs/playbook.md` | Kit-specific rules and artifact sequence for the layer you are in. |

---

## What is NOT Portable

These things live in the AI session and do not transfer between providers:

- **Conversation history** — lives in the provider's session, not on disk
- **In-memory context or reasoning** — the sherpa journal captures what matters; the rest is ephemeral
- **Tool-specific state** — `.claude/` memory files, ChatGPT custom instructions, Copilot workspace state
- **Partial generation output that was not saved to a file** — if the AI was mid-generation when the session ended, that output is lost

This is why the checklist above insists on saving everything to disk before closing.

---

## Resumption Command

Paste this to the new AI session, filling in the bracketed values:

```
Read aieos-sherpa/sherpa-prompt.md and follow all instructions.

Resume initiative {INITIATIVE} from the Engagement Record at
{project}/docs/engagement/er-{INITIATIVE}-001.md.

Read the §1b State Block for current position, then the Sherpa Journal
for decision context. Present a resumption summary before continuing.
```

---

## What Good Resumption Looks Like

The new AI should present something like:

> "Welcome back. I've read your ER and journal. You're working on {INITIATIVE} (P{N} {preset name}). You've frozen {N} artifacts through {last frozen}. The state block shows you're at {current step} in {current kit}. {Any deferred decisions or open health signals}. Ready to continue with {next action}?"

If the AI does not produce a summary like this, it has not read the required files. Point it to the specific files from the priority table above.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| AI doesn't know where I am | State block is stale or unread | Ask the AI to run position-check against the artifact directory (`docs/sdlc/`). |
| AI re-asks routing questions | It didn't read the routing record | Point it to `docs/sdlc/00-routing-record.md`. |
| AI generates an artifact I already have | It didn't read the ER artifact table | Point it to the ER and ask it to verify which artifacts are already frozen. |
| AI uses a different artifact format | It didn't read the kit's spec and template | Point it to the current kit's `CLAUDE.md`, then to the specific spec and template files for the artifact type. |
| AI skips the sherpa persona entirely | It didn't load the sherpa prompt | Re-paste `aieos-sherpa/sherpa-prompt.md` content as the system prompt or opening message. |
| AI hallucinates artifact content | It read the journal but not the frozen artifacts | Point it to the actual frozen files listed in the ER artifact table. |
