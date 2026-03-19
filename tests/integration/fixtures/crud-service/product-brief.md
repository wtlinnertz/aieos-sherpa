# Product Brief — TaskTracker CRUD Service

## Summary

A REST API for managing tasks (create, read, update, delete) with status tracking, priority levels, and timestamps. Deployed as a Docker container with PostgreSQL storage.

## Problem

Small teams need a self-hosted task tracker that is simple, fast, and under their control.

## Proposed Solution

A Node.js/TypeScript REST API with:
- CRUD endpoints for tasks (/api/tasks)
- Task fields: title, description, status, priority, created_at, updated_at
- PostgreSQL persistence
- Docker deployment
- No authentication (internal network use)

## Acceptance Criteria

1. POST /api/tasks creates a task and returns 201
2. GET /api/tasks returns all tasks with filtering by status
3. GET /api/tasks/:id returns a single task or 404
4. PUT /api/tasks/:id updates a task and returns 200
5. DELETE /api/tasks/:id removes a task and returns 204
6. All endpoints respond under 100ms at p95 with 100 concurrent users
7. Docker image builds and runs with a single compose command

## Non-Goals

- User authentication or authorization
- Real-time notifications
- Reporting or analytics
- Frontend application (API only)

## Constraints

- Single developer, 2-week timeline
- Node.js + TypeScript + PostgreSQL
- Docker deployment
- No external service dependencies
