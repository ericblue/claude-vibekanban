---
description: Create a development plan from a PRD with task breakdown
allowed-tools: mcp__vibekanban__list_projects, mcp__vibekanban__list_tasks
---

# Create Development Plan

## Context

You are creating a structured development plan based on a PRD. This plan will serve as:
1. A roadmap for implementation organized by epics
2. A source for generating VibeKanban tasks
3. A living document to track progress

## PRD Location

!`ls -la docs/*.md 2>/dev/null`

## Existing Plan Check

!`ls -la docs/development-plan.md 2>/dev/null`

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

5. **Define acceptance criteria** - Each epic should have clear acceptance criteria

6. **Create the plan file** - Write to `docs/development-plan.md`

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

| ID | Title | Description | Priority | Status |
|----|-------|-------------|----------|--------|
| 1.1 | [Task title] | [Description] | High | <!-- vk: --> |
| 1.2 | [Task title] | [Description] | Medium | <!-- vk: --> |
| 1.3 | [Task title] | [Description] | Low | <!-- vk: --> |

---

## Epic 2: [Epic Name] (NOT STARTED)

[Brief description]

### Acceptance Criteria

- [ ] [Criterion 1]

### Tasks

| ID | Title | Description | Priority | Status |
|----|-------|-------------|----------|--------|
| 2.1 | [Task title] | [Description] | High | <!-- vk: --> |

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

## After Creation

After creating the plan, inform the user:
1. The plan has been created at `docs/development-plan.md`
2. They can review and adjust the plan (especially epic organization and priorities)
3. When ready, run `/generate-tasks` to create VibeKanban tasks
4. Use `/sync-plan` anytime to sync status between the plan and VibeKanban
5. Use `/plan-status` for a quick progress overview
