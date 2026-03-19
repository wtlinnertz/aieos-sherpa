# P5 Exploratory Research Test Scenario: AI Code Review

## Initiative
- Name: AICR
- Preset: P5 (Exploratory Research)
- Topic: Investigating AI-powered code review agents

## User Responses (in conversation order)

### Initial request
I've been hearing a lot about using AI agents to automate code reviews. I'm not sure if it's actually viable for our team or just hype. I'd like to investigate whether it could work before we commit to building or buying anything.

### Clarifying question: problem understanding
We have some pain points — reviews take too long and quality is inconsistent — but I don't know if AI agents are the right answer or even what's available. I just want to explore the space.

### Clarifying question: hands-on vs recommendation
I'd want to try something hands-on if possible — maybe test one or two tools on some real PRs to see how they perform. Not a full build, just enough to know if it's worth pursuing.

### Confirm preset
Yes, that sounds right. Let's do it.

### Initiative name
AICR

### Intake Section 1: Problem Context
Reviews typically sit for 1-2 days before anyone picks them up, then the back-and-forth adds another day or two. So a PR that should take an hour of review time takes 3-4 days wall clock. The quality issue is mainly inconsistency — some reviewers are thorough, others rubber-stamp. We've had bugs reach production that were in the diff but the reviewer missed them. Developers feel it most — they context-switch away while waiting, then have to come back to address comments. We have 8 developers and 2 senior devs who do most of the reviews, so they're the bottleneck. No specific incident triggered this — it's been a growing pain as the team scaled from 4 to 8 over the past year. Review load doubled but reviewer count didn't. Evidence is mostly anecdotal — retro complaints every sprint, and we can pull PR cycle time from GitHub but haven't done a formal analysis.

### Intake Section 2: Users and Stakeholders
I'm the engineering manager, so I'd be the sponsor. Product managers are affected — they see features take longer because PRs sit in review. No dedicated QA team, the developers handle their own testing.

### Intake Section 3: Opportunity
The big win would be getting an initial review pass within minutes instead of waiting a day or two. Even if AI only catches the straightforward stuff — style issues, obvious bugs, missing error handling — that would let the senior devs focus on architecture and logic concerns. I'd hope to cut overall PR cycle time by at least 40%. What's uncertain: I don't know if AI tools are good enough to be trusted, or if developers will just ignore the feedback. There's also the question of false positives — if it flags too much noise, people will tune it out.

### Intake Section 4: Current State
PRs go up in GitHub, we use CODEOWNERS to auto-assign one of the two senior devs. We have ESLint and a basic CI pipeline (unit tests, type checking) but nothing that does semantic review. No other review tooling. We tried a review rotation a few months back to spread the load, but the junior devs didn't feel confident reviewing each other's code without a senior sign-off, so it collapsed back to the two seniors doing everything.

### Intake Section 5: Scope and Boundaries
In scope: evaluating 2-3 existing tools against real PRs. I'd also consider a lightweight custom integration if the off-the-shelf options don't fit, but that would be a separate decision after the research. Out of scope: replacing human reviewers — this is about augmenting, not replacing. Also not looking at AI coding assistants or test generation, just the review step. Constraints: code is proprietary so anything that sends code to a third-party API needs to be evaluated for security. We don't have a big budget — ideally free tiers or trials for the evaluation. No hard timeline but I'd like to have a recommendation within 3-4 weeks.

### Intake Section 6: Assumptions and Risks
Assumptions: AI review tools are mature enough to handle TypeScript and React, which is our stack. Developers will take AI feedback seriously if the signal-to-noise ratio is decent. The tools can run on PRs of our typical size (200-500 line diffs). Risks: Security team might block any tool that sends code externally. Developers might see it as surveillance or micromanagement. The tools might only be good at style/formatting and not catch real bugs, which would make it not worth the effort.

### Confirm intake accuracy
Looks good, the summary captures it well.

### After each validation
(User confirms and sherpa proceeds)

### VH thresholds confirmation
The thresholds feel right. The gap between falsification and success targets is a good call — gives us room to interpret "partially works."

### AR confirmation
ASM-6 is a great catch — I hadn't thought of it explicitly but you're right, we are assuming this. The risk levels and validation plan look right.
