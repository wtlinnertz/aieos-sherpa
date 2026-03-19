# Discovery Intake — TaskTracker CRUD Service

## Initiative Description

Build a simple task tracking REST API that allows users to create, read, update, and delete tasks. Each task has a title, description, status (open/in-progress/done), priority (low/medium/high), and timestamps. The API serves a single-page frontend.

## Target Users

Small development teams (5-15 people) managing work items without heavyweight project management tools.

## Problem Statement

Teams need a lightweight, self-hosted task tracker that they control. Existing solutions are either too complex (Jira) or too limited (text files). The gap is a simple CRUD API with just enough structure to be useful.

## Success Criteria

- REST API supports full CRUD on tasks
- Tasks have status, priority, timestamps
- API response times under 100ms at p95
- Deployable via Docker
- No external service dependencies (self-contained)

## Constraints

- Must be deployable on a single machine
- No authentication required (internal use behind VPN)
- PostgreSQL as the data store
- Node.js/TypeScript runtime
- Budget: 1 developer, 2 weeks

## Known Risks

- Scope creep into features like user management, notifications, or reporting
- PostgreSQL schema evolution if requirements change after initial deployment
