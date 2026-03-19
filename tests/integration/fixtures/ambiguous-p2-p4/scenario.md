# Ambiguous Routing Test: P2 vs P4 (Enhancement vs Performance Fix)

## Initiative
- Name: APISLOWAMBIG
- Preset: Ambiguous (should trigger clarifying question)
- Topic: "API is slow, want to improve it" — could be enhancement or incident-triggered

## User Responses (in conversation order)

### Initial request
Our API is slow and I want to improve the performance. Response times have been creeping up over the past few months.

### Disambiguating response (steers toward P2)
No, there hasn't been an incident or a sudden spike. It's been a gradual degradation — response times went from 80ms p95 six months ago to 180ms p95 now. No outages, no alerts fired. We want to proactively optimize before it becomes a real problem. We know the bottleneck is in our database queries — we've already profiled it.

### Confirm preset after disambiguation
Right, P2 Enhancement. This is proactive optimization, not an incident response.

### Initiative name
APISLOWAMBIG
