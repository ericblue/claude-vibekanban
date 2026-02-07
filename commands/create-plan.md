---
description: Create a development plan from a PRD with task breakdown
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks
---

# Create Development Plan

## Context

You are creating a structured development plan based on a PRD. This plan will serve as:
1. A roadmap for implementation organized by epics
2. A source for generating VibeKanban tasks
3. A living document to track progress

## PRD Location

Check for PRD files by listing `docs/*.md`.

## Existing Plan Check

Check if `docs/development-plan.md` already exists.

## Instructions

1. **Read the PRD** - If you haven't already reviewed it, read the PRD file in `docs/`

2. **Check for existing VibeKanban project** - Use `list_projects` to see if a project already exists for this work

3. **Organize into Epics** - Group related work into epics (major feature areas or milestones):
   - **Epic 1: Foundation/Setup** - Project scaffolding, dependencies, basic structure
   - **Epic 2: Core Features** - Main functionality implementation
   - **Epic 3: Supporting Features** - Secondary features, integrations
   - **Epic 4: Polish & UX** - Error handling, edge cases, UX improvements
   - **Epic 5: Testing & Documentation** - Test coverage, docs, deployment prep

   Note: Adjust epic names and count based on the project's needs. Each epic should represent a cohesive body of work.

4. **Break down into tasks** - Each task should be:
   - Atomic (completable in one work session)
   - Clear and actionable
   - Independently testable where possible
   - Assigned a priority (High, Medium, Low)
   - Given a hierarchical ID (Epic.Task, e.g., 1.1, 1.2, 2.1)
   - Estimated for complexity: `S` (Small, <1hr), `M` (Medium, 1-4hrs), `L` (Large, 4-8hrs), `XL` (Extra Large, 8hrs+)
   - Checked for dependencies on other tasks (reference by ID, e.g., `1.1, 1.2` or `—` for none)

5. **Identify dependencies** - For each task, determine if it depends on other tasks being completed first. Dependencies can be within the same epic or across epics. Use task IDs to reference dependencies.

6. **Write task-level acceptance criteria** - After each task table, add a `### Task Details` section with specific, testable acceptance criteria for every task. Each task should have 2-4 concrete criteria that define "done" -- these should be verifiable actions (e.g., "API returns 200 for valid input", "Unit tests pass", "Config file is created at path X"), not vague statements.

7. **Define epic-level acceptance criteria** - Each epic should have clear acceptance criteria that represent the overall goal of the epic

8. **Create the plan file** - Write to `docs/development-plan.md`

   Note: The task table provides a scannable overview; the Task Details section below it provides the depth needed for execution. Both are required.

## Plan Format

Use this exact format for the development plan:

```markdown
# Development Plan: [Project Name]

> **Generated from:** docs/[prd-filename].md
> **Created:** [date]
> **Last synced:** [date]
> **Status:** Active Planning Document
> **VibeKanban Project ID:** [To be assigned]

## Overview

[2-3 sentence summary of what we're building]

## Tech Stack

- **Backend:** [technologies]
- **Frontend:** [technologies]
- **Database:** [technologies]
- **Infrastructure:** [technologies]

---

## Completion Status Summary

| Epic | Status | Progress |
|------|--------|----------|
| 1. [Epic Name] | Not Started | 0% |
| 2. [Epic Name] | Not Started | 0% |
| 3. [Epic Name] | Not Started | 0% |

---

## Epic 1: [Epic Name] (NOT STARTED)

[Brief description of this epic's purpose]

### Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 1.1 | [Task title] | [Description] | High | S | — | <!-- vk: --> |
| 1.2 | [Task title] | [Description] | Medium | M | 1.1 | <!-- vk: --> |
| 1.3 | [Task title] | [Description] | Low | S | — | <!-- vk: --> |

### Task Details

**1.1 - [Task title]**
- [ ] [Specific, testable criterion - e.g., "Project builds with no errors"]
- [ ] [Specific, testable criterion - e.g., "Folder structure matches convention: src/, tests/, docs/"]
- [ ] [Specific, testable criterion - e.g., "README includes setup instructions"]

**1.2 - [Task title]**
- [ ] [Specific, testable criterion - e.g., "Database migrations run successfully"]
- [ ] [Specific, testable criterion - e.g., "Connection pool configured with env vars"]

**1.3 - [Task title]**
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

---

## Epic 2: [Epic Name] (NOT STARTED)

[Brief description]

### Acceptance Criteria

- [ ] [Criterion 1]

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 2.1 | [Task title] | [Description] | High | M | 1.1, 1.2 | <!-- vk: --> |

### Task Details

**2.1 - [Task title]**
- [ ] [Specific, testable criterion - e.g., "API endpoint returns 200 for valid request"]
- [ ] [Specific, testable criterion - e.g., "Unit tests cover happy path and error cases"]
- [ ] [Specific, testable criterion - e.g., "Input validation rejects malformed data"]

---

[Continue for all epics...]

---

## Dependencies

- [External dependency 1]
- [External dependency 2]

## Out of Scope

- [Item explicitly not included]

## Open Questions

- [ ] [Any remaining questions to resolve]

## Related Documents

| Document | Purpose | Status |
|----------|---------|--------|
| docs/[prd].md | Product Requirements | Current |

---

## Changelog

- **[date]**: Initial development plan created from PRD
```

## Important Notes

- The `<!-- vk: -->` comment in the Status column is a placeholder for VibeKanban task IDs (populated by `/generate-tasks`)
- Epic statuses are: `NOT STARTED`, `IN PROGRESS`, `COMPLETE`
- Progress percentages are calculated as: (completed tasks / total tasks) * 100
- Task priorities are: `High`, `Medium`, `Low`
- Hierarchical IDs follow the pattern: Epic.Task (e.g., 1.1, 1.2, 2.1)
- **Complexity** estimates: `S` (Small, <1hr), `M` (Medium, 1-4hrs), `L` (Large, 4-8hrs), `XL` (Extra Large, 8hrs+). These are rough estimates to help with sprint planning and task selection.
- **Depends On** references other task IDs that must be completed before this task can start. Use `—` for tasks with no dependencies. Dependencies can cross epic boundaries (e.g., task 2.1 can depend on 1.3).
- **Task Details** sections provide per-task acceptance criteria as checkboxes. Each task should have 2-4 specific, testable criteria that define "done." These are verifiable conditions (builds, tests pass, endpoint works), not descriptions of what to do. These checkboxes can be checked off during development to track completion within the plan itself.

## After Creation

After creating the plan, inform the user:
1. The plan has been created at `docs/development-plan.md`
2. They can review and adjust the plan (especially epic organization and priorities)
3. When ready, run `/generate-tasks` to create VibeKanban tasks
4. Use `/sync-plan` anytime to sync status between the plan and VibeKanban
5. Use `/plan-status` for a quick progress overview
