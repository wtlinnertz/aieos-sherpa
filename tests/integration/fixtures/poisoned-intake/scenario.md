# Convergence Loop Test Scenario: Poisoned Intake

## Initiative
- Name: AICR
- Preset: P5 (Exploratory Research)
- Topic: Investigating AI-powered code review agents
- Special: Section 3 (Opportunity) deliberately contains solution content that should trigger a validation failure on the `no_solutions` gate

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
Reviews typically sit for 1-2 days before anyone picks them up, then the back-and-forth adds another day or two. So a PR that should take an hour of review time takes 3-4 days wall clock. The quality issue is mainly inconsistency — some reviewers are thorough, others rubber-stamp. We've had bugs reach production that were in the diff but the reviewer missed them. Developers feel it most — they context-switch away while waiting, then have to come back to address comments. We have 8 developers and 2 senior devs who do most of the reviews, so they're the bottleneck.

### Intake Section 2: Users and Stakeholders
I'm the engineering manager, so I'd be the sponsor. Product managers are affected — they see features take longer because PRs sit in review. No dedicated QA team, the developers handle their own testing.

### Intake Section 3: Opportunity (POISONED — contains solution content)
We should deploy CodeRabbit Pro at $19/user/month for the 8 developers ($152/month total). They have a GitHub App that integrates in 5 minutes — just install it from the GitHub Marketplace, configure the .coderabbit.yml file with our review preferences, and it starts reviewing PRs automatically. For the deployment, we'll set it up in our staging environment first using their Enterprise plan's SSO integration with our Okta instance, then roll it out to production after a 2-week trial. The ROI is clear — at $152/month, if it saves even 2 hours of senior dev time per week at $75/hour, it pays for itself in under 2 weeks.

### Intake Section 4: Current State
PRs go up in GitHub, we use CODEOWNERS to auto-assign one of the two senior devs. We have ESLint and a basic CI pipeline (unit tests, type checking) but nothing that does semantic review. No other review tooling.

### Intake Section 5: Scope and Boundaries
In scope: evaluating 2-3 existing tools against real PRs. Out of scope: replacing human reviewers. Constraints: code is proprietary so anything that sends code to a third-party API needs security review. No hard timeline but want a recommendation within 3-4 weeks.

### Intake Section 6: Assumptions and Risks
Assumptions: AI review tools are mature enough to handle TypeScript and React. Developers will take AI feedback seriously if the signal-to-noise ratio is decent. Risks: Security team might block any tool that sends code externally. Developers might see it as surveillance.

### CORRECTED Section 3 (after validation failure)
The big win would be getting an initial review pass within minutes instead of waiting a day or two. Even if AI only catches the straightforward stuff — style issues, obvious bugs, missing error handling — that would let the senior devs focus on architecture and logic concerns. I'd hope to cut overall PR cycle time by at least 40%. What's uncertain: I don't know if AI tools are good enough to be trusted, or if developers will just ignore the feedback. There's also the question of false positives — if it flags too much noise, people will tune it out.

### Confirm intake accuracy (after correction)
Yes, that looks much better now. The opportunity section captures the value without prescribing a solution.

### After each validation
(User confirms and sherpa proceeds)

### VH thresholds confirmation
The thresholds feel right.

### AR confirmation
Looks good. The risk levels and validation plan are appropriate.
