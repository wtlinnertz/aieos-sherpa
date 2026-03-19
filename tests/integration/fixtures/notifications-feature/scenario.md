# P1 New Feature Test Scenario: Push Notifications

## Initiative
- Name: PUSHNOTIFY
- Preset: P1 (New Feature)
- Topic: Push notification system for mobile app — new capability requiring discovery

## User Responses (in conversation order)

### Initial request
We want to add push notifications to our mobile app. Users have been asking for reminders about upcoming deadlines and status changes on their tasks, but we've never had any notification capability. This is a brand new feature area for us.

### Clarifying question: problem understanding
It's a real gap — users are missing deadlines because they only see updates when they open the app. Our mobile app is for project management and right now it's purely pull-based. Users have to manually check for changes. We've had multiple customer interviews where notifications came up as the #1 requested feature.

### Clarifying question: discovery needed?
Definitely needs discovery. We don't know what notification events users actually want — there could be dozens of possible triggers and we need to figure out which ones are valuable vs noisy. We also haven't decided on the technical approach — APNs vs FCM vs a unified service, real-time vs batched, etc. Lots of open questions.

### Confirm preset
Yes, P1 New Feature is right. This needs full discovery before we start building.

### Initiative name
PUSHNOTIFY

### Intake Section 1: Problem Context
Users miss critical updates because our mobile app has no notification system. The app is a project management tool used by teams of 10-50 people. Key pain points: (1) deadline reminders — 34% of tasks are completed late, and users say they forgot about them, (2) assignment notifications — when a task is assigned or reassigned, the new owner doesn't know until they open the app, (3) comment replies — discussions stall because participants don't see new comments. We surveyed 200 users and 78% ranked notifications as their top feature request. Monthly churn is 8% and exit surveys cite "lack of timely updates" as the #2 reason after pricing.

### Intake Section 2: Users and Stakeholders
Primary users: project team members who use the mobile app daily. Secondary: project managers who need their teams to be responsive. Stakeholders: product VP (sponsor), mobile team lead (technical), customer success (will handle notification preference support). The mobile app has 12,000 MAU across iOS and Android.

### Intake Section 3: Opportunity
The opportunity is to transform our app from pull-based to proactive. If we can notify users about the right events at the right time, we expect to: (1) reduce late task completion from 34% to under 15%, (2) increase daily active usage by 20%+ as users return to the app in response to notifications, (3) reduce churn by addressing the #2 exit reason. The uncertain part: we don't know which notification types will be valuable vs annoying. Too many notifications = users disable them entirely. Too few = no behavior change. We need to discover the right balance through user research and experimentation.

### Intake Section 4: Current State
No notification infrastructure exists. The mobile app is React Native, with a Node.js/Express backend and PostgreSQL database. We have no message queue or event bus — everything is synchronous request/response. The app currently polls for updates every 60 seconds when in the foreground, which partially masks the problem for active users but does nothing for backgrounded sessions. We considered push notifications 6 months ago but deprioritized it for a billing feature. No prior technical spikes.

### Intake Section 5: Scope and Boundaries
In scope: discovering which notification events are valuable, validating with users, designing the notification strategy. Also in scope for the eventual build: the notification service, APNs/FCM integration, user preference management, and a notification center in the app. Out of scope: email notifications (separate initiative), SMS/text (cost prohibitive at our scale), in-app chat (different feature area). Constraints: must work on both iOS and Android, must comply with platform notification guidelines, must have per-notification-type opt-out.

### Intake Section 6: Assumptions and Risks
Assumptions: users will enable push notifications (industry average is ~60% opt-in for non-gaming apps). React Native has mature libraries for push notification handling. Our backend can be extended with an event bus without major refactoring. Risks: notification fatigue could actually increase churn if we get the frequency wrong. APNs/FCM token management adds operational complexity. Privacy implications — some users may not want coworkers to see notification previews on their lock screen. Platform rate limits could be an issue at scale.

### Confirm intake accuracy
Yes, that captures everything well.

### After each validation
(User confirms and sherpa proceeds)

### VH thresholds confirmation
Good thresholds. The falsification threshold of 30% opt-in is conservative enough — if less than a third of users want notifications, we should rethink the approach. The success target of 60% opt-in and 15% DAU increase feels right for a "proceed" decision.

### AR confirmation
The assumptions look complete. ASM-4 about React Native library maturity is worth calling out — good catch. The risk levels make sense.

### EL experiment design
I like the phased approach. The fake-door test for opt-in rates as experiment 1 makes sense — it's low cost and tells us quickly if users will actually enable notifications. For experiment 2, a small-scale beta with the top 5 notification types is a good way to measure engagement impact before building the full system.

### EL proceed decision
The experiments showed strong results — 67% opt-in on the fake door test (above our 60% success target), and beta users showed 28% increase in DAU. Proceed to DPRD.

### Cross-cutting kit decisions
QAK: accept — notifications touch multiple systems and need integration testing
SCK: decline — no sensitive data in notifications beyond task titles, existing auth model applies
DKK: accept — users will need documentation on notification preferences and management

### ACF context
React Native 0.72, Node.js 18 with Express, PostgreSQL 15, deployed on AWS (ECS Fargate). No existing message queue — will need to add one. Mobile app distributed via App Store and Google Play. Current release cadence is biweekly.

### SAD confirmation
The event bus architecture with Redis Streams and a dedicated notification service looks right. Separating the delivery layer (APNs/FCM) from the notification logic is a good call.
