# Manual Test Scenario: P5 with Persona B (Product Manager)

## Initiative
- Name: AICHAT
- Preset: P5 (Exploratory Research)
- Topic: AI chatbots for customer support — PM exploring viability
- Challenges: vague answer (Section 4), jargon test (VH), skip request (AR)

## User Responses (in conversation order)

### Initial request
Hi! I'm a product manager. Our support team is overwhelmed — ticket volume doubled this year. I'm wondering if AI chatbots could handle the simple repetitive questions. But I'm not sure if the tech is ready or if customers would accept it. I want to figure that out before investing. Can you help?

### Clarifying: new vs research
This is research. I don't want to commit to building or buying yet — need to understand if it's viable. CEO asked me to look into it but no budget or timeline.

### Confirm preset
That sounds perfect. Let's do exploratory.

### Initiative name
AICHAT

### Intake Section 1: Problem Context
Support handles 800 tickets/week, was 400 a year ago. 12 agents at capacity, first response went from 2hr to 8hr. Top categories: password resets (20%), billing (15%), how-to questions (30%) — all scripted. NPS dropped from 72 to 58, customers cite wait times.

### Intake Section 2: Users and Stakeholders
15,000 active users, mostly non-technical small business owners. Reach us via email, web widget, phone. Support lead Sarah is cautiously optimistic but worried about job security. VP of Product is exec sponsor.

### Intake Section 3: Opportunity
Deflecting 30% of tickets = 240/week saved. At $12/ticket = $150K/year savings. Real win is response time: seconds vs 8 hours. Uncertain: will older, less tech-savvy users use a chatbot?

### Intake Section 4: Current State (DELIBERATELY VAGUE — sherpa should probe)
We use Zendesk.

### After being probed for more on Section 4
Oh sorry. Zendesk for ticketing, email and web widget through Zendesk. No automation, no macros, no auto-responses, everything manual. Agents use a messy shared Google Doc as knowledge base. Looked at Zendesk's built-in bot last year but nobody set it up.

### Intake Section 5: Scope and Boundaries
In scope: evaluate if AI chatbots can handle top 3 categories, test 2-3 tools, maybe small pilot. Out of scope: replacing agents, phone support. Constraints: SOC 2 required, no heavy engineering — needs to plug into Zendesk.

### Intake Section 6: Assumptions and Risks
Assumptions: AI good enough for FAQ-type Qs, customers will engage if positioned right. Risks: customers hate it, bot gives wrong answers, knowledge base too messy to train on, support team morale.

### Confirm intake accuracy
Looks right.

### When VH introduced (JARGON TEST)
Wait — what's a VH? Is that like a business case?

### VH thresholds (after explanation)
OK makes sense. Success: deflect 30% of top 3 categories with 80% accuracy. Falsification: accuracy below 50% or less than 20% of eligible tickets interact with bot.

### AR review (SKIP REQUEST)
This overlaps with what I put in the intake. Can we skip this?

### After skip explanation
Fine, the structured approach is useful. Assumptions look right.

### If utility prompt offered
What's that? Sure, let's try it.

### EL confirmation
Experiment design looks reasonable. I like the phased approach.
